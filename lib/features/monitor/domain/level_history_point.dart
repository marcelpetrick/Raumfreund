// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// One point of the level timeline ("heartbeat monitor").
///
/// Holds only a number and a monotonic timestamp – never audio.
final class LevelHistoryPoint {
  /// Creates a point.
  const LevelHistoryPoint({required this.timestamp, required this.levelDb});

  /// Monotonic time of the measurement (see MonotonicClock).
  final Duration timestamp;

  /// Estimated level in dB (0–130).
  final double levelDb;

  @override
  bool operator ==(Object other) =>
      other is LevelHistoryPoint &&
      other.timestamp == timestamp &&
      other.levelDb == levelDb;

  @override
  int get hashCode => Object.hash(timestamp, levelDb);
}
