// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'peak_envelope.dart';

/// Attack/release smoothing of the *displayed* gauge level only.
///
/// The alarm decision always uses the unsmoothed estimate; this filter just
/// calms the gauge. It is a [PeakEnvelope] tuned for responsiveness: the
/// needle rises almost immediately but falls back with a ~1 s release, so
/// it does not jitter with every quiet 100 ms sample. The timeline uses the
/// same envelope with a much longer release (see LevelHistory), which keeps
/// the gauge feeling live while the chart shows the cool-down.
final class DisplaySmoother {
  /// Creates a smoother with the given time constants.
  DisplaySmoother({
    Duration attack = defaultAttack,
    Duration release = defaultRelease,
  }) : _envelope = PeakEnvelope(attack: attack, release: release);

  /// Default attack: 100 ms, i.e. one microphone reading. Short enough
  /// that a peak is visible within ~0.2 s, long enough that a single click
  /// does not slam the needle to the top.
  static const Duration defaultAttack = Duration(milliseconds: 100);

  /// Default release: 1 s. Responsive, but slower than the attack so the
  /// gauge does not flicker between loud and quiet samples.
  static const Duration defaultRelease = Duration(seconds: 1);

  final PeakEnvelope _envelope;

  /// Time constant for rising levels.
  Duration get attack => _envelope.attack;

  /// Time constant for falling levels.
  Duration get release => _envelope.release;

  /// Current smoothed value; null before the first sample/after [reset].
  double? get value => _envelope.value;

  /// Adds a sample taken at monotonic [timestamp] and returns the new value.
  /// The first sample is taken over directly. Non-finite samples are ignored.
  double? add({required Duration timestamp, required double levelDb}) =>
      _envelope.add(timestamp: timestamp, levelDb: levelDb);

  /// Forgets the state (stop, new session).
  void reset() => _envelope.reset();
}
