// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/glow.dart';

/// Rounded translucent panel with a thin neon border and a soft glow.
class GlowPanel extends StatelessWidget {
  /// Creates a panel around [child].
  const GlowPanel({
    required this.child,
    this.color = AppColors.lavender,
    this.glowStrength = 0.35,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  /// Content of the panel.
  final Widget child;

  /// Border and glow colour.
  final Color color;

  /// Glow intensity (0 = none, 1 = strong).
  final double glowStrength;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      boxShadow: glowStrength > 0
          ? Glow.shadows(color, strength: glowStrength)
          : null,
    ),
    child: Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}
