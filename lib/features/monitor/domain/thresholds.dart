// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'zone.dart';

/// Validated zone limits in whole dB of the estimated level.
///
/// Invariant: `minDb <= yellowDb < redDb <= maxDb`. Instances can only be
/// created through [Thresholds.new] (throws) or [Thresholds.tryCreate]
/// (returns null), so an invalid combination can never exist.
final class Thresholds {
  /// Creates thresholds or throws an [ArgumentError] if they are invalid.
  Thresholds({required this.yellowDb, required this.redDb}) {
    if (!isValid(yellowDb: yellowDb, redDb: redDb)) {
      throw ArgumentError(
        'Invalid thresholds: require $minDb <= yellow < red <= $maxDb, '
        'got yellow=$yellowDb red=$redDb',
      );
    }
  }

  /// Lowest value of the scale.
  static const int minDb = 0;

  /// Highest value of the scale.
  static const int maxDb = 130;

  /// Default start of the yellow zone.
  static const int defaultYellowDb = 60;

  /// Default start of the red zone.
  static const int defaultRedDb = 80;

  /// Default thresholds (60 / 80 dB).
  static final Thresholds defaults = Thresholds(
    yellowDb: defaultYellowDb,
    redDb: defaultRedDb,
  );

  /// Start of the yellow zone (inclusive).
  final int yellowDb;

  /// Start of the red zone (inclusive).
  final int redDb;

  /// Whether the given pair satisfies the invariant.
  static bool isValid({required int yellowDb, required int redDb}) =>
      minDb <= yellowDb && yellowDb < redDb && redDb <= maxDb;

  /// Returns thresholds for a valid pair, otherwise null.
  static Thresholds? tryCreate({required int yellowDb, required int redDb}) =>
      isValid(yellowDb: yellowDb, redDb: redDb)
      ? Thresholds(yellowDb: yellowDb, redDb: redDb)
      : null;

  /// Classifies an estimated level. A value exactly on a limit belongs to the
  /// higher zone (vision §3).
  Zone classify(double levelDb) {
    if (levelDb >= redDb) return Zone.red;
    if (levelDb >= yellowDb) return Zone.yellow;
    return Zone.green;
  }

  @override
  bool operator ==(Object other) =>
      other is Thresholds && other.yellowDb == yellowDb && other.redDb == redDb;

  @override
  int get hashCode => Object.hash(yellowDb, redDb);

  @override
  String toString() => 'Thresholds(yellow: $yellowDb, red: $redDb)';
}
