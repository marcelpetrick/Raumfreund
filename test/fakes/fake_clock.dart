// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:raumfreund/core/clock.dart';

/// Manually driven [MonotonicClock] for tests.
final class FakeClock implements MonotonicClock {
  /// Creates a clock at [start].
  FakeClock([Duration start = Duration.zero]) : _now = start;

  Duration _now;

  @override
  Duration get now => _now;

  /// Moves the clock forward by [delta] (must not be negative).
  void advance(Duration delta) {
    if (delta.isNegative) {
      throw ArgumentError.value(delta, 'delta', 'clock is monotonic');
    }
    _now += delta;
  }

  /// Moves the clock forward by [milliseconds].
  void advanceMs(int milliseconds) =>
      advance(Duration(milliseconds: milliseconds));
}
