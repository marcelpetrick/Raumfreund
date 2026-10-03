// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import '../../monitor/domain/thresholds.dart';

/// User settings of Raumfreund. Always valid (see [Thresholds]).
final class AppSettings {
  /// Creates settings; throws [ArgumentError] for an out-of-range
  /// [calibrationCorrectionDb].
  AppSettings({
    required this.thresholds,
    required this.calibrationCorrectionDb,
    required this.alarmSoundEnabled,
    required this.vibrationEnabled,
  }) {
    if (calibrationCorrectionDb < minCalibrationDb ||
        calibrationCorrectionDb > maxCalibrationDb) {
      throw ArgumentError.value(
        calibrationCorrectionDb,
        'calibrationCorrectionDb',
        'must be within $minCalibrationDb..$maxCalibrationDb',
      );
    }
  }

  /// Lowest calibration correction.
  static const int minCalibrationDb = -30;

  /// Highest calibration correction.
  static const int maxCalibrationDb = 30;

  /// Factory defaults.
  static final AppSettings defaults = AppSettings(
    thresholds: Thresholds.defaults,
    calibrationCorrectionDb: 0,
    alarmSoundEnabled: true,
    vibrationEnabled: true,
  );

  /// Zone limits.
  final Thresholds thresholds;

  /// User correction added to the estimated level (dB).
  final int calibrationCorrectionDb;

  /// Whether the alarm plays a tone.
  final bool alarmSoundEnabled;

  /// Whether the alarm vibrates (if the device can).
  final bool vibrationEnabled;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    Thresholds? thresholds,
    int? calibrationCorrectionDb,
    bool? alarmSoundEnabled,
    bool? vibrationEnabled,
  }) => AppSettings(
    thresholds: thresholds ?? this.thresholds,
    calibrationCorrectionDb:
        calibrationCorrectionDb ?? this.calibrationCorrectionDb,
    alarmSoundEnabled: alarmSoundEnabled ?? this.alarmSoundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.thresholds == thresholds &&
      other.calibrationCorrectionDb == calibrationCorrectionDb &&
      other.alarmSoundEnabled == alarmSoundEnabled &&
      other.vibrationEnabled == vibrationEnabled;

  @override
  int get hashCode => Object.hash(
    thresholds,
    calibrationCorrectionDb,
    alarmSoundEnabled,
    vibrationEnabled,
  );
}
