// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/glow.dart';
import 'kitty_body.dart';
import 'kitty_mood.dart';
import 'kitty_pose.dart';

/// Left eye centre in design units (the right eye is mirrored at x = 120).
const Offset kLeftEye = Offset(91, 98);

/// Right eye centre in design units.
const Offset kRightEye = Offset(149, 98);

const double _eyeRadius = 16;

const Color _shine = Color(0xCCFFFFFF);

Offset _mirror(Offset p) => Offset(240 - p.dx, p.dy);

/// Ears (upright or flattened by [KittyPose.earDroop]) and the head.
void paintHead(Canvas canvas, KittyPose pose, KittyLayer layer) {
  _ear(canvas, pose.earDroop, layer, mirrored: false);
  _ear(canvas, pose.earDroop, layer, mirrored: true);
  drawFurOval(canvas, kittyHeadRect, layer);
  if (layer == KittyLayer.neon) return;
  final stripe = Glow.stroke(KittyColors.stripe, 5);
  canvas
    ..drawLine(const Offset(120, 42), const Offset(120, 54), stripe)
    ..drawLine(const Offset(106, 45), const Offset(109, 55), stripe)
    ..drawLine(const Offset(134, 45), const Offset(131, 55), stripe);
}

void _ear(
  Canvas canvas,
  double droop,
  KittyLayer layer, {
  required bool mirrored,
}) {
  Offset m(Offset p) => mirrored ? _mirror(p) : p;
  final tip = Offset.lerp(const Offset(62, 16), const Offset(26, 62), droop)!;
  final outerBase = Offset.lerp(
    const Offset(62, 72),
    const Offset(66, 80),
    droop,
  )!;
  const innerBase = Offset(102, 46);
  final outer = Path()..addPolygon([m(outerBase), m(tip), m(innerBase)], true);
  final centroid = (outerBase + tip + innerBase) / 3;
  final inner = Path()
    ..addPolygon([
      for (final p in [outerBase, tip, innerBase])
        m(Offset.lerp(centroid, p, 0.55)!),
    ], true);
  drawFurPath(canvas, outer, layer);
  if (layer == KittyLayer.neon) return;
  // A fur-coloured round-joined stroke gives the ears soft, rounded tips.
  canvas
    ..drawPath(outer, Glow.stroke(KittyColors.fur, 8))
    ..drawPath(inner, Glow.stroke(KittyColors.innerEar, 4))
    ..drawPath(inner, Paint()..color = KittyColors.innerEar);
}

/// Blush, eyes, brows, nose, mouth and whiskers for [mood].
void paintFace(Canvas canvas, KittyMood mood, KittyPose pose) {
  _cheeks(canvas, mood);
  _whiskers(canvas);
  switch (mood) {
    case KittyMood.happy:
      _happyEye(canvas, kLeftEye);
      _happyEye(canvas, kRightEye);
    case KittyMood.crying:
      _squeezedEye(canvas, kLeftEye, mirrored: false);
      _squeezedEye(canvas, kRightEye, mirrored: true);
      _brows(canvas);
    case KittyMood.idle || KittyMood.uneasy:
      _openEye(canvas, kLeftEye, pose);
      _openEye(canvas, kRightEye, pose);
      if (mood == KittyMood.uneasy) _brows(canvas);
  }
  _nose(canvas);
  paintMouth(canvas, mood);
}

void _cheeks(Canvas canvas, KittyMood mood) {
  final alpha = switch (mood) {
    KittyMood.happy => 0.7,
    KittyMood.idle => 0.45,
    KittyMood.uneasy => 0.25,
    KittyMood.crying => 0.6,
  };
  final paint = Paint()
    ..color = KittyColors.blush.withValues(alpha: alpha)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  for (final c in const [Offset(76, 120), Offset(164, 120)]) {
    canvas.drawOval(Rect.fromCenter(center: c, width: 24, height: 13), paint);
  }
}

void _whiskers(Canvas canvas) {
  final paint = Glow.stroke(const Color(0xE6FFFFFF), 1.8);
  const lines = [
    (Offset(62, 110), Offset(20, 102)),
    (Offset(62, 117), Offset(18, 120)),
    (Offset(64, 124), Offset(24, 136)),
  ];
  for (final (a, b) in lines) {
    canvas
      ..drawLine(a, b, paint)
      ..drawLine(_mirror(a), _mirror(b), paint);
  }
}

void _openEye(Canvas canvas, Offset center, KittyPose pose) {
  final open = pose.eyeOpen.clamp(0.08, 1.0);
  final rect = Rect.fromCenter(
    center: center,
    width: _eyeRadius * 2,
    height: _eyeRadius * 2.2 * open,
  );
  final iris = Paint()
    ..shader = Gradient.linear(
      rect.topCenter,
      rect.bottomCenter,
      [KittyColors.ink, KittyColors.ink, KittyColors.iris],
      const [0, 0.55, 1],
    );
  canvas.drawOval(rect, iris);
  if (open < 0.4) return;
  final look = Offset(pose.lookDx, 0);
  final white = Paint()..color = const Color(0xFFFFFFFF);
  canvas
    ..drawCircle(center + look + Offset(5, -7 * open), 5.5, white)
    ..drawCircle(center + look + Offset(-5, 6 * open), 2.6, white);
}

void _happyEye(Canvas canvas, Offset c) {
  final path = Path()
    ..moveTo(c.dx - 13, c.dy + 4)
    ..quadraticBezierTo(c.dx, c.dy - 16, c.dx + 13, c.dy + 4);
  canvas.drawPath(path, Glow.stroke(KittyColors.ink, 5));
}

void _squeezedEye(Canvas canvas, Offset c, {required bool mirrored}) {
  final d = mirrored ? -1.0 : 1.0;
  final path = Path()
    ..moveTo(c.dx - 10 * d, c.dy - 9)
    ..lineTo(c.dx + 9 * d, c.dy)
    ..lineTo(c.dx - 10 * d, c.dy + 9);
  canvas.drawPath(path, Glow.stroke(KittyColors.ink, 5));
}

void _brows(Canvas canvas) {
  final paint = Glow.stroke(KittyColors.ink, 4);
  // Worried brows: the inner ends are higher than the outer ends.
  canvas
    ..drawLine(const Offset(76, 76), const Offset(102, 68), paint)
    ..drawLine(const Offset(164, 76), const Offset(138, 68), paint);
}

void _nose(Canvas canvas) {
  final path = Path()
    ..moveTo(113, 114)
    ..quadraticBezierTo(120, 110, 127, 114)
    ..quadraticBezierTo(124, 120, 120, 121)
    ..quadraticBezierTo(116, 120, 113, 114)
    ..close();
  canvas
    ..drawPath(path, Paint()..color = KittyColors.nose)
    ..drawCircle(const Offset(118, 114), 1.6, Paint()..color = _shine);
}

/// Mouth shape per mood: "ω" with tongue, wavy line or wailing mouth.
void paintMouth(Canvas canvas, KittyMood mood) {
  final line = Glow.stroke(KittyColors.ink, 3);
  if (mood == KittyMood.uneasy) {
    final wave = Path()..moveTo(106, 130);
    for (var x = 106.0; x <= 134; x += 1) {
      wave.lineTo(x, 130 + 2.5 * math.sin((x - 106) / 14 * 2 * math.pi));
    }
    canvas.drawPath(wave, line);
    return;
  }
  if (mood == KittyMood.crying) {
    final mouth = Rect.fromCenter(
      center: const Offset(120, 133),
      width: 24,
      height: 20,
    );
    canvas
      ..drawOval(mouth, Paint()..color = KittyColors.mouth)
      ..drawOval(
        Rect.fromCenter(center: const Offset(120, 139), width: 14, height: 7),
        Paint()..color = KittyColors.tongue,
      )
      ..drawOval(mouth, line);
    return;
  }
  if (mood == KittyMood.happy) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 129), width: 11, height: 9),
      Paint()..color = KittyColors.tongue,
    );
  }
  final omega = Path()
    ..moveTo(108, 122)
    ..quadraticBezierTo(113, 129, 120, 122)
    ..quadraticBezierTo(127, 129, 132, 122);
  canvas.drawPath(omega, line);
}
