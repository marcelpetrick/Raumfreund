// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/rendering.dart';

import '../../../shop/domain/kitty_accessory.dart';
import 'kitty_accessories.dart';
import 'kitty_body.dart';
import 'kitty_effects.dart';
import 'kitty_face.dart';
import 'kitty_mood.dart';
import 'kitty_pose.dart';

/// Size of the design box Mia is drawn in (scaled to fit the canvas).
const Size kKittyDesignSize = Size(240, 224);

/// Vector painter of Mia the chibi kitty on her little glowing stage.
///
/// Everything is drawn in a 240×224 design box that is scaled uniformly and
/// anchored to the bottom centre. [walk] moves her to the right until she has
/// completely left the visible canvas.
class KittyPainter extends CustomPainter {
  /// Creates the painter.
  const KittyPainter({
    required this.mood,
    required this.phase,
    required this.walk,
    this.running = false,
    this.accessories = const <KittyAccessory>{},
  });

  /// Mood to draw.
  final KittyMood mood;

  /// Position in the 0..1 idle loop.
  final double phase;

  /// Walk-away progress (0 on stage, 1 gone).
  final double walk;

  /// Whether the walk is a scared run away (false: calm walk back).
  final bool running;

  /// Items Mia wears or plays with.
  ///
  /// Everything she wears moves with her; the toy mouse stays on the stage.
  final Set<KittyAccessory> accessories;

  /// Fleeing Mia is scared whatever the current zone says.
  KittyMood get _shown => running ? KittyMood.scared : mood;

  /// Horizontal walk offset in design units for a canvas of [size].
  static double walkOffset(Size size, double walk) {
    final scale = _scaleFor(size);
    return walk * (size.width / 2 / scale + kKittyDesignSize.width / 2 + 20);
  }

  static double _scaleFor(Size size) => math.min(
    size.width / kKittyDesignSize.width,
    size.height / kKittyDesignSize.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = _scaleFor(size);
    if (scale <= 0) return;
    final pose = KittyPose.of(mood, phase, walk, running: running);
    final walkDx = walkOffset(size, walk);
    canvas
      ..save()
      ..translate(
        (size.width - kKittyDesignSize.width * scale) / 2,
        size.height - kKittyDesignSize.height * scale,
      )
      ..scale(scale);
    paintStage(canvas, _shown.glowColor);
    if (walk > 0) paintPawPrints(canvas, walkDx);
    if (accessories.contains(KittyAccessory.mouse)) paintMouse(canvas);
    canvas
      ..save()
      ..translate(walkDx + pose.shakeDx, pose.bobDy);
    _paintKitty(canvas, pose);
    canvas
      ..restore()
      ..restore();
  }

  void _paintKitty(Canvas canvas, KittyPose pose) {
    _paintAura(canvas);
    for (final layer in KittyLayer.values) {
      _paintLayer(canvas, pose, layer);
    }
    canvas.save();
    // While walking, the face is shifted sideways so that Mia appears to
    // turn her head: ahead when walking, back over her shoulder when running.
    if (pose.walking) canvas.translate(pose.lookDx, 0);
    paintFace(canvas, _shown, pose);
    canvas.restore();
    switch (_shown) {
      case KittyMood.happy:
        paintPurr(canvas, phase);
      case KittyMood.uneasy:
        paintSweat(canvas, phase);
      case KittyMood.scared:
        paintWhimper(canvas, phase);
      case KittyMood.idle:
        break;
    }
  }

  /// One silhouette pass. Cushion goes below everything, the scarf between
  /// body and head, bow and hat on top of the head; none of them reaches the
  /// face, which is painted afterwards anyway.
  void _paintLayer(Canvas canvas, KittyPose pose, KittyLayer layer) {
    if (accessories.contains(KittyAccessory.cushion)) {
      paintCushion(canvas, layer);
    }
    paintTail(canvas, pose, layer);
    paintBody(canvas, layer);
    paintPaws(canvas, pose, layer);
    if (accessories.contains(KittyAccessory.scarf)) paintScarf(canvas, layer);
    paintHead(canvas, pose, layer);
    if (accessories.contains(KittyAccessory.bow)) {
      paintBow(canvas, pose, layer);
    }
    if (accessories.contains(KittyAccessory.hat)) {
      paintHat(canvas, pose, layer);
    }
  }

  void _paintAura(Canvas canvas) {
    final aura = Paint()
      ..color = _shown.glowColor.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(const Rect.fromLTWH(34, 20, 172, 190), aura);
  }

  @override
  bool shouldRepaint(KittyPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.phase != phase ||
      oldDelegate.walk != walk ||
      oldDelegate.running != running ||
      !setEquals(oldDelegate.accessories, accessories);
}
