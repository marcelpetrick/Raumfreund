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
///   `latest sample - first sample`. No time is counted without samples.
/// * Two consecutive valid samples more than [AlarmStateMachine.maxGap]
///   (default 1 s) apart break continuity; the later sample starts a new
///   phase. A gap of exactly `maxGap` is still continuous.
/// * The alarm fires once per yellow/red phase when the elapsed phase time
///   reaches [AlarmStateMachine.alarmDelay] (default 10 s): never earlier,
///   and at the latest with the first valid sample at or after 10 s.
/// * Green resets the phase and the fired flag. A yellow ↔ red change starts
///   a new phase with a new fired flag.
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

  /// Zone of the current phase; null before the first sample/after reset.
  final Zone? zone;

  /// Time since the first sample of the current yellow/red phase; zero in
  /// green or without a phase.
  final Duration phaseElapsed;

  /// Time left until the alarm of this phase; null in green, without a
  /// phase, or after the alarm of this phase has fired.
  final Duration? remainingUntilAlarm;

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
  /// Creates a machine for [thresholds].
  AlarmStateMachine({
    required this.thresholds,
    this.alarmDelay = defaultAlarmDelay,
    this.maxGap = defaultMaxGap,
  });

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

  Zone? _zone;
  Duration? _phaseStart;
  Duration? _lastSample;
  bool _fired = false;
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
    final zone = thresholds.classify(levelDb);
    final continuous = _isContinuous(timestamp);
    _lastSample = timestamp;
    if (zone == Zone.green) {
      _zone = zone;
      _phaseStart = null;
      _fired = false;
      return _snapshot = _build(timestamp, shouldFire: false);
    }
    if (!continuous || zone != _zone || _phaseStart == null) {
      _zone = zone;
      _phaseStart = timestamp;
      _fired = false;
    }
    final elapsed = timestamp - _phaseStart!;
    final fireNow = !_fired && elapsed >= alarmDelay;
    if (fireNow) _fired = true;
    return _snapshot = _build(timestamp, shouldFire: fireNow);
  }

  /// Forgets the current phase (stop, background, error, threshold change).
  /// Also ends a suppression.
  void reset() {
    _zone = null;
    _phaseStart = null;
    _lastSample = null;
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

  bool _isContinuous(Duration timestamp) {
    final last = _lastSample;
    if (last == null) return false;
    final delta = timestamp - last;
    return delta >= Duration.zero && delta <= maxGap;
  }

  AlarmSnapshot _build(Duration timestamp, {required bool shouldFire}) {
    final start = _phaseStart;
    final elapsed = start == null ? Duration.zero : timestamp - start;
    final remaining = start == null || _fired ? null : alarmDelay - elapsed;
    return AlarmSnapshot(
      zone: _zone,
      phaseElapsed: elapsed,
      remainingUntilAlarm: remaining,
      alarmFiredInPhase: _fired,
      suppressed: _suppressed,
      shouldFireAlarm: shouldFire,
    );
  }

  AlarmSnapshot _copy({required bool shouldFire}) => AlarmSnapshot(
    zone: _snapshot.zone,
    phaseElapsed: _snapshot.phaseElapsed,
    remainingUntilAlarm: _snapshot.remainingUntilAlarm,
    alarmFiredInPhase: _snapshot.alarmFiredInPhase,
    suppressed: _suppressed,
    shouldFireAlarm: shouldFire,
  );
}
