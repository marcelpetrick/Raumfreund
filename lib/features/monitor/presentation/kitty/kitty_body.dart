// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui';

import '../../../../app/theme/glow.dart';
import 'kitty_pose.dart';

/// Colours of Mia's fur and features (taken from the design mockups).
abstract final class KittyColors {
  /// Brightest fur highlight.
  static const Color furLight = Color(0xFFFFFBFE);

  /// Pink-white fur.
  static const Color fur = Color(0xFFFCE6F6);

  /// Lilac fur shade at the edges.
  static const Color furShade = Color(0xFFE2C2F2);

  /// Lilac stripes on forehead and tail.
  static const Color stripe = Color(0xFFD9AEF0);

  /// White belly and paws.
  static const Color belly = Color(0xFFFFF6FC);

  /// Cyan neon outline that glows around Mia.
  static const Color neon = Color(0xFF7DF9FF);

  /// Deep violet of eyes, brows and mouth lines.
  static const Color ink = Color(0xFF2A1846);

  /// Pink of inner ears.
  static const Color innerEar = Color(0xFFFF9CC8);

  /// Blush on the cheeks.
  static const Color blush = Color(0xFFFF7FB8);

  /// Nose.
  static const Color nose = Color(0xFFFF6FA8);

  /// Tongue.
  static const Color tongue = Color(0xFFFF5C93);

  /// Inside of an open mouth.
  static const Color mouth = Color(0xFF5A1838);

  /// Lower, lighter part of the eyes.
  static const Color iris = Color(0xFF3BA7FF);
}

/// The two passes in which Mia's silhouette is drawn: first a cyan neon
/// outline behind every part, then the fur fills on top.
enum KittyLayer {
  /// Cyan glow and outline.
  neon,

  /// Fur fill.
  fill,
}

final Paint _neonHalo = Glow.haloStroke(KittyColors.neon, 14, sigma: 7);
final Paint _neonLine = Glow.stroke(KittyColors.neon, 6);

/// Draws [path] in [layer]: neon outline or fur fill ([fill] or gradient).
void drawFurPath(Canvas canvas, Path path, KittyLayer layer, {Color? fill}) {
  if (layer == KittyLayer.neon) {
    canvas
      ..drawPath(path, _neonHalo)
      ..drawPath(path, _neonLine);
    return;
  }
  final bounds = path.getBounds();
  final paint = Paint();
  if (fill != null) {
    paint.color = fill;
  } else {
    paint.shader = Gradient.radial(
      bounds.topLeft + Offset(bounds.width * 0.42, bounds.height * 0.35),
      0.75 * (bounds.width > bounds.height ? bounds.width : bounds.height),
      const [KittyColors.furLight, KittyColors.fur, KittyColors.furShade],
      const [0, 0.6, 1],
    );
  }
  canvas.drawPath(path, paint);
}

/// Draws an oval [rect] as part of the silhouette.
void drawFurOval(Canvas canvas, Rect rect, KittyLayer layer, {Color? fill}) =>
    drawFurPath(canvas, Path()..addOval(rect), layer, fill: fill);

/// Glowing double ring on the floor of Mia's stage in the mood colour.
void paintStage(Canvas canvas, Color glow) {
  final outer = Rect.fromCenter(
    center: const Offset(120, 208),
    width: 176,
    height: 26,
  );
  final inner = outer.deflate(22);
  canvas
    ..drawOval(outer, Glow.halo(glow, sigma: 12, alpha: 0.35))
    ..drawOval(outer, Glow.stroke(glow.withValues(alpha: 0.8), 2))
    ..drawOval(inner, Glow.haloStroke(KittyColors.neon, 4, sigma: 4))
    ..drawOval(inner, Glow.stroke(KittyColors.neon, 2));
}

final Rect _headRect = Rect.fromCenter(
  center: const Offset(120, 92),
  width: 144,
  height: 112,
);
final Rect _bodyRect = Rect.fromCenter(
  center: const Offset(120, 164),
  width: 104,
  height: 84,
);

/// Rect of the head (used by the face painter).
Rect get kittyHeadRect => _headRect;

/// Curly striped tail, rotated around its base by [KittyPose.tailAngle].
void paintTail(Canvas canvas, KittyPose pose, KittyLayer layer) {
  const base = Offset(150, 190);
  // A frightened cat's tail fur stands up, which reads as a fatter tail.
  final puff = 10 * pose.tailPuff;
  final path = Path()
    ..moveTo(base.dx, base.dy)
    ..cubicTo(200, 196, 224, 156, 210, 122)
    ..cubicTo(202, 104, 180, 108, 186, 124);
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(-pose.tailAngle)
    ..translate(-base.dx, -base.dy);
  if (layer == KittyLayer.neon) {
    canvas
      ..drawPath(path, Glow.haloStroke(KittyColors.neon, 30 + puff, sigma: 7))
      ..drawPath(path, Glow.stroke(KittyColors.neon, 22 + puff));
  } else {
    canvas.drawPath(path, Glow.stroke(KittyColors.fur, 16 + puff));
    _tailStripes(canvas, path, 12 + puff * 0.6);
  }
  canvas.restore();
}

void _tailStripes(Canvas canvas, Path path, double width) {
  final stripe = Paint()
    ..color = KittyColors.stripe.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
  for (final metric in path.computeMetrics()) {
    for (var d = 24.0; d < metric.length - 6; d += 16) {
      canvas.drawPath(metric.extractPath(d, d + 5), stripe);
    }
  }
}

/// Round sitting body with a white belly and two haunches.
void paintBody(Canvas canvas, KittyLayer layer) {
  drawFurOval(canvas, _bodyRect, layer);
  for (final x in const [92.0, 148.0]) {
    drawFurOval(
      canvas,
      Rect.fromCenter(center: Offset(x, 196), width: 40, height: 24),
      layer,
      fill: KittyColors.belly,
    );
  }
  if (layer == KittyLayer.fill) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 170), width: 56, height: 54),
      Paint()..color = const Color(0xD9FFFFFF),
    );
  }
}

/// Two little front paws with toe lines; lifted during the walk cycle.
void paintPaws(Canvas canvas, KittyPose pose, KittyLayer layer) {
  _paw(canvas, Offset(106, 202 - pose.leftPawLift), layer);
  _paw(canvas, Offset(134, 202 - pose.rightPawLift), layer);
}

void _paw(Canvas canvas, Offset center, KittyLayer layer) {
  drawFurOval(
    canvas,
    Rect.fromCenter(center: center, width: 26, height: 16),
    layer,
    fill: KittyColors.belly,
  );
  if (layer == KittyLayer.neon) return;
  final toe = Glow.stroke(KittyColors.stripe, 2);
  canvas
    ..drawLine(center.translate(-4, 1), center.translate(-4, 6), toe)
    ..drawLine(center.translate(4, 1), center.translate(4, 6), toe);
}
