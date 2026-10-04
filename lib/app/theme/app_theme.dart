// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Minimum interactive size (Material/Android accessibility guideline).
const double kMinTouchTarget = 48;

/// Builds the Material 3 dark theme of Raumfreund.
///
/// Uses the platform default font (no font assets) with rounded, friendly
/// weights; all interactive elements keep at least [kMinTouchTarget].
ThemeData buildAppTheme() {
  final scheme = _colorScheme();
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: 0.82),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: _filledStyle(scheme)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _outlinedStyle()),
    textButtonTheme: TextButtonThemeData(style: _textStyle()),
    sliderTheme: _sliderTheme(),
    switchTheme: _switchTheme(),
  );
}

ColorScheme _colorScheme() => const ColorScheme.dark(
  primary: AppColors.green,
  onPrimary: AppColors.onNeon,
  secondary: AppColors.yellow,
  onSecondary: AppColors.onNeon,
  tertiary: AppColors.lavender,
  onTertiary: AppColors.onNeon,
  error: AppColors.red,
  onError: AppColors.onNeon,
  surface: AppColors.surface,
  onSurface: AppColors.text,
  onSurfaceVariant: AppColors.textMuted,
  surfaceContainerHighest: AppColors.surfaceHigh,
  outline: AppColors.textMuted,
);

TextTheme _textTheme(TextTheme base) => base
    .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
    .copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.text,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textMuted),
    );

const Size _minButtonSize = Size(kMinTouchTarget, kMinTouchTarget + 8);
const OutlinedBorder _pill = StadiumBorder();
const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 12,
);

ButtonStyle _filledStyle(ColorScheme scheme) => FilledButton.styleFrom(
  backgroundColor: scheme.primary,
  foregroundColor: scheme.onPrimary,
  minimumSize: _minButtonSize,
  padding: _buttonPadding,
  shape: _pill,
  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
);

ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: AppColors.text,
  side: const BorderSide(color: AppColors.textMuted, width: 1.5),
  minimumSize: _minButtonSize,
  padding: _buttonPadding,
  shape: _pill,
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
);

ButtonStyle _textStyle() => TextButton.styleFrom(
  foregroundColor: AppColors.lavender,
  minimumSize: _minButtonSize,
  padding: _buttonPadding,
  shape: _pill,
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
);

SliderThemeData _sliderTheme() => const SliderThemeData(
  trackHeight: 8,
  inactiveTrackColor: AppColors.surfaceHigh,
  overlayShape: RoundSliderOverlayShape(),
  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
);

SwitchThemeData _switchTheme() => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? AppColors.onNeon
        : AppColors.textMuted,
  ),
  trackColor: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.selected)
        ? AppColors.green
        : AppColors.surfaceHigh,
  ),
);
