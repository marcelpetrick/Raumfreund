// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_theme.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

/// German localizations for direct use in tests.
final AppLocalizations l10nDe = lookupAppLocalizations(const Locale('de'));

/// Wraps [child] in a themed, German-localized MaterialApp.
///
/// When [scaffold] is true, [child] is placed in a Scaffold body.
Widget testApp(
  Widget child, {
  bool scaffold = true,
  bool disableAnimations = false,
  double textScale = 1,
}) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('de'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: disableAnimations,
      textScaler: TextScaler.linear(textScale),
    ),
    child: app!,
  ),
  home: scaffold
      ? Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(child: child),
        )
      : child,
);

/// Pumps [child] in [testApp].
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  bool scaffold = true,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    testApp(child, scaffold: scaffold, disableAnimations: disableAnimations),
  );
  await tester.pump();
}

/// Sets the logical screen size for the current test and resets it later.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Returns [value] unchanged, but as a non-constant expression.
///
/// Widgets created only with `const` are canonicalized at compile time, and
/// their constructor lines then count as not hit on some CI machines. Tests
/// therefore build each class at least once through this helper.
T rt<T>(T value) => value;
