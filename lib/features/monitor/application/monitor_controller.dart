// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../../../core/clock.dart';
import '../../../core/scheduler.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/alarm_state_machine.dart';
import '../domain/calibration.dart';
import '../domain/display_smoother.dart';
import '../domain/level_history.dart';
import '../domain/quiet_stars.dart';
import '../domain/zone.dart';
import 'monitor_state.dart';
import 'ports.dart';

/// Owns the measurement session: permission flow, recording lifecycle,
/// level processing and the alarm.
///
/// Concurrency rules:
///
/// * Only one session at a time. Every [start] gets a new session id; events
///   and async completions of other sessions are dropped.
/// * [start] works only from [MonitorStatus.stopped]/[MonitorStatus.error];
///   calls while busy are ignored (no double start by rapid taps).
/// * Lifecycle changes while the permission dialog is open do not cancel
///   the request; after a grant recording starts only in the foreground.
/// * Going to the background stops the measurement; there is no automatic
///   restart on resume.
/// * Cleanup ([stop], [dispose]) is idempotent.
/// * A recorder that delivers no valid reading for [firstReadingTimeout]
///   after measuring begins, or for [readingStallTimeout] afterwards, ends
///   the session with [MonitorFailure.noReadings] (ADR 0003). Readings
///   ignored during the own alarm output pause this watchdog.
final class MonitorController extends ChangeNotifier {
  /// Creates a stopped controller using [settings] for the next start.
  MonitorController({
    required this._permission,
    required this._levelSource,
    required this._alarmOutput,
    required this._screenAwake,
    required this._clock,
    required this._scheduler,
    required AppSettings settings,
    LevelHistory? history,
    QuietStars? stars,
    this._onStarEarned = ignoreStarEarned,
  }) : _settings = settings,
       _sessionSettings = settings,
       _history = history ?? LevelHistory(),
       _stars = stars ?? QuietStars(minute: _starIntervalFor(settings)),
       _alarm = _alarmFor(settings),
       _calibration = Calibration(
         correctionDb: settings.calibrationCorrectionDb,
       ),
       _state = MonitorState.initial(settings.thresholds);

  final MicrophonePermissionPort _permission;
  final LevelSourcePort _levelSource;
  final AlarmOutputPort _alarmOutput;
  final ScreenAwakePort _screenAwake;
  final MonotonicClock _clock;
  final TimerScheduler _scheduler;
  final LevelHistory _history;
  final QuietStars _stars;
  final StarEarnedSink _onStarEarned;
  final DisplaySmoother _smoother = DisplaySmoother();

  AppSettings _settings;
  AppSettings _sessionSettings;
  AlarmStateMachine _alarm;
  Calibration _calibration;
  MonitorState _state;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  StreamSubscription<LevelEvent>? _subscription;
  int _lastSessionId = 0;
  int? _activeSession;
  bool _alarmOutputActive = false;
  bool _disposed = false;
  ScheduledCallback? _watchdog;
  bool _sessionHadReading = false;

  /// Longest wait for the first valid reading once measuring has begun.
  ///
  /// Readings arrive every ~100 ms; `AudioRecord` usually delivers its first
  /// window within a few hundred milliseconds, but routing to a headset or
  /// a slow device can take longer. Until the first reading the UI shows
  /// "starting" (no zone), never a calm state, so this may be generous.
  static const Duration firstReadingTimeout = Duration(seconds: 5);

  /// Longest gap between valid readings before the session is ended.
  ///
  /// Thirty missed ~100 ms windows: far beyond scheduling or GC hiccups,
  /// and as long as the zone release window (ADR 0004), so a stale zone is
  /// shown at most as long as a real one would take to cool down. Sparser
  /// but living recorders are covered by the "signal thin" hint instead.
  static const Duration readingStallTimeout = Duration(seconds: 3);

  /// Longest wait for the native alarm output to report its end.
  ///
  /// The native tone and vibration end after at most 500 ms
  /// (`AlarmDurationPolicy`). Readings are ignored and the no-reading
  /// watchdog is paused while output is active, and that suppression is
  /// shared across sessions, so a lost answer must not freeze every later
  /// measurement. After this timeout the output counts as failed.
  static const Duration alarmOutputTimeout = Duration(seconds: 2);

  /// Current immutable state.
  MonitorState get state => _state;

  /// Settings used for the next start.
  AppSettings get settings => _settings;

  /// Id of the most recently started session (0 before the first start).
  int get lastSessionId => _lastSessionId;

  /// Starts a measurement (permission → recording). Ignored while busy.
  Future<void> start() async {
    if (_disposed || _state.isBusy) return;
    final session = ++_lastSessionId;
    _activeSession = session;
    _prepareSession();
    final permission = await _obtainPermission();
    if (!_isCurrent(session)) return;
    switch (permission) {
      case null:
        return _endSession(failure: MonitorFailure.unavailable);
      case MicrophonePermissionStatus.denied:
        return _endSession(failure: MonitorFailure.permissionDenied);
      case MicrophonePermissionStatus.permanentlyDenied:
        return _endSession(failure: MonitorFailure.permissionPermanentlyDenied);
      case MicrophonePermissionStatus.granted:
        break;
    }
    // The app may have gone to the background while the dialog was open.
    if (!_isForeground) return _endSession();
    await _startRecording(session);
  }

  /// Stops the measurement. Idempotent; keeps the level history.
  Future<void> stop() async {
    if (_activeSession == null) return;
    await _endSession();
  }

  /// Start/stop button: starts when stopped or failed, stops while
  /// measuring, and ignores taps during transitions.
  Future<void> toggle() async {
    switch (_state.status) {
      case MonitorStatus.stopped:
      case MonitorStatus.error:
        await start();
      case MonitorStatus.measuring:
        await stop();
      case MonitorStatus.permissionPending:
      case MonitorStatus.starting:
      case MonitorStatus.stopping:
        return;
    }
  }

  /// Forwards app lifecycle changes. Hidden/paused/detached stop the
  /// measurement, except while the permission dialog is pending (the
  /// dialog itself pauses the activity). Inactive is ignored.
  void onLifecycleChanged(AppLifecycleState lifecycle) {
    _lifecycle = lifecycle;
    switch (lifecycle) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_state.status == MonitorStatus.permissionPending) return;
        unawaited(stop());
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        return;
    }
  }

  /// Stops the measurement and uses [settings] (thresholds, calibration,
  /// alarm delay, star interval and options) from the next start on.
  Future<void> applySettings(AppSettings settings) async {
    if (_disposed) return;
    _settings = settings;
    await stop();
    if (_disposed) return;
    // A newer apply may have completed while this call awaited teardown.
    // Always publish the last requested settings so fields cannot diverge.
    final current = _settings;
    _stars.setMinute(_starIntervalFor(current));
    _emit(_state.copyWith(thresholds: current.thresholds));
  }

  /// Opens the Android app settings (after a permanent denial). Returns
  /// false if that is not possible.
  Future<bool> openAppSettings() async {
    try {
      await _permission.openAppSettings();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeSession = null;
    _cancelWatchdog();
    _alarm.reset();
    unawaited(_teardown());
    super.dispose();
  }

  bool _isCurrent(int session) => !_disposed && _activeSession == session;

  bool get _isForeground =>
      _lifecycle == AppLifecycleState.resumed ||
      _lifecycle == AppLifecycleState.inactive;

  void _prepareSession() {
    _sessionSettings = _settings;
    _alarm = _alarmFor(_settings);
    _calibration = Calibration(correctionDb: _settings.calibrationCorrectionDb);
    _smoother.reset();
    _stars.reset();
    _sessionHadReading = false;
    _emit(
      _state.copyWith(
        status: MonitorStatus.permissionPending,
        clearFailure: true,
        clearLevels: true,
        clearRemaining: true,
        alarmFiredInPhase: false,
        kittyAway: false,
        alarmPlaying: _alarmOutputActive,
        alarmOutputFailed: false,
        signalThin: false,
        thresholds: _settings.thresholds,
        starJustEarned: false,
        starProgress: 0,
      ),
    );
  }

  Future<MicrophonePermissionStatus?> _obtainPermission() async {
    try {
      final status = await _permission.status();
      if (status == MicrophonePermissionStatus.granted) return status;
      return await _permission.request();
    } on Exception catch (error, stack) {
      _report(error, stack, 'while obtaining the microphone permission');
      return null;
    }
  }

  Future<void> _startRecording(int session) async {
    _emit(_state.copyWith(status: MonitorStatus.starting));
    _subscription = _levelSource.events.listen(
      _onEvent,
      onError: (Object error, StackTrace stack) {
        _onStreamError(session, error, stack);
      },
      onDone: () => _onStreamDone(session),
    );
    if (!_isCurrent(session)) return;
    try {
      await _levelSource.start(session);
    } on LevelSourceException catch (error) {
      if (_isCurrent(session)) {
        await _endSession(failure: _mapFailure(error.failure));
      }
      return;
    } on Exception catch (error, stack) {
      _report(error, stack, 'while starting the level source');
      if (_isCurrent(session)) {
        await _endSession(failure: MonitorFailure.unavailable);
      }
      return;
    }
    if (!_isCurrent(session)) {
      // Stopped while starting: the native side may have begun recording
      // after our stop request. Stop it, unless a newer session owns the
      // recorder by now (its own start/teardown handles the recorder).
      if (_activeSession == null) await _guard(_levelSource.stop);
      return;
    }
    _emit(_state.copyWith(status: MonitorStatus.measuring));
    _armWatchdog(session);
    await _guard(() => _screenAwake.setKeepScreenOn(enabled: true));
  }

  void _onEvent(LevelEvent event) {
    final session = event.sessionId;
    if (!_isCurrent(session)) return;
    switch (event) {
      case LevelReading(:final dbfs):
        _onReading(session, dbfs);
      case LevelError(:final failure):
        unawaited(_endSession(failure: _mapFailure(failure)));
    }
  }

  void _onStreamError(int session, Object error, StackTrace stack) {
    if (!_isCurrent(session)) return;
    _report(error, stack, 'while receiving microphone levels');
    unawaited(_endSession(failure: MonitorFailure.unavailable));
  }

  void _onStreamDone(int session) {
    if (!_isCurrent(session)) return;
    unawaited(_endSession(failure: MonitorFailure.recordingAborted));
  }

  void _onReading(int session, double dbfs) {
    // Output can outlive the session that started it. A replacement session
    // must still ignore the physical tone until its future completes.
    if (_alarmOutputActive) return;
    final level = _calibration.estimate(dbfs);
    // An invalid value (NaN, infinity, digital silence of a muted input) is
    // no measurement and does not feed the watchdog.
    if (level == null) return;
    _sessionHadReading = true;
    _armWatchdog(session);
    final now = _clock.now;
    final snapshot = _alarm.onSample(timestamp: now, levelDb: level);
    // While the own alarm tone plays the microphone hears it: the machine
    // ignores these samples, and gauge, chart and stars must not show it.
    if (snapshot.suppressed) return;
    final display = _smoother.add(timestamp: now, levelDb: level);
    // The confirmed (debounced) zone drives UI and stars, so they never
    // flicker differently from the alarm phase (ADR 0004).
    final zone = snapshot.zone;
    _history.add(timestamp: now, levelDb: level);
    if (zone != null) _stars.onSample(timestamp: now, zone: zone);
    // Exactly once per star: earnedStarNow is true only after that sample.
    if (zone != null && _stars.earnedStarNow) _onStarEarned();
    _emit(
      _state.copyWith(
        displayLevelDb: display,
        alarmLevelDb: level,
        zone: zone,
        remainingUntilAlarm: snapshot.remainingUntilAlarm,
        clearRemaining: snapshot.remainingUntilAlarm == null,
        alarmFiredInPhase: snapshot.alarmFiredInPhase,
        kittyAway: _kittyAway(snapshot),
        signalThin: snapshot.signalThin,
        history: _history.points,
        historyNow: now,
        stars: _stars.stars,
        starProgress: _stars.progress,
        starJustEarned: _stars.earnedStarNow,
      ),
    );
    if (snapshot.shouldFireAlarm) unawaited(_playAlarm(session));
  }

  /// "Mia is away" latch: she leaves when the alarm of a confirmed red
  /// phase fires and stays away (also in yellow, and across the reset after
  /// the own alarm tone) until green is confirmed *and settled*: after the
  /// post-tone reset the first sample is adopted immediately, and a single
  /// green sample must not bring her back. Stop, reset and errors clear the
  /// latch via [_prepareSession]/[_endSession].
  bool _kittyAway(AlarmSnapshot snapshot) => switch (snapshot.zone) {
    Zone.green when snapshot.zoneSettled => false,
    Zone.red when snapshot.alarmFiredInPhase => true,
    _ => _state.kittyAway,
  };

  Future<void> _playAlarm(int session) async {
    final sound = _sessionSettings.alarmSoundEnabled;
    final vibrate = _sessionSettings.vibrationEnabled;
    // Nothing audible or tangible: no need to pause the measurement.
    if (!sound && !vibrate) return;
    if (_alarmOutputActive) return;
    _alarmOutputActive = true;
    // Readings are ignored on purpose now; their absence is no failure.
    _cancelWatchdog();
    _alarm.onAlarmOutputStarted();
    _emit(_state.copyWith(alarmPlaying: true));
    final succeeded = await _playOutput(sound: sound, vibrate: vibrate);
    _alarmOutputActive = false;
    _finishAlarmOutput(ownerSession: session, failed: !succeeded);
  }

  /// Plays the output and reports whether it ended normally within
  /// [alarmOutputTimeout]. A late answer after the timeout is ignored.
  Future<bool> _playOutput({required bool sound, required bool vibrate}) {
    final result = Completer<bool>();
    void complete({required bool succeeded}) {
      if (!result.isCompleted) result.complete(succeeded);
    }

    final timeout = _scheduler.schedule(
      alarmOutputTimeout,
      () => complete(succeeded: false),
    );
    unawaited(
      _awaitOutput(sound: sound, vibrate: vibrate).then((succeeded) {
        timeout.cancel();
        complete(succeeded: succeeded);
      }),
    );
    return result.future;
  }

  Future<bool> _awaitOutput({
    required bool sound,
    required bool vibrate,
  }) async {
    try {
      await _alarmOutput.play(sound: sound, vibrate: vibrate);
      return true;
    } on Exception {
      return false;
    }
  }

  void _finishAlarmOutput({required int ownerSession, required bool failed}) {
    final activeSession = _activeSession;
    if (_disposed || activeSession == null) return;
    // A replacement session ignored every sample while the old output was
    // active. Reset its continuity too, then accept only later samples.
    _alarm.onAlarmOutputFinished();
    _emit(
      _state.copyWith(
        alarmPlaying: false,
        alarmOutputFailed:
            _state.alarmOutputFailed ||
            (ownerSession == activeSession && failed),
        alarmFiredInPhase: false,
        clearRemaining: true,
        // The machine was reset; the next reading judges afresh.
        signalThin: false,
      ),
    );
    // A session still starting arms the watchdog when it reaches measuring.
    if (_state.status == MonitorStatus.measuring) _armWatchdog(activeSession);
  }

  /// (Re)starts the no-reading watchdog of [session]. Not armed while the
  /// own alarm output makes the controller ignore readings; output
  /// completion arms it again.
  void _armWatchdog(int session) {
    _cancelWatchdog();
    if (_alarmOutputActive || !_isCurrent(session)) return;
    final timeout = _sessionHadReading
        ? readingStallTimeout
        : firstReadingTimeout;
    _watchdog = _scheduler.schedule(timeout, () => _onNoReadings(session));
  }

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  void _onNoReadings(int session) {
    _watchdog = null;
    // A watchdog of an older session must never touch a newer one, and a
    // session that is still starting or stopping has its own outcome.
    if (!_isCurrent(session) || _alarmOutputActive) return;
    if (_state.status != MonitorStatus.measuring) return;
    unawaited(_endSession(failure: MonitorFailure.noReadings));
  }

  Future<void> _endSession({MonitorFailure? failure}) async {
    _activeSession = null;
    _cancelWatchdog();
    _alarm.reset();
    _smoother.reset();
    _stars.reset();
    _emit(
      _state.copyWith(
        status: MonitorStatus.stopping,
        clearLevels: true,
        clearRemaining: true,
        alarmFiredInPhase: false,
        kittyAway: false,
        alarmPlaying: false,
        signalThin: false,
        starProgress: 0,
        starJustEarned: false,
      ),
    );
    await _teardown();
    if (_activeSession != null) return;
    _emit(
      _state.copyWith(
        status: failure == null ? MonitorStatus.stopped : MonitorStatus.error,
        failure: failure,
      ),
    );
  }

  Future<void> _teardown() async {
    final cancelling = _subscription?.cancel();
    _subscription = null;
    if (cancelling != null) await _guard(() => cancelling);
    await _guard(_levelSource.stop);
    await _guard(() => _screenAwake.setKeepScreenOn(enabled: false));
  }

  /// Runs a cleanup/platform call; failures are reported, never swallowed,
  /// but must not leave the controller in a transitional state.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Exception catch (error, stack) {
      _report(error, stack, 'during a measurement platform call');
    }
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'raumfreund monitor',
        context: ErrorDescription(context),
      ),
    );
  }

  void _emit(MonitorState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  /// A fresh machine per session: thresholds and the configured alarm delay
  /// are fixed for its lifetime, so a settings change takes effect with the
  /// next start (Settings stop the measurement anyway).
  static AlarmStateMachine _alarmFor(AppSettings settings) => AlarmStateMachine(
    thresholds: settings.thresholds,
    alarmDelay: settings.alarmDelay,
  );

  static Duration _starIntervalFor(AppSettings settings) =>
      settings.quickStarModeEnabled
      ? const Duration(seconds: 5)
      : QuietStars.defaultMinute;

  static MonitorFailure _mapFailure(LevelFailure failure) => switch (failure) {
    LevelFailure.microphoneBusy => MonitorFailure.microphoneBusy,
    LevelFailure.recordingAborted => MonitorFailure.recordingAborted,
    LevelFailure.unavailable => MonitorFailure.unavailable,
    LevelFailure.permissionMissing => MonitorFailure.permissionDenied,
  };
}
