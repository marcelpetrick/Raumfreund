// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_colors.dart';
import 'package:raumfreund/app/theme/app_theme.dart';
import 'package:raumfreund/app/theme/glow.dart';
import 'package:raumfreund/app/theme/zone_palette.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

import '../../shared/widgets/test_app.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('buildAppTheme', () {
    final theme = buildAppTheme();

    test('is a dark Material 3 theme with neon primary', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.green);
      expect(theme.colorScheme.error, AppColors.red);
    });

    test('keeps buttons at least 48 dp tall', () {
      final size = theme.filledButtonTheme.style!.minimumSize!.resolve({});
      expect(size!.height, greaterThanOrEqualTo(kMinTouchTarget));
      final outlined = theme.outlinedButtonTheme.style!.minimumSize!.resolve(
        {},
      );
      expect(outlined!.height, greaterThanOrEqualTo(kMinTouchTarget));
      final text = theme.textButtonTheme.style!.minimumSize!.resolve({});
      expect(text!.height, greaterThanOrEqualTo(kMinTouchTarget));
    });

    test('switch colours depend on the selected state', () {
      final thumb = theme.switchTheme.thumbColor!;
      final track = theme.switchTheme.trackColor!;
      expect(thumb.resolve({WidgetState.selected}), AppColors.onNeon);
      expect(thumb.resolve({}), AppColors.textMuted);
      expect(track.resolve({WidgetState.selected}), AppColors.green);
      expect(track.resolve({}), AppColors.surfaceHigh);
    });
  });

  group('contrast (WCAG AA >= 4.5)', () {
    for (final background in [
      AppColors.skyTop,
      AppColors.skyMiddle,
      AppColors.skyBottom,
      AppColors.surface,
    ]) {
      test('text on $background', () {
        expect(_contrast(AppColors.text, background), greaterThan(4.5));
        expect(_contrast(AppColors.textMuted, background), greaterThan(4.5));
      });
    }
    for (final neon in [AppColors.green, AppColors.yellow, AppColors.red]) {
      test('onNeon on $neon', () {
        expect(_contrast(AppColors.onNeon, neon), greaterThan(4.5));
      });
    }
  });

  group('ZonePalette', () {
    test('maps every zone to colour, icon and German label', () {
      expect(ZonePalette.of(Zone.green).color, AppColors.green);
      expect(ZonePalette.of(Zone.yellow).color, AppColors.yellow);
      expect(ZonePalette.of(Zone.red).color, AppColors.red);
      expect(ZonePalette.of(Zone.green).label(l10nDe), l10nDe.zoneGreen);
      expect(ZonePalette.of(Zone.yellow).label(l10nDe), l10nDe.zoneYellow);
      expect(ZonePalette.of(Zone.red).label(l10nDe), l10nDe.zoneRed);
      final icons = Zone.values.map((z) => ZonePalette.of(z).icon).toSet();
      expect(icons, hasLength(3));
    });

    test('colorOf falls back to lavender without a zone', () {
      expect(ZonePalette.colorOf(null), AppColors.lavender);
      expect(ZonePalette.colorOf(Zone.red), AppColors.red);
    });
  });

  test('Glow helpers produce blurred paints and shadows', () {
    expect(Glow.shadows(AppColors.green), hasLength(2));
    expect(Glow.halo(AppColors.red).maskFilter, isNotNull);
    expect(Glow.haloStroke(AppColors.red, 4).strokeWidth, 4);
    expect(Glow.stroke(AppColors.red, 3).style, PaintingStyle.stroke);
  });
}
