// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/painting.dart';

/// Helpers for the soft neon glow used across the UI.
abstract final class Glow {
  /// Box shadows that make a widget of [color] glow.
  ///
  /// [strength] scales opacity and blur radius (1 = default).
  static List<BoxShadow> shadows(Color color, {double strength = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.55 * strength.clamp(0, 1)),
      blurRadius: 18 * strength,
      spreadRadius: 1 * strength,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.25 * strength.clamp(0, 1)),
      blurRadius: 42 * strength,
      spreadRadius: 4 * strength,
    ),
  ];

  /// A paint that draws a blurred halo of [color] (for CustomPainters).
  static Paint halo(Color color, {double sigma = 8, double alpha = 0.7}) =>
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  /// A stroke paint with a blurred halo, drawn below a crisp stroke.
  static Paint haloStroke(Color color, double width, {double sigma = 6}) =>
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  /// A crisp round stroke paint.
  static Paint stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
