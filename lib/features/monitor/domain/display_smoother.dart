// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

/// Exponential smoothing of the *displayed* level only.
///
/// The alarm decision always uses the unsmoothed estimate; this filter just
/// calms the gauge. The weight of a new sample depends on the real time
/// since the previous one (`alpha = 1 - exp(-dt / timeConstant)`), so the
/// result does not depend on the sample or frame rate.
final class DisplaySmoother {
  /// Creates a smoother with [timeConstant] (default ~300 ms: follows
  /// changes within about a second without flickering).
  DisplaySmoother({this.timeConstant = defaultTimeConstant})
    : assert(timeConstant > Duration.zero, 'timeConstant must be positive');

  /// Default time constant.
  static const Duration defaultTimeConstant = Duration(milliseconds: 300);

  /// Time after which ~63 % of a step change is shown.
  final Duration timeConstant;

  double? _value;
  Duration? _lastTimestamp;

  /// Current smoothed value; null before the first sample/after [reset].
  double? get value => _value;

  /// Adds a sample taken at monotonic [timestamp] and returns the new value.
  /// The first sample is taken over directly. Non-finite samples are ignored.
  double? add({required Duration timestamp, required double levelDb}) {
    if (!levelDb.isFinite) return _value;
    final previous = _value;
    final last = _lastTimestamp;
    _lastTimestamp = timestamp;
    if (previous == null || last == null) return _value = levelDb;
    final dt = (timestamp - last).inMicroseconds;
    if (dt <= 0) return previous;
    final alpha = 1 - math.exp(-dt / timeConstant.inMicroseconds);
    return _value = previous + alpha * (levelDb - previous);
  }

  /// Forgets the state (stop, new session).
  void reset() {
    _value = null;
    _lastTimestamp = null;
  }
}
