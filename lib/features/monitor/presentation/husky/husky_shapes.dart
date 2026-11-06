// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../../app/theme/glow.dart';
import '../kitty/kitty_body.dart' show KittyLayer;
import '../kitty/kitty_mood.dart';
import '../kitty/kitty_pose.dart';

const _fur = Color(0xFF9B98B7);
const _furLight = Color(0xFFE9E8F5);
const _white = Color(0xFFFFF9FF);
const _ink = Color(0xFF24183F);
const _cyan = Color(0xFF57F7FC);
const _pink = Color(0xFFFF8DC3);
const _blue = Color(0xFF168EE6);
const _green = Color(0xFF1AAE8B);

void _shape(Canvas canvas, Path path, KittyLayer layer, Color color) {
  if (layer == KittyLayer.neon) {
    canvas
      ..drawPath(path, Glow.haloStroke(_cyan, 14, sigma: 7))
      ..drawPath(path, Glow.stroke(_cyan, 6));
  } else {
    canvas.drawPath(path, Paint()..color = color);
  }
}

Path _oval(Rect rect) => Path()..addOval(rect);

/// Fluffy curved tail behind Flocke's body.
void paintHuskyTail(Canvas canvas, KittyPose pose, KittyLayer layer) {
  canvas
    ..save()
    ..translate(155, 185)
    ..rotate(-pose.tailAngle * 0.55)
    ..translate(-155, -185);
  final tail = Path()
    ..moveTo(156, 185)
    ..cubicTo(203, 213, 231, 179, 212, 145)
    ..cubicTo(205, 130, 192, 126, 184, 136)
    ..cubicTo(207, 141, 205, 166, 190, 168)
    ..cubicTo(181, 170, 170, 165, 160, 162)
    ..close();
  _shape(canvas, tail, layer, _fur);
  if (layer == KittyLayer.fill) {
    final tip = Path()
      ..moveTo(184, 136)
      ..cubicTo(200, 127, 209, 132, 215, 148)
      ..lineTo(202, 153)
      ..cubicTo(199, 143, 192, 139, 184, 136)
      ..close();
    canvas.drawPath(tip, Paint()..color = _white);
  }
  canvas.restore();
}

/// Rounded husky body, fluffy white chest and animated paws.
void paintHuskyBody(Canvas canvas, KittyPose pose, KittyLayer layer) {
  final body = _oval(const Rect.fromLTWH(68, 124, 104, 82));
  _shape(canvas, body, layer, _fur);
  if (layer == KittyLayer.fill) {
    final chest = Path()
      ..moveTo(91, 143)
      ..quadraticBezierTo(120, 153, 149, 143)
      ..lineTo(144, 180)
      ..lineTo(137, 173)
      ..lineTo(129, 188)
      ..lineTo(120, 180)
      ..lineTo(111, 188)
      ..lineTo(103, 173)
      ..lineTo(96, 180)
      ..close();
    canvas.drawPath(chest, Paint()..color = _white);
  }
  for (final (x, lift) in [
    (92.0, pose.leftPawLift),
    (148.0, pose.rightPawLift),
  ]) {
    final paw = _oval(
      Rect.fromCenter(center: Offset(x, 198 - lift), width: 33, height: 19),
    );
    _shape(canvas, paw, layer, _furLight);
  }
}

/// Husky head with erect ears, white face mask and a fluffy forehead.
void paintHuskyHead(Canvas canvas, KittyPose pose, KittyLayer layer) {
  for (final side in [-1.0, 1.0]) {
    canvas
      ..save()
      ..translate(120, 0)
      ..scale(side, 1);
    final droop = pose.earDroop * 8;
    final ear = Path()
      ..moveTo(30, 62)
      ..quadraticBezierTo(35 + droop, 17 + droop, 49, 24 + droop)
      ..quadraticBezierTo(72, 32 + droop, 73, 72)
      ..close();
    _shape(canvas, ear, layer, _fur);
    if (layer == KittyLayer.fill) {
      final inside = Path()
        ..moveTo(43, 56)
        ..quadraticBezierTo(47, 35 + droop, 51, 35 + droop)
        ..quadraticBezierTo(62, 39 + droop, 65, 59)
        ..close();
      canvas.drawPath(inside, Paint()..color = _pink);
    }
    canvas.restore();
  }
  final head = _oval(const Rect.fromLTWH(46, 38, 148, 108));
  _shape(canvas, head, layer, _fur);
  if (layer == KittyLayer.fill) _paintMask(canvas);
}

void _paintMask(Canvas canvas) {
  final mask = Path()
    ..moveTo(48, 100)
    ..cubicTo(54, 87, 66, 85, 76, 75)
    ..cubicTo(93, 58, 105, 63, 120, 81)
    ..cubicTo(135, 63, 147, 58, 164, 75)
    ..cubicTo(174, 85, 186, 87, 192, 100)
    ..cubicTo(187, 132, 164, 146, 120, 146)
    ..cubicTo(76, 146, 53, 132, 48, 100)
    ..close();
  canvas.drawPath(mask, Paint()..color = _white);
  for (final x in [110.0, 120.0, 130.0]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, x == 120 ? 50 : 54),
        width: 6,
        height: 10,
      ),
      Paint()..color = _furLight,
    );
  }
}

/// Flocke's face; her left eye is blue and right eye is green.
void paintHuskyFace(Canvas canvas, KittyMood mood, KittyPose pose) {
  final awakeMood = pose.wake != null ? KittyMood.idle : mood;
  for (final (center, color) in [
    (const Offset(88, 96), _blue),
    (const Offset(152, 96), _green),
  ]) {
    _eye(canvas, center, color, awakeMood, pose);
  }
  if (awakeMood == KittyMood.uneasy || awakeMood == KittyMood.scared) {
    final pen = Glow.stroke(_ink, 3);
    canvas
      ..drawLine(const Offset(75, 76), const Offset(99, 70), pen)
      ..drawLine(const Offset(165, 76), const Offset(141, 70), pen);
  }
  _muzzle(canvas, awakeMood, pose.yawn);
}

void _eye(
  Canvas canvas,
  Offset center,
  Color iris,
  KittyMood mood,
  KittyPose pose,
) {
  if (mood == KittyMood.sleeping || pose.eyeOpen < 0.12) {
    final lid = Path()
      ..moveTo(center.dx - 11, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 9, center.dx + 11, center.dy);
    canvas.drawPath(lid, Glow.stroke(_ink, 4));
    return;
  }
  final openness = pose.eyeOpen.clamp(0.12, 1.0);
  final eye = Rect.fromCenter(center: center, width: 27, height: 31 * openness);
  canvas
    ..drawOval(eye, Paint()..color = _ink)
    ..save()
    ..clipPath(Path()..addOval(eye.deflate(2)))
    ..translate(pose.lookDx, 0)
    ..drawOval(eye.deflate(4), Paint()..color = iris);
  if (openness >= 0.4) {
    canvas
      ..drawCircle(
        center.translate(4, -5 * openness),
        4.5,
        Paint()..color = _white,
      )
      ..drawCircle(
        center.translate(-4, 5 * openness),
        2,
        Paint()..color = _white,
      );
  }
  canvas.restore();
}

void _muzzle(Canvas canvas, KittyMood mood, double yawn) {
  canvas
    ..drawOval(const Rect.fromLTWH(95, 108, 50, 28), Paint()..color = _furLight)
    ..drawOval(const Rect.fromLTWH(112, 110, 16, 10), Paint()..color = _ink);
  final mouth = Path()..moveTo(120, 119);
  if (mood == KittyMood.scared || yawn > 0.05) {
    canvas.drawOval(
      const Rect.fromLTWH(114, 122, 12, 13),
      Paint()..color = _ink,
    );
    return;
  }
  final smile = mood == KittyMood.uneasy ? -2.0 : 5.0;
  mouth
    ..quadraticBezierTo(114, 128 + smile, 107, 121)
    ..moveTo(120, 119)
    ..quadraticBezierTo(126, 128 + smile, 133, 121);
  canvas.drawPath(mouth, Glow.stroke(_ink, 3));
  if (mood == KittyMood.happy) {
    canvas.drawCircle(const Offset(120, 132), 4, Paint()..color = _pink);
  }
}
