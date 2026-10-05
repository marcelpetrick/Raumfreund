// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import '../domain/level_history_point.dart';
import '../domain/thresholds.dart';
import '../domain/zone.dart';

/// Lifecycle of a measurement as seen by the UI.
enum MonitorStatus {
  /// No measurement; start is possible.
  stopped,

  /// Waiting for the microphone permission (dialog may be visible).
  permissionPending,

  /// Permission granted, recording is being started.
  starting,

  /// Levels are being received.
  measuring,

  /// Recording is being shut down.
  stopping,

  /// The last attempt failed; see [MonitorState.failure]. Start is possible.
  error,
}

/// Why the measurement is in [MonitorStatus.error].
enum MonitorFailure {
  /// The user denied the permission; asking again is possible.
  permissionDenied,

  /// Denied permanently; only the Android app settings help.
  permissionPermanentlyDenied,

  /// Another app uses or silences the microphone.
  microphoneBusy,

  /// Recording was aborted by the system.
  recordingAborted,

  /// Microphone or audio format not available.
  unavailable,
}

/// Immutable snapshot of the measurement for the UI.
final class MonitorState {
  /// Creates a state.
  const MonitorState({
    required this.status,
    required this.thresholds,
    this.failure,
    this.displayLevelDb,
    this.alarmLevelDb,
    this.zone,
    this.remainingUntilAlarm,
    this.alarmFiredInPhase = false,
    this.kittyAway = false,
    this.alarmPlaying = false,
    this.alarmOutputFailed = false,
    this.signalThin = false,
    this.history = const [],
    this.historyNow = Duration.zero,
    this.stars = 0,
    this.starProgress = 0,
    this.starJustEarned = false,
  });

  /// Stopped state without any measurement.
  factory MonitorState.initial(Thresholds thresholds) =>
      MonitorState(status: MonitorStatus.stopped, thresholds: thresholds);

  /// Current lifecycle status.
  final MonitorStatus status;

  /// Set only in [MonitorStatus.error].
  final MonitorFailure? failure;

  /// Smoothed estimated level for the gauge; null without a sample.
  final double? displayLevelDb;

  /// Unsmoothed estimated level used for zones and the alarm.
  final double? alarmLevelDb;

  /// Confirmed zone (1 s hysteresis, ADR 0004) of the recent
  /// [alarmLevelDb] samples; null without a sample. A single sample across a
  /// threshold does not change it.
  final Zone? zone;

  /// Countdown of the current yellow/red phase; null otherwise.
  final Duration? remainingUntilAlarm;

  /// Whether the alarm of the current phase has fired.
  final bool alarmFiredInPhase;

  /// Whether Mia has walked away: set when the alarm of a confirmed red
  /// phase fires, kept (also in yellow) until the confirmed zone is green or
  /// the measurement stops, resets or fails.
  final bool kittyAway;

  /// Whether the alarm output is playing (measurement paused for alarms).
  final bool alarmPlaying;

  /// Non-fatal: the last alarm output failed. Reset on the next start.
  final bool alarmOutputFailed;

  /// Whether readings have been too sparse to judge the room for a while
  /// (e.g. a throttled recorder), so no alarm can fire. Cleared on stop,
  /// reset, error and after the alarm tone.
  final bool signalThin;

  /// Zone limits of the current/next measurement.
  final Thresholds thresholds;

  /// Timeline of 1 s level peaks (unmodifiable, RAM only).
  final List<LevelHistoryPoint> history;

  /// Monotonic time at which this state was created (x-axis reference).
  final Duration historyNow;

  /// Quiet stars earned in this app session.
  final int stars;

  /// Progress (0..1) to the next star.
  final double starProgress;

  /// True only in the state emitted for the sample that earned a star.
  final bool starJustEarned;

  /// Whether a measurement is running or being set up/torn down.
  bool get isBusy =>
      status != MonitorStatus.stopped && status != MonitorStatus.error;

  /// Returns a copy with the given fields replaced. Nullable fields are
  /// replaced via the `clear…` flags.
  MonitorState copyWith({
    MonitorStatus? status,
    MonitorFailure? failure,
    bool clearFailure = false,
    double? displayLevelDb,
    double? alarmLevelDb,
    Zone? zone,
    bool clearLevels = false,
    Duration? remainingUntilAlarm,
    bool clearRemaining = false,
    bool? alarmFiredInPhase,
    bool? kittyAway,
    bool? alarmPlaying,
    bool? alarmOutputFailed,
    bool? signalThin,
    Thresholds? thresholds,
    List<LevelHistoryPoint>? history,
    Duration? historyNow,
    int? stars,
    double? starProgress,
    bool? starJustEarned,
  }) => MonitorState(
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
    displayLevelDb: clearLevels ? null : displayLevelDb ?? this.displayLevelDb,
    alarmLevelDb: clearLevels ? null : alarmLevelDb ?? this.alarmLevelDb,
    zone: clearLevels ? null : zone ?? this.zone,
    remainingUntilAlarm: clearRemaining
        ? null
        : remainingUntilAlarm ?? this.remainingUntilAlarm,
    alarmFiredInPhase: alarmFiredInPhase ?? this.alarmFiredInPhase,
    kittyAway: kittyAway ?? this.kittyAway,
    alarmPlaying: alarmPlaying ?? this.alarmPlaying,
    alarmOutputFailed: alarmOutputFailed ?? this.alarmOutputFailed,
    signalThin: signalThin ?? this.signalThin,
    thresholds: thresholds ?? this.thresholds,
    history: history ?? this.history,
    historyNow: historyNow ?? this.historyNow,
    stars: stars ?? this.stars,
    starProgress: starProgress ?? this.starProgress,
    starJustEarned: starJustEarned ?? this.starJustEarned,
  );
}
