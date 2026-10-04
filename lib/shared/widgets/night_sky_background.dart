// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Deep night-sky gradient with a sprinkle of soft, static stars.
///
/// The stars are placed by a fixed-seed generator, so the background is
/// identical on every frame and in golden tests.
class NightSkyBackground extends StatelessWidget {
  /// Creates the background behind [child].
  const NightSkyBackground({required this.child, super.key});

  /// Content drawn above the sky.
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.skyTop, AppColors.skyMiddle, AppColors.skyBottom],
        stops: [0, 0.55, 1],
      ),
    ),
    child: CustomPaint(painter: const SkyStarsPainter(), child: child),
  );
}

/// Paints small glowing stars at deterministic positions.
class SkyStarsPainter extends CustomPainter {
  /// Creates the painter.
  const SkyStarsPainter({this.count = 42, this.seed = 7});

  /// Number of stars.
  final int count;

  /// Seed of the position generator.
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final dot = Paint();
    for (var i = 0; i < count; i++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.8,
      );
      final radius = 0.6 + random.nextDouble() * 1.4;
      final alpha = 0.25 + random.nextDouble() * 0.5;
      glow.color = AppColors.lavender.withValues(alpha: alpha * 0.6);
      dot.color = AppColors.text.withValues(alpha: alpha);
      canvas
        ..drawCircle(center, radius * 2.2, glow)
        ..drawCircle(center, radius, dot);
    }
  }

  @override
  bool shouldRepaint(SkyStarsPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.seed != seed;
}
