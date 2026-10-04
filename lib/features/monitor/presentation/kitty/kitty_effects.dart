// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;
import 'dart:ui';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/glow.dart';
import 'kitty_body.dart';
import 'kitty_face.dart';

const Color _heartPink = Color(0xFFFF7AB8);

/// Floating hearts and a music note ("purr") above Mia's head.
void paintPurr(Canvas canvas, double phase) {
  for (var i = 0; i < 3; i++) {
    final p = (phase + i / 3) % 1;
    final center = Offset(
      186 + i * 10 + 6 * math.sin(p * 2 * math.pi + i),
      74 - p * 58,
    );
    final alpha = math.sin(p * math.pi).clamp(0.0, 1.0);
    if (i == 1) {
      _note(canvas, center, AppColors.green.withValues(alpha: alpha));
    } else {
      _heart(canvas, center, 8 + i * 1.5, _heartPink.withValues(alpha: alpha));
    }
  }
}

void _heart(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx, c.dy + r)
    ..cubicTo(c.dx - r * 1.6, c.dy, c.dx - r, c.dy - r, c.dx, c.dy - r * 0.35)
    ..cubicTo(c.dx + r, c.dy - r, c.dx + r * 1.6, c.dy, c.dx, c.dy + r)
    ..close();
  canvas
    ..drawPath(path, Glow.halo(color, sigma: 4, alpha: color.a * 0.6))
    ..drawPath(path, Paint()..color = color);
}

void _note(Canvas canvas, Offset c, Color color) {
  canvas
    ..drawPath(
      Path()..addOval(Rect.fromCenter(center: c, width: 10, height: 8)),
      Glow.halo(color, sigma: 4, alpha: color.a * 0.6),
    )
    ..drawOval(
      Rect.fromCenter(center: c, width: 10, height: 8),
      Paint()..color = color,
    )
    ..drawLine(
      c.translate(4.5, 0),
      c.translate(4.5, -16),
      Glow.stroke(color, 2.4),
    )
    ..drawLine(
      c.translate(4.5, -16),
      c.translate(10, -11),
      Glow.stroke(color, 2.4),
    );
}

/// A worried sweat drop next to the right ear.
void paintSweat(Canvas canvas, double phase) {
  final dy = 2 * math.sin(phase * 2 * math.pi);
  _drop(canvas, Offset(178, 58 + dy), 7, AppColors.tear);
}

/// Tear streams and falling tear drops below both eyes.
void paintTears(Canvas canvas, double phase) {
  final stream = Glow.stroke(AppColors.tear.withValues(alpha: 0.75), 6);
  for (final eye in const [kLeftEye, kRightEye]) {
    final side = eye.dx < 120 ? -1.0 : 1.0;
    final start = eye.translate(side * 6, 10);
    canvas.drawLine(start, start.translate(side * 5, 30), stream);
    for (var k = 0; k < 2; k++) {
      final p = (phase * 2 + k / 2) % 1;
      final pos = start.translate(side * (6 + p * 14), 32 + p * 52);
      _drop(canvas, pos, 5.5, AppColors.tear.withValues(alpha: 1 - p * 0.8));
    }
  }
}

void _drop(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r * 2)
    ..quadraticBezierTo(c.dx + r * 1.3, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - r * 1.3, c.dy, c.dx, c.dy - r * 2)
    ..close();
  canvas
    ..drawPath(path, Glow.halo(color, sigma: 3, alpha: color.a * 0.6))
    ..drawPath(path, Paint()..color = color);
}

/// Paw prints from the stage centre to Mia's current position [walkDx].
///
/// Older prints (further behind her) fade out.
void paintPawPrints(Canvas canvas, double walkDx) {
  const spacing = 26.0;
  const fadeDistance = 220.0;
  for (var x = 150.0, i = 0; x < 120 + walkDx; x += spacing, i++) {
    final behind = 120 + walkDx - x;
    final alpha = (1 - behind / fadeDistance).clamp(0.0, 1.0) * 0.7;
    if (alpha <= 0) continue;
    _pawPrint(canvas, Offset(x, i.isEven ? 208 : 214), alpha);
  }
}

void _pawPrint(Canvas canvas, Offset c, double alpha) {
  final paint = Paint()..color = KittyColors.fur.withValues(alpha: alpha);
  canvas.drawOval(Rect.fromCenter(center: c, width: 9, height: 7), paint);
  for (final dx in const [-4.5, 0.0, 4.5]) {
    canvas.drawCircle(c.translate(dx, dx == 0 ? -6.5 : -5), 2.1, paint);
  }
}
