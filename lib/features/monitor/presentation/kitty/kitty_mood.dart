// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Mood of Mia the kitty.
enum KittyMood {
  /// Not measuring: sits calmly and blinks slowly.
  idle,

  /// Green zone: smiles, purrs and sways her tail.
  happy,

  /// Yellow zone: flat ears, worried brows and a sweat drop.
  uneasy,

  /// Red zone: frightened by the noise – wide eyes, flat ears, trembling,
  /// puffed tail and a few whimper tears.
  scared;

  /// Glow colour that surrounds Mia in this mood.
  Color get glowColor => switch (this) {
    KittyMood.idle => AppColors.lavender,
    KittyMood.happy => AppColors.green,
    KittyMood.uneasy => AppColors.yellow,
    KittyMood.scared => AppColors.red,
  };

  /// Screen-reader description of the mood.
  String describe(AppLocalizations l10n) => switch (this) {
    KittyMood.idle => l10n.kittyIdle,
    KittyMood.happy => l10n.kittyHappy,
    KittyMood.uneasy => l10n.kittyUneasy,
    KittyMood.scared => l10n.kittyScared,
  };
}
