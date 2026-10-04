// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'kitty_mood.dart';

/// Number of steps Mia takes while walking off (or back onto) her stage.
const int kKittyWalkSteps = 6;

/// All animated parameters of one kitty frame, derived from mood, loop
/// phase and walk progress by [KittyPose.of]. Pure, so it is unit-tested.
final class KittyPose {
  /// Creates a pose.
  const KittyPose({
    required this.eyeOpen,
    required this.earDroop,
    required this.tailAngle,
    required this.shakeDx,
    required this.bobDy,
    required this.leftPawLift,
    required this.rightPawLift,
    required this.lookDx,
    required this.walking,
  });

  /// Derives the pose.
  ///
  /// [phase] is the position in the 0..1 idle loop (always 0 with reduced
  /// motion); [walk] is 0 when Mia sits on her stage and 1 when she is gone.
  factory KittyPose.of(KittyMood mood, double phase, double walk) {
    final walking = walk > 0 && walk < 1;
    final step = math.sin(walk * kKittyWalkSteps * 2 * math.pi);
    final wave = math.sin(phase * 2 * math.pi);
    return KittyPose(
      eyeOpen: mood == KittyMood.idle ? _blink(phase) : 1,
      earDroop: switch (mood) {
        KittyMood.idle || KittyMood.happy => 0,
        KittyMood.uneasy => 0.75,
        KittyMood.crying => 1,
      },
      tailAngle: switch (mood) {
        KittyMood.idle => 0.06 * wave,
        KittyMood.happy => 0.22 * math.sin(phase * 4 * math.pi),
        KittyMood.uneasy => 0.28 + 0.03 * math.sin(phase * 12 * math.pi),
        KittyMood.crying => 0.4,
      },
      shakeDx: mood == KittyMood.crying && !walking
          ? 1.8 * math.sin(phase * 16 * math.pi)
          : 0,
      bobDy: walking
          ? -3 * step.abs()
          : (mood == KittyMood.happy ? 1.5 * wave : 0),
      leftPawLift: walking ? 8 * math.max(0, step) : 0,
      rightPawLift: walking ? 8 * math.max(0, -step) : 0,
      lookDx: walking ? 6 : (mood == KittyMood.uneasy ? -3 : 0),
      walking: walking,
    );
  }

  /// Slow blink at the end of every loop: 1 = open, ~0 = closed.
  static double _blink(double phase) {
    const start = 0.92;
    if (phase < start) return 1;
    return 1 - 0.95 * math.sin((phase - start) / (1 - start) * math.pi);
  }

  /// Eye openness (1 open, 0 closed).
  final double eyeOpen;

  /// Ear droop (0 upright, 1 flat).
  final double earDroop;

  /// Tail rotation around its base in radians.
  final double tailAngle;

  /// Horizontal sobbing shake in design units.
  final double shakeDx;

  /// Vertical body bob in design units (negative = up).
  final double bobDy;

  /// Lift of the left front paw (walk cycle).
  final double leftPawLift;

  /// Lift of the right front paw (walk cycle).
  final double rightPawLift;

  /// Horizontal pupil offset (looking sideways).
  final double lookDx;

  /// Whether Mia is currently walking.
  final bool walking;
}
