// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Converts digital microphone levels (dBFS) into the *estimated* sound level
/// shown by Raumfreund.
///
/// This is deliberately simple: a constant offset cannot turn dBFS into a
/// device-independent dB SPL measurement (automatic gain, microphone
/// sensitivity and housing differ per device). The user can shift the result
/// with [correctionDb] after comparing with a reference meter.
final class Calibration {
  /// Creates a calibration with the user's [correctionDb] (see
  /// `AppSettings.calibrationCorrectionDb`).
  const Calibration({this.correctionDb = 0});

  /// Fixed offset added to every dBFS value.
  ///
  /// Typical phone microphones reach digital full scale (0 dBFS) at roughly
  /// 90 dB SPL, so 0 dBFS maps to ~90 dB. This is a rough, device-dependent
  /// assumption, not a calibrated value.
  static const double baseOffsetDb = 90;

  /// Lowest estimated level (bottom of the 0–130 dB scale).
  static const double minDb = 0;

  /// Highest estimated level (top of the 0–130 dB scale).
  static const double maxDb = 130;

  /// User correction in dB added after [baseOffsetDb].
  final int correctionDb;

  /// Estimated level in dB for a dBFS value, clamped to [minDb]..[maxDb].
  ///
  /// Returns null for NaN or infinite input: such a sample is invalid and
  /// must be ignored by the caller (it neither counts as measurement time
  /// nor resets anything).
  double? estimate(double dbfs) {
    if (!dbfs.isFinite) return null;
    return (dbfs + baseOffsetDb + correctionDb).clamp(minDb, maxDb);
  }
}
