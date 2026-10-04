// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'kitty_mood.dart';

/// Number of steps Mia takes while walking calmly back onto her stage.
const int kKittyWalkSteps = 6;

/// Number of (quicker, smaller) steps while she runs away scared.
const int kKittyRunSteps = 8;

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
    required this.tailPuff,
  });

  /// Derives the pose.
  ///
  /// [phase] is the position in the 0..1 idle loop (always 0 with reduced
  /// motion); [walk] is 0 when Mia sits on her stage and 1 when she is gone.
  /// With [running] she flees: she is scared whatever [shown] says, takes
  /// quick steps and looks back over her shoulder.
  factory KittyPose.of(
    KittyMood shown,
    double phase,
    double walk, {
    bool running = false,
  }) {
    final mood = running ? KittyMood.scared : shown;
    final walking = walk > 0 && walk < 1;
    final steps = running ? kKittyRunSteps : kKittyWalkSteps;
    final step = math.sin(walk * steps * 2 * math.pi);
    final wave = math.sin(phase * 2 * math.pi);
    // Fast, small tremble: 32 oscillations per loop instead of slow sobbing.
    final tremble = math.sin(phase * 64 * math.pi);
    return KittyPose(
      eyeOpen: mood == KittyMood.idle ? _blink(phase) : 1,
      earDroop: switch (mood) {
        KittyMood.idle || KittyMood.happy => 0,
        KittyMood.uneasy => 0.75,
        KittyMood.scared => 1,
      },
      tailAngle: switch (mood) {
        KittyMood.idle => 0.06 * wave,
        KittyMood.happy => 0.22 * math.sin(phase * 4 * math.pi),
        KittyMood.uneasy => 0.28 + 0.03 * math.sin(phase * 12 * math.pi),
        KittyMood.scared => 0.75 + 0.04 * tremble,
      },
      shakeDx: mood == KittyMood.scared && !walking ? tremble : 0,
      bobDy: walking
          ? (running ? -4 : -3) * step.abs()
          : (mood == KittyMood.happy ? 1.5 * wave : 0),
      leftPawLift: walking ? 8 * math.max(0, step) : 0,
      rightPawLift: walking ? 8 * math.max(0, -step) : 0,
      lookDx: _lookDx(mood, walking, running),
      walking: walking,
      tailPuff: mood == KittyMood.scared ? 1 : 0,
    );
  }

  /// Pupils look ahead while walking, back over the shoulder while fleeing.
  static double _lookDx(KittyMood mood, bool walking, bool running) {
    if (walking) return running ? -6 : 6;
    return mood == KittyMood.uneasy ? -3 : 0;
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

  /// Horizontal trembling in design units (scared only).
  final double shakeDx;

  /// Puffed-up tail fur (0 normal, 1 fully bushy).
  final double tailPuff;

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
