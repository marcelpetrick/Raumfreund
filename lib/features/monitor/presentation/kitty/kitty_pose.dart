// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;

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
    this.yawn = 0,
    this.wake,
  });

  /// Derives the pose.
  ///
  /// [phase] is the position in the 0..1 idle loop (always 0 with reduced
  /// motion); [walk] is 0 when Mia sits on her stage and 1 when she is gone.
  /// With [running] she flees: she is scared whatever [shown] says, takes
  /// quick steps and looks back over her shoulder. A non-null [wake] (0..1)
  /// is the progress of waking up from [KittyMood.sleeping] into [shown].
  factory KittyPose.of(
    KittyMood shown,
    double phase,
    double walk, {
    bool running = false,
    double? wake,
  }) {
    final mood = running ? KittyMood.scared : shown;
    final pose = KittyPose._base(mood, phase, walk, running: running);
    final asleep = mood == KittyMood.sleeping;
    return wake == null || asleep ? pose : pose._wakingUp(wake);
  }

  /// Pose of [mood] without waking up. Asleep, her eyes are closed, the
  /// ears a little relaxed, the tail rests and the body rises and sinks
  /// with one slow breath per loop.
  factory KittyPose._base(
    KittyMood mood,
    double phase,
    double walk, {
    required bool running,
  }) {
    final walking = walk > 0 && walk < 1;
    final steps = running ? kKittyRunSteps : kKittyWalkSteps;
    final step = math.sin(walk * steps * 2 * math.pi);
    final wave = math.sin(phase * 2 * math.pi);
    // Fast, small tremble: 32 oscillations per loop instead of slow sobbing.
    final tremble = math.sin(phase * 64 * math.pi);
    return KittyPose(
      eyeOpen: switch (mood) {
        KittyMood.idle => _blink(phase),
        KittyMood.sleeping => 0,
        KittyMood.happy || KittyMood.uneasy || KittyMood.scared => 1,
      },
      earDroop: switch (mood) {
        KittyMood.idle || KittyMood.happy => 0,
        KittyMood.uneasy => 0.75,
        KittyMood.scared => 1,
        KittyMood.sleeping => _sleepEarDroop,
      },
      tailAngle: switch (mood) {
        KittyMood.idle => 0.06 * wave,
        KittyMood.happy => 0.22 * math.sin(phase * 4 * math.pi),
        KittyMood.uneasy => 0.28 + 0.03 * math.sin(phase * 12 * math.pi),
        KittyMood.scared => 0.75 + 0.04 * tremble,
        KittyMood.sleeping => 0.04 * wave,
      },
      shakeDx: mood == KittyMood.scared && !walking ? tremble : 0,
      bobDy: walking
          ? (running ? -4 : -3) * step.abs()
          : switch (mood) {
              KittyMood.happy => 1.5 * wave,
              KittyMood.sleeping => 1.4 * wave,
              KittyMood.idle || KittyMood.uneasy || KittyMood.scared => 0,
            },
      leftPawLift: walking ? 8 * math.max(0, step) : 0,
      rightPawLift: walking ? 8 * math.max(0, -step) : 0,
      lookDx: _lookDx(mood, walking, running),
      walking: walking,
      tailPuff: mood == KittyMood.scared ? 1 : 0,
    );
  }

  /// Blends this awake pose with waking up at progress [wake] (0..1): she
  /// yawns, blinks herself awake, stretches upwards with lifted paws and
  /// raised tail, and her relaxed ears perk up.
  KittyPose _wakingUp(double wake) {
    final w = wake.clamp(0.0, 1.0);
    final stretch = math.sin(_window(w, 0.3, 0.75) * math.pi);
    final perk = Curves.easeOut.transform(_window(w, 0.2, 0.7));
    return KittyPose(
      eyeOpen: _wakeEyes(w),
      earDroop: _sleepEarDroop + (earDroop - _sleepEarDroop) * perk,
      tailAngle: tailAngle + 0.3 * stretch,
      shakeDx: 0,
      bobDy: -7 * stretch,
      leftPawLift: 5 * stretch,
      rightPawLift: 5 * stretch,
      lookDx: 0,
      walking: false,
      tailPuff: 0,
      yawn: math.sin(_window(w, 0.04, 0.42) * math.pi),
      wake: w,
    );
  }

  /// Ear droop of the sleeping and just waking Mia.
  static const double _sleepEarDroop = 0.3;

  /// Position of [x] inside [start]..[end], clamped to 0..1.
  static double _window(double x, double start, double end) =>
      ((x - start) / (end - start)).clamp(0.0, 1.0);

  /// Sleepy eyes: closed while yawning, half open, one slow blink, open.
  static double _wakeEyes(double w) {
    if (w < 0.4) return 0;
    if (w < 0.55) return 0.55 * _window(w, 0.4, 0.55);
    if (w < 0.65) return 0.55 - 0.45 * _window(w, 0.55, 0.65);
    return 0.1 + 0.9 * Curves.easeOut.transform(_window(w, 0.65, 0.9));
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

  /// How wide she yawns while waking up (0 mouth closed, 1 widest).
  final double yawn;

  /// Wake-up progress (0..1) while waking from sleep, otherwise null.
  final double? wake;
}
