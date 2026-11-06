// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../../shop/domain/kitty_accessory.dart';
import '../kitty/kitty_accessories.dart';
import '../kitty/kitty_body.dart' show KittyLayer, paintStage;
import '../kitty/kitty_effects.dart';
import '../kitty/kitty_mood.dart';
import '../kitty/kitty_painter.dart' show kKittyDesignSize, kKittyWakeLead;
import '../kitty/kitty_pose.dart';
import 'husky_shapes.dart';

/// Draws Flocke using Mia's stage, animation timing and accessory coordinates.
class HuskyPainter extends CustomPainter {
  /// Creates a frame of Flocke.
  const HuskyPainter({
    required this.mood,
    required this.phase,
    required this.walk,
    this.running = false,
    this.accessories = const <KittyAccessory>{},
    this.wake,
    this.danceProgress,
  });

  /// Current room mood.
  final KittyMood mood;

  /// Loop progress between zero and one.
  final double phase;

  /// Exit progress between zero and one.
  final double walk;

  /// Whether Flocke runs away scared.
  final bool running;

  /// Cosmetic items shown with Flocke.
  final Set<KittyAccessory> accessories;

  /// Wake-up progress, including the initial sleeping interval.
  final double? wake;

  /// Optional 0..1 shop dance, ignored for sleeping, waking or moving away.
  final double? danceProgress;

  static const double _padding = 40;

  /// Scale-independent displacement needed to leave a clipped scene.
  static double walkOffset(Size size, double walk) {
    final scale = _scaleFor(size);
    if (scale <= 0) return 0;
    return walk * (size.width / 2 / scale + kKittyDesignSize.width / 2 + 60);
  }

  static double _scaleFor(Size size) => math.min(
    size.width / (kKittyDesignSize.width + 2 * _padding),
    size.height / (kKittyDesignSize.height + 2 * _padding),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleFor(size);
    if (scale <= 0) return;
    final lead = wake != null && wake! < kKittyWakeLead;
    final drawn = lead ? KittyMood.sleeping : mood;
    final shown = running ? KittyMood.scared : drawn;
    final waking = wake == null || lead
        ? null
        : (wake! - kKittyWakeLead) / (1 - kKittyWakeLead);
    final basePose = KittyPose.of(
      drawn,
      phase,
      walk,
      running: running,
      wake: waking,
    );
    final dance = _danceAmount(drawn);
    final pose = dance == null ? basePose : _dancingPose(basePose, dance);
    final dx = walkOffset(size, walk);
    canvas
      ..save()
      ..translate(
        (size.width - kKittyDesignSize.width * scale) / 2,
        (size.height - kKittyDesignSize.height * scale) / 2,
      )
      ..scale(scale);
    paintStage(canvas, shown.glowColor);
    if (walk > 0) paintPawPrints(canvas, dx);
    if (accessories.contains(KittyAccessory.mouse)) paintMouse(canvas);
    canvas
      ..save()
      ..translate(dx + pose.shakeDx, pose.bobDy)
      ..translate(120, 185)
      ..rotate(dance == null ? 0 : _danceSway(dance) * 0.08)
      ..translate(-120, -185);
    for (final layer in KittyLayer.values) {
      _paintLayer(canvas, pose, layer);
    }
    paintHuskyFace(canvas, shown, pose);
    _paintEffects(canvas, shown, pose);
    canvas
      ..restore()
      ..restore();
  }

  double? _danceAmount(KittyMood drawn) {
    final progress = danceProgress;
    if (progress == null ||
        !progress.isFinite ||
        running ||
        walk != 0 ||
        wake != null ||
        drawn == KittyMood.sleeping) {
      return null;
    }
    return progress.clamp(0.0, 1.0);
  }

  double _danceSway(double progress) {
    if (progress <= 0 || progress >= 1) return 0;
    return math.sin(progress * math.pi) * math.sin(progress * math.pi * 8);
  }

  KittyPose _dancingPose(KittyPose base, double progress) {
    final sway = _danceSway(progress);
    return KittyPose(
      eyeOpen: base.eyeOpen,
      earDroop: base.earDroop,
      tailAngle: base.tailAngle + sway * 0.5,
      shakeDx: base.shakeDx,
      bobDy: base.bobDy - sway.abs() * 3,
      leftPawLift: base.leftPawLift + math.max(0, sway) * 7,
      rightPawLift: base.rightPawLift + math.max(0, -sway) * 7,
      lookDx: base.lookDx,
      walking: base.walking,
      tailPuff: base.tailPuff,
      yawn: base.yawn,
      wake: base.wake,
    );
  }

  void _paintLayer(Canvas canvas, KittyPose pose, KittyLayer layer) {
    if (accessories.contains(KittyAccessory.cushion)) {
      paintCushion(canvas, layer);
    }
    paintHuskyTail(canvas, pose, layer);
    paintHuskyBody(canvas, pose, layer);
    if (accessories.contains(KittyAccessory.scarf)) paintScarf(canvas, layer);
    paintHuskyHead(canvas, pose, layer);
    if (accessories.contains(KittyAccessory.bow)) {
      // Mia's ears fold much farther than Flocke's upright ears.
      canvas
        ..save()
        ..translate(24 * pose.earDroop, -24 * pose.earDroop);
      paintBow(canvas, pose, layer);
      canvas.restore();
    }
    if (accessories.contains(KittyAccessory.hat)) paintHat(canvas, pose, layer);
  }

  void _paintEffects(Canvas canvas, KittyMood shown, KittyPose pose) {
    if (pose.wake != null) {
      paintZzz(canvas, phase, opacity: 1 - pose.wake! / 0.3);
      paintWakeSparkles(canvas, pose.wake!);
      return;
    }
    switch (shown) {
      case KittyMood.happy:
        paintHuskyJoy(canvas, phase);
      case KittyMood.uneasy:
        paintSweat(canvas, phase);
      case KittyMood.scared:
        paintWhimper(canvas, phase);
      case KittyMood.sleeping:
        paintNoseBubble(canvas, phase);
        paintZzz(canvas, phase);
      case KittyMood.idle:
        break;
    }
  }

  @override
  bool shouldRepaint(HuskyPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.phase != phase ||
      oldDelegate.walk != walk ||
      oldDelegate.running != running ||
      oldDelegate.wake != wake ||
      oldDelegate.danceProgress != danceProgress ||
      !setEquals(oldDelegate.accessories, accessories);
}
