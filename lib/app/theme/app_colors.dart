// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/painting.dart';

/// The "poppy and glowing" night palette of Raumfreund.
///
/// Text colours were chosen for at least WCAG AA contrast (4.5:1) against
/// the darkest and the brightest part of the night-sky gradient.
abstract final class AppColors {
  /// Top of the night-sky gradient (deep indigo).
  static const Color skyTop = Color(0xFF120B2E);

  /// Middle of the night-sky gradient (violet).
  static const Color skyMiddle = Color(0xFF2B1055);

  /// Bottom of the night-sky gradient (deep teal).
  static const Color skyBottom = Color(0xFF0B3D5C);

  /// Card/panel surface (translucent violet, drawn over the sky).
  static const Color surface = Color(0xFF1E1442);

  /// Slightly brighter surface for raised elements.
  static const Color surfaceHigh = Color(0xFF2A1D5A);

  /// Background of the heartbeat monitor screen.
  static const Color monitorScreen = Color(0xFF080517);

  /// Primary text on the night sky (contrast > 14:1).
  static const Color text = Color(0xFFF7F3FF);

  /// Secondary text on the night sky (contrast > 7:1).
  static const Color textMuted = Color(0xFFC9BFEA);

  /// Dark text on neon fills (contrast > 10:1 on all zone colours).
  static const Color onNeon = Color(0xFF140A2E);

  /// Neon mint of the green zone.
  static const Color green = Color(0xFF3DFFA8);

  /// Neon sun of the yellow zone.
  static const Color yellow = Color(0xFFFFD23F);

  /// Neon pink-red of the red zone.
  static const Color red = Color(0xFFFF4D6D);

  /// Accent lavender used for neutral (idle) glows.
  static const Color lavender = Color(0xFFB79CFF);

  /// Soft sky blue (tears, sweat drops).
  static const Color tear = Color(0xFF7FD8FF);

  /// Star gold of the star counter.
  static const Color star = Color(0xFFFFE066);
}
