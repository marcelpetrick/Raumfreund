// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Zone phases and the "10 seconds too loud" alarm (vision §3).
///
/// Timing model:
///
/// * The native recorder delivers one RMS level per ~100 ms window. Each
///   level is stamped with the monotonic clock when it reaches Dart, so the
///   time resolution of all decisions is one sample interval (~100 ms).
/// * Only *valid* samples (finite, see `Calibration.estimate`) are fed in.
///   Time is measured exclusively between samples: the start of a phase is
///   the timestamp of its first valid sample, and the elapsed phase time is
///   `latest sample in the phase's zone - first sample` (raw zone >= the
///   phase zone). Dips between such samples count; a quiet tail after the
///   last one does not. No time is counted without samples.
/// * Phases follow the *confirmed* zone of a [ZoneDebouncer] (ADR 0004),
///   not the raw per-sample zone: fast attack (a zone is entered when it
///   covers 50 % of the last [AlarmStateMachine.holdTime], default 1 s),
///   slow release (it is left when it covers less than 15 % of the last
///   3 s). Pauses and dips while the zone holds neither change the zone nor
///   restart the phase.
/// * The phase of a newly confirmed zone starts at the first sample of the
///   contiguous loud run that led to the confirmation (never at a sample
///   below that zone). The alarm therefore never fires before
///   [AlarmStateMachine.alarmDelay] of such samples; after confirmation,
///   dips are tolerated by the hysteresis.
/// * Two consecutive valid samples more than [AlarmStateMachine.maxGap]
///   (default 1 s) apart break continuity; the later sample is adopted
///   immediately as the confirmed zone and starts a new phase. A gap of
///   exactly `maxGap` is still continuous. The same holds for the first
///   sample after construction or [AlarmStateMachine.reset].
/// * The alarm fires once per yellow/red phase when the elapsed phase time
///   reaches [AlarmStateMachine.alarmDelay] (default 10 s): never earlier,
///   only on a sample in the phase's zone, and only while the debouncer's
///   release window is usable ([ZoneDecision.usable]); otherwise with the
///   first such sample at or after 10 s.
/// * Confirmed green resets the phase and the fired flag. A confirmed
///   yellow ↔ red change starts a new phase with a new fired flag.
///
/// Own alarm tone: the tone can reach the microphone and would otherwise keep
/// the room "loud". Between [AlarmStateMachine.onAlarmOutputStarted] and
/// [AlarmStateMachine.onAlarmOutputFinished] all samples are ignored (no
/// phase progress, no further alarm; the snapshot reports `suppressed`).
/// When the tone ends the machine is reset, so a new phase starts only with
/// valid samples taken after the tone. This short measurement pause is
/// intended.
///
/// The class is pure Dart: no Flutter, no platform, no real clock.
library;

import 'thresholds.dart';
import 'zone.dart';
import 'zone_debouncer.dart';

/// Read-only view of the [AlarmStateMachine] after the latest event.
final class AlarmSnapshot {
  /// Creates a snapshot.
  const AlarmSnapshot({
    required this.zone,
    required this.phaseElapsed,
    required this.remainingUntilAlarm,
    required this.alarmFiredInPhase,
    required this.suppressed,
    required this.shouldFireAlarm,
    this.zoneSettled = false,
  });

  /// State before the first sample or after a reset.
  static const AlarmSnapshot idle = AlarmSnapshot(
    zone: null,
    phaseElapsed: Duration.zero,
    remainingUntilAlarm: null,
    alarmFiredInPhase: false,
    suppressed: false,
    shouldFireAlarm: false,
  );

  /// Confirmed zone of the current phase (see [ZoneDebouncer]); null before
  /// the first sample/after reset.
  final Zone? zone;

  /// Time since the first sample of the current yellow/red phase; zero in
  /// green or without a phase.
  final Duration phaseElapsed;

  /// Time left until the alarm of this phase; null in green, without a
  /// phase, or after the alarm of this phase has fired.
  final Duration? remainingUntilAlarm;

  /// Whether [zone] is backed by at least the hold time of raw samples (see
  /// [ZoneDecision.settled]); false right after a reset or gap.
  final bool zoneSettled;

  /// Whether the alarm of the current phase has already fired.
  final bool alarmFiredInPhase;

  /// Whether samples are currently ignored because the alarm is playing.
  final bool suppressed;

  /// True only for the sample that triggers the alarm of a phase.
  final bool shouldFireAlarm;
}

/// Pure state machine deciding when the alarm fires. See the library
/// documentation for the exact rules.
///
/// Thresholds are fixed per instance: when they change, create a new machine
/// or call [reset] (the measurement is stopped anyway).
final class AlarmStateMachine {
  /// Creates a machine for [thresholds]. Throws an [ArgumentError] if
  /// [alarmDelay] is shorter than [holdTime]. (The Settings range for the
  /// delay starts at 3 s; that is added separately.)
  AlarmStateMachine({
    required this.thresholds,
    this.alarmDelay = defaultAlarmDelay,
    this.maxGap = defaultMaxGap,
    this.holdTime = ZoneDebouncer.defaultHoldTime,
  }) : _debouncer = ZoneDebouncer(holdTime: holdTime, maxGap: maxGap) {
    // A confirmation can lie up to one hold time after the phase start, so a
    // shorter delay would fire late (at confirmation) instead of on time.
    if (alarmDelay < holdTime) {
      throw ArgumentError.value(
        alarmDelay,
        'alarmDelay',
        'must not be shorter than holdTime ($holdTime)',
      );
    }
  }

  /// Continuous yellow/red time that triggers the alarm.
  static const Duration defaultAlarmDelay = Duration(seconds: 10);

  /// Largest distance between two samples that still counts as continuous.
  static const Duration defaultMaxGap = Duration(seconds: 1);

  /// Zone limits used to classify samples.
  final Thresholds thresholds;

  /// See [defaultAlarmDelay].
  final Duration alarmDelay;

  /// See [defaultMaxGap].
  final Duration maxGap;

  /// Length of the zone hysteresis window (see [ZoneDebouncer.holdTime]).
  final Duration holdTime;

  final ZoneDebouncer _debouncer;
  Zone? _zone;
  Duration? _phaseStart;
  Duration? _lastLoud;
  bool _fired = false;
  bool _settled = false;
  bool _suppressed = false;
  AlarmSnapshot _snapshot = AlarmSnapshot.idle;

  /// State after the latest event.
  AlarmSnapshot get snapshot => _snapshot;

  /// Feeds one valid sample (estimated level [levelDb] at monotonic
  /// [timestamp]) and returns the new snapshot.
  ///
  /// Non-finite levels are ignored like invalid samples. While the alarm
  /// output is playing the sample is ignored as well.
  AlarmSnapshot onSample({
    required Duration timestamp,
    required double levelDb,
  }) {
    if (_suppressed || !levelDb.isFinite) {
      return _snapshot = _copy(shouldFire: false);
    }
    final raw = thresholds.classify(levelDb);
    final decision = _debouncer.onSample(timestamp: timestamp, zone: raw);
    _zone = decision.zone;
    _settled = decision.settled;
    if (decision.zone == Zone.green) {
      _phaseStart = null;
      _lastLoud = null;
      _fired = false;
      return _snapshot = _build(shouldFire: false);
    }
    if (decision.started || _phaseStart == null) {
      // Start of the loud run that led to the confirmation.
      _phaseStart = decision.since;
      _lastLoud = null;
      _fired = false;
    }
    // Only samples in the phase's zone advance it: dips between them count,
    // a quiet tail after the last of them does not.
    final inZone = raw.index >= decision.zone.index;
    if (inZone) _lastLoud = timestamp;
    final elapsed = _elapsed();
    final fireNow =
        !_fired && inZone && decision.usable && elapsed >= alarmDelay;
    if (fireNow) _fired = true;
    return _snapshot = _build(shouldFire: fireNow);
  }

  /// Forgets the current phase (stop, background, error, threshold change).
  /// Also ends a suppression.
  void reset() {
    _zone = null;
    _phaseStart = null;
    _lastLoud = null;
    _debouncer.reset();
    _settled = false;
    _fired = false;
    _suppressed = false;
    _snapshot = AlarmSnapshot.idle;
  }

  /// The alarm output has started: ignore samples until
  /// [onAlarmOutputFinished].
  void onAlarmOutputStarted() {
    _suppressed = true;
    _snapshot = _copy(shouldFire: false);
  }

  /// The alarm output has ended: reset, so a new phase starts only with
  /// samples taken after the tone.
  void onAlarmOutputFinished() => reset();

  /// Phase time: from the phase start to the latest sample in the phase's
  /// zone (zero without a phase).
  Duration _elapsed() {
    final start = _phaseStart;
    if (start == null) return Duration.zero;
    return (_lastLoud ?? start) - start;
  }

  AlarmSnapshot _build({required bool shouldFire}) {
    final start = _phaseStart;
    final elapsed = _elapsed();
    final left = alarmDelay - elapsed;
    // Can stay at zero while thin data blocks the alarm decision.
    final remaining = start == null || _fired
        ? null
        : (left.isNegative ? Duration.zero : left);
    return AlarmSnapshot(
      zone: _zone,
      phaseElapsed: elapsed,
      remainingUntilAlarm: remaining,
      alarmFiredInPhase: _fired,
      suppressed: _suppressed,
      shouldFireAlarm: shouldFire,
      zoneSettled: _settled,
    );
  }

  AlarmSnapshot _copy({required bool shouldFire}) => AlarmSnapshot(
    zone: _snapshot.zone,
    phaseElapsed: _snapshot.phaseElapsed,
    remainingUntilAlarm: _snapshot.remainingUntilAlarm,
    alarmFiredInPhase: _snapshot.alarmFiredInPhase,
    suppressed: _suppressed,
    shouldFireAlarm: shouldFire,
    zoneSettled: _snapshot.zoneSettled,
  );
}
