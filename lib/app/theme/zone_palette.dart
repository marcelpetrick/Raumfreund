// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../features/monitor/domain/zone.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_colors.dart';

/// Visual identity of one [Zone]: colour, icon and label.
///
/// Colour never carries information alone (vision §3): every place that uses
/// [color] also shows [icon] and/or [label].
final class ZoneStyle {
  /// Creates a style.
  const ZoneStyle({
    required this.zone,
    required this.color,
    required this.icon,
  });

  /// The zone this style belongs to.
  final Zone zone;

  /// Neon colour of the zone.
  final Color color;

  /// Icon shown next to the colour.
  final IconData icon;

  /// Localized label of the zone.
  String label(AppLocalizations l10n) => switch (zone) {
    Zone.green => l10n.zoneGreen,
    Zone.yellow => l10n.zoneYellow,
    Zone.red => l10n.zoneRed,
  };
}

/// Central mapping from [Zone] to [ZoneStyle].
abstract final class ZonePalette {
  static const ZoneStyle _green = ZoneStyle(
    zone: Zone.green,
    color: AppColors.green,
    icon: Icons.sentiment_very_satisfied_rounded,
  );
  static const ZoneStyle _yellow = ZoneStyle(
    zone: Zone.yellow,
    color: AppColors.yellow,
    icon: Icons.sentiment_neutral_rounded,
  );
  static const ZoneStyle _red = ZoneStyle(
    zone: Zone.red,
    color: AppColors.red,
    icon: Icons.sentiment_very_dissatisfied_rounded,
  );

  /// Returns the style of [zone].
  static ZoneStyle of(Zone zone) => switch (zone) {
    Zone.green => _green,
    Zone.yellow => _yellow,
    Zone.red => _red,
  };

  /// Colour of [zone], or the neutral lavender when there is no zone.
  static Color colorOf(Zone? zone) =>
      zone == null ? AppColors.lavender : of(zone).color;
}
