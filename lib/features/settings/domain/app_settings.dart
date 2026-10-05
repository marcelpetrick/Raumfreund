// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import '../../monitor/domain/thresholds.dart';

/// User settings of Raumfreund. Always valid (see [Thresholds]).
final class AppSettings {
  /// Creates settings; throws [ArgumentError] for an out-of-range
  /// [calibrationCorrectionDb] or [alarmDelaySeconds].
  AppSettings({
    required this.thresholds,
    required this.calibrationCorrectionDb,
    required this.alarmSoundEnabled,
    required this.vibrationEnabled,
    required this.alarmDelaySeconds,
  }) {
    _checkRange(
      calibrationCorrectionDb,
      minCalibrationDb,
      maxCalibrationDb,
      'calibrationCorrectionDb',
    );
    _checkRange(
      alarmDelaySeconds,
      minAlarmDelaySeconds,
      maxAlarmDelaySeconds,
      'alarmDelaySeconds',
    );
  }

  /// Lowest calibration correction.
  static const int minCalibrationDb = -30;

  /// Highest calibration correction.
  static const int maxCalibrationDb = 30;

  /// Shortest selectable alarm delay.
  ///
  /// The alarm state machine requires a delay of at least its 1 s zone
  /// hysteresis hold time (ADR 0004); 3 s keeps a clear margin above that.
  /// Shorter delays would also make the alarm nervous: a single laugh or a
  /// dropped object would already trigger it, which defeats the purpose of a
  /// friendly "it has been loud for a while" reminder.
  static const int minAlarmDelaySeconds = 3;

  /// Longest selectable alarm delay.
  ///
  /// Beyond one minute the feedback no longer feels connected to the noise
  /// that caused it, and the gap-free requirement (vision §3) makes a longer
  /// phase unlikely to ever complete in a lively room.
  static const int maxAlarmDelaySeconds = 60;

  /// Factory alarm delay (vision §3). Equals the alarm state machine's
  /// default delay; a test keeps both in sync.
  static const int defaultAlarmDelaySeconds = 10;

  /// Factory defaults.
  static final AppSettings defaults = AppSettings(
    thresholds: Thresholds.defaults,
    calibrationCorrectionDb: 0,
    alarmSoundEnabled: true,
    vibrationEnabled: true,
    alarmDelaySeconds: defaultAlarmDelaySeconds,
  );

  /// Zone limits.
  final Thresholds thresholds;

  /// User correction added to the estimated level (dB).
  final int calibrationCorrectionDb;

  /// Whether the alarm plays a tone.
  final bool alarmSoundEnabled;

  /// Whether the alarm vibrates (if the device can).
  final bool vibrationEnabled;

  /// How long (seconds) it must be continuously yellow or red before the
  /// alarm fires; within [minAlarmDelaySeconds]..[maxAlarmDelaySeconds].
  final int alarmDelaySeconds;

  /// [alarmDelaySeconds] as the duration the alarm state machine expects.
  Duration get alarmDelay => Duration(seconds: alarmDelaySeconds);

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    Thresholds? thresholds,
    int? calibrationCorrectionDb,
    bool? alarmSoundEnabled,
    bool? vibrationEnabled,
    int? alarmDelaySeconds,
  }) => AppSettings(
    thresholds: thresholds ?? this.thresholds,
    calibrationCorrectionDb:
        calibrationCorrectionDb ?? this.calibrationCorrectionDb,
    alarmSoundEnabled: alarmSoundEnabled ?? this.alarmSoundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    alarmDelaySeconds: alarmDelaySeconds ?? this.alarmDelaySeconds,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.thresholds == thresholds &&
      other.calibrationCorrectionDb == calibrationCorrectionDb &&
      other.alarmSoundEnabled == alarmSoundEnabled &&
      other.vibrationEnabled == vibrationEnabled &&
      other.alarmDelaySeconds == alarmDelaySeconds;

  @override
  int get hashCode => Object.hash(
    thresholds,
    calibrationCorrectionDb,
    alarmSoundEnabled,
    vibrationEnabled,
    alarmDelaySeconds,
  );

  static void _checkRange(int value, int min, int max, String name) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'must be within $min..$max');
    }
  }
}
