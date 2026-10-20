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

/// One small whimper tear per eye plus little fright marks above the ears.
///
/// Deliberately less than the former sobbing: Mia is frightened, not sad.
void paintWhimper(Canvas canvas, double phase) {
  for (final eye in const [kLeftEye, kRightEye]) {
    final side = eye.dx < 120 ? -1.0 : 1.0;
    final p = (phase * 2 + (side < 0 ? 0 : 0.5)) % 1;
    final pos = eye.translate(side * (14 + p * 6), 14 + p * 40);
    _drop(canvas, pos, 4.5, AppColors.tear.withValues(alpha: 1 - p * 0.8));
  }
  _frightMarks(canvas, phase);
}

/// Short comic-style strokes that flicker above both ears.
void _frightMarks(Canvas canvas, double phase) {
  final flicker = 0.55 + 0.45 * math.sin(phase * 16 * math.pi).abs();
  final paint = Glow.stroke(AppColors.red.withValues(alpha: flicker), 3);
  const marks = [
    (Offset(38, 30), Offset(30, 20)),
    (Offset(30, 42), Offset(18, 38)),
    (Offset(28, 54), Offset(16, 56)),
  ];
  for (final (a, b) in marks) {
    canvas
      ..drawLine(a, b, paint)
      ..drawLine(Offset(240 - a.dx, a.dy), Offset(240 - b.dx, b.dy), paint);
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

const Color _dreamLilac = Color(0xFFD9CCFF);

/// Three "Z" that drift up and to the right of the sleeping head, growing
/// and fading; [opacity] fades them out while she wakes up.
void paintZzz(Canvas canvas, double phase, {double opacity = 1}) {
  for (var i = 0; i < 3; i++) {
    final p = (phase + i / 3) % 1;
    final size = 8 + 10 * p;
    // Right of the head and above the tail, where nothing covers them.
    final center = Offset(
      206 + 20 * p + 3 * math.sin(p * 2 * math.pi),
      92 - 62 * p,
    );
    final alpha = math.sin(p * math.pi).clamp(0.0, 1.0) * opacity;
    if (alpha <= 0) continue;
    _z(canvas, center, size, _dreamLilac.withValues(alpha: alpha));
  }
}

void _z(Canvas canvas, Offset c, double size, Color color) {
  final h = size / 2;
  final path = Path()
    ..moveTo(c.dx - h, c.dy - h)
    ..lineTo(c.dx + h, c.dy - h)
    ..lineTo(c.dx - h, c.dy + h)
    ..lineTo(c.dx + h, c.dy + h);
  canvas
    ..drawPath(path, Glow.haloStroke(color, 5, sigma: 3))
    ..drawPath(path, Glow.stroke(color, 2.6));
}

/// Sleepy nose bubble that swells and shrinks with each breath.
void paintNoseBubble(Canvas canvas, double phase) {
  final breath = (math.sin(phase * 2 * math.pi) + 1) / 2;
  final radius = 3 + 6 * breath;
  final center = Offset(129 + radius * 0.6, 117 + radius * 0.3);
  canvas
    ..drawCircle(
      center,
      radius,
      Paint()..color = AppColors.tear.withValues(alpha: 0.28),
    )
    ..drawCircle(
      center,
      radius,
      Glow.stroke(AppColors.tear.withValues(alpha: 0.75), 1.4),
    )
    ..drawCircle(
      center.translate(-radius * 0.35, -radius * 0.35),
      math.max(1, radius * 0.22),
      Paint()..color = const Color(0xCCFFFFFF),
    );
}

/// Little twinkling stars around the head at the end of waking up [wake].
void paintWakeSparkles(Canvas canvas, double wake) {
  final t = ((wake - 0.65) / 0.35).clamp(0.0, 1.0);
  final alpha = math.sin(t * math.pi);
  if (alpha <= 0) return;
  const spots = [
    (Offset(46, 40), 7.0),
    (Offset(196, 34), 9.0),
    (Offset(206, 92), 6.0),
  ];
  for (final (center, radius) in spots) {
    _sparkle(
      canvas,
      center,
      radius * (0.6 + 0.4 * t),
      AppColors.star.withValues(alpha: alpha),
    );
  }
}

void _sparkle(Canvas canvas, Offset c, double r, Color color) {
  final w = r * 0.28;
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
    ..close();
  canvas
    ..drawPath(path, Glow.halo(color, sigma: 4, alpha: color.a * 0.6))
    ..drawPath(path, Paint()..color = color);
}
