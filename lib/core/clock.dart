// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Monotonic time source.
///
/// All timing decisions (alarm phases, measurement gaps, history) use this
/// interface instead of wall-clock time so they are immune to clock changes
/// and can be driven by a fake clock in tests.
abstract interface class MonotonicClock {
  /// Time elapsed since an arbitrary but fixed origin. Never decreases.
  Duration get now;
}

/// [MonotonicClock] backed by a [Stopwatch] started on construction.
final class StopwatchClock implements MonotonicClock {
  /// Creates and starts the clock.
  StopwatchClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get now => _stopwatch.elapsed;
}
