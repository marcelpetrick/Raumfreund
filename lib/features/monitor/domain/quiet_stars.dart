// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'zone.dart';

/// Playful reward for children: one star for every full minute of
/// continuous green while measuring.
///
/// Uses the same continuity rule as the alarm: samples more than [maxGap]
/// apart, a non-green sample or [reset] restart the current minute. The star
/// count lives in RAM for the app session only.
final class QuietStars {
  /// Creates a counter without stars.
  QuietStars({this.minute = defaultMinute, this.maxGap = defaultMaxGap});

  /// Continuous green time that earns a star.
  static const Duration defaultMinute = Duration(seconds: 60);

  /// Largest distance between samples that still counts as continuous.
  static const Duration defaultMaxGap = Duration(seconds: 1);

  /// See [defaultMinute].
  final Duration minute;

  /// See [defaultMaxGap].
  final Duration maxGap;

  int _stars = 0;
  Duration? _minuteStart;
  Duration? _lastSample;
  double _progress = 0;
  bool _earnedNow = false;

  /// Stars earned in this app session.
  int get stars => _stars;

  /// Progress (0..1) of the current green minute.
  double get progress => _progress;

  /// True only directly after the sample that earned a star (for a small
  /// celebration); false again after the next sample.
  bool get earnedStarNow => _earnedNow;

  /// Feeds the zone of one valid sample at monotonic [timestamp].
  void onSample({required Duration timestamp, required Zone zone}) {
    final last = _lastSample;
    _lastSample = timestamp;
    _earnedNow = false;
    final delta = last == null ? null : timestamp - last;
    final continuous =
        delta != null && delta >= Duration.zero && delta <= maxGap;
    if (zone != Zone.green) {
      _restartMinute();
      return;
    }
    final start = _minuteStart;
    if (start == null || !continuous) {
      _minuteStart = timestamp;
      _progress = 0;
      return;
    }
    var elapsed = timestamp - start;
    if (elapsed >= minute) {
      _stars++;
      _earnedNow = true;
      _minuteStart = start + minute;
      elapsed -= minute;
    }
    _progress = (elapsed.inMicroseconds / minute.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// Restarts the current minute (stop, gap, error); keeps earned stars.
  void reset() {
    _restartMinute();
    _lastSample = null;
  }

  void _restartMinute() {
    _minuteStart = null;
    _progress = 0;
    _earnedNow = false;
  }
}
