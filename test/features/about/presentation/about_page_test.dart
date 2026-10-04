// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';
import 'package:raumfreund/features/about/presentation/about_page.dart';

import '../../../shared/widgets/test_app.dart';

void main() {
  testWidgets('shows privacy, build and project information', (tester) async {
    await pumpTestApp(
      tester,
      const AboutPage(
        info: AppInfo(
          versionName: '1.2.3',
          buildNumber: 42,
          gitCommit: 'abc1234',
        ),
      ),
      scaffold: false,
    );
    expect(find.text(l10nDe.aboutTitle), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text(l10nDe.aboutBuildValue(42, 'abc1234')), findsOneWidget);
    expect(find.text('Marcel Petrick'), findsOneWidget);
    expect(find.text('github.com/marcelpetrick/Raumfreund'), findsOneWidget);
    expect(find.text(l10nDe.aboutPrivacyBody), findsOneWidget);
    expect(find.text(l10nDe.aboutMeasurementBody), findsOneWidget);
  });

  testWidgets('opens the Flutter licence page', (tester) async {
    await pumpTestApp(
      tester,
      const AboutPage(
        info: AppInfo(versionName: '1.0.0', buildNumber: 1, gitCommit: 'dev'),
      ),
      scaffold: false,
    );
    await tester.scrollUntilVisible(
      find.text(l10nDe.aboutLicensesButton),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10nDe.aboutLicensesButton));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Raumfreund'), findsWidgets);
    expect(find.text('1.0.0'), findsOneWidget);
  });
}
