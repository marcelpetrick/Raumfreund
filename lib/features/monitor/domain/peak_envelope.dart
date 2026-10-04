// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

/// "Fast attack, slow release" envelope follower for *displayed* levels.
///
/// Rising levels are followed with the short [attack] time constant,
/// falling levels with the long [release] one. This asymmetry is the
/// hysteresis the display needs: a peak shows up at once, but the value
/// cools down gradually instead of bouncing back with every quiet sample.
///
/// Both directions use exponential smoothing in the dB domain,
/// `alpha = 1 - exp(-dt / tau)`, computed from the real time between two
/// sample timestamps, so the result does not depend on the sample rate.
/// Exponential (rather than a fixed dB/s slope) was chosen because one
/// formula then serves attack and release, it never overshoots the input
/// and a short release still settles quickly on small changes.
///
/// Pure domain logic: no Flutter, no real clock, no audio.
final class PeakEnvelope {
  /// Creates an envelope. [attack] may be zero (follow rises instantly);
  /// [release] must be positive.
  PeakEnvelope({required this.attack, required this.release})
    : assert(attack >= Duration.zero, 'attack must not be negative'),
      assert(release > Duration.zero, 'release must be positive');

  /// Time constant for rising levels; zero means "jump to the peak".
  final Duration attack;

  /// Time constant for falling levels (~63 % of a drop after this time).
  final Duration release;

  double? _value;
  Duration? _lastTimestamp;

  /// Current envelope value; null before the first sample/after [reset].
  double? get value => _value;

  /// Feeds a level taken at monotonic [timestamp] and returns the new
  /// envelope value. The first sample is taken over directly; non-finite
  /// samples and non-advancing timestamps leave the value unchanged.
  double? add({required Duration timestamp, required double levelDb}) {
    if (!levelDb.isFinite) return _value;
    final previous = _value;
    final last = _lastTimestamp;
    if (previous == null || last == null) {
      _lastTimestamp = timestamp;
      return _value = levelDb;
    }
    final dt = timestamp - last;
    if (dt <= Duration.zero) return previous;
    _lastTimestamp = timestamp;
    final tau = levelDb > previous ? attack : release;
    if (tau == Duration.zero) return _value = levelDb;
    final alpha = 1 - math.exp(-dt.inMicroseconds / tau.inMicroseconds);
    return _value = previous + alpha * (levelDb - previous);
  }

  /// Forgets the state (stop, new session, gap in the measurement).
  void reset() {
    _value = null;
    _lastTimestamp = null;
  }
}
