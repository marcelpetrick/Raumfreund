// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/settings/application/language_controller.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

import '../fakes/in_memory_language_repository.dart';
import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../fakes/monitor_harness.dart';
import '../shared/widgets/test_app.dart';

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));
final AppLocalizations _hr = lookupAppLocalizations(const Locale('hr'));

/// The app with fakes and a language controller over [languages].
final class _App {
  _App([AppLanguage stored = AppLanguage.german])
    : languages = InMemoryLanguageRepository(stored);

  final InMemoryLanguageRepository languages;
  final InMemorySettingsRepository settings = InMemorySettingsRepository();

  Future<void> pump(WidgetTester tester) async {
    final language = LanguageController(languages);
    await language.load();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(settings),
        languageController: language,
        monitorController: MonitorHarness().controller,
        shopRepository: InMemoryShopRepository(),
        appInfoPort: const _AppInfo(),
      ),
    );
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await _settle(tester);
}

void main() {
  testWidgets('the stored language is used from the first frame', (
    tester,
  ) async {
    await _App(AppLanguage.english).pump(tester);
    expect(find.text(_en.measureStart), findsOneWidget);
    expect(find.byTooltip(_en.actionSettings), findsOneWidget);
  });

  testWidgets('picking a language switches the whole app and stores it', (
    tester,
  ) async {
    final app = _App();
    await app.pump(tester);
    await tester.tap(find.byTooltip(l10nDe.actionSettings));
    await _settle(tester);
    await _tapText(tester, l10nDe.languageEnglish);
    expect(find.text(_en.settingsTitle), findsOneWidget);
    expect(find.text(_en.settingsLanguageHeading), findsOneWidget);
    expect(app.languages.stored, AppLanguage.english);
    await tester.tap(find.byTooltip(_en.actionBack).hitTestable().first);
    await _settle(tester);
    expect(find.text(_en.measureStart), findsOneWidget);
  });

  testWidgets('an unsaved draft survives a language switch', (tester) async {
    final app = _App();
    await app.pump(tester);
    await tester.tap(find.byTooltip(l10nDe.actionSettings));
    await _settle(tester);
    final increase = l10nDe.settingsIncrease(l10nDe.settingsYellowLabel);
    await tester.tap(find.byTooltip(increase));
    await _settle(tester);
    await _tapText(tester, l10nDe.languageCroatian);
    await _tapText(tester, _hr.settingsSave);
    expect(
      app.settings.stored.thresholds.yellowDb,
      Thresholds.defaultYellowDb + 1,
    );
    expect(app.settings.saveCalls, 1);
    expect(app.languages.stored, AppLanguage.croatian);
    expect(find.text(_hr.measureStart), findsOneWidget);
  });

  testWidgets('a failed write is reported in the new language', (tester) async {
    final app = _App()..languages.saveException = Exception('disk full');
    await app.pump(tester);
    await tester.tap(find.byTooltip(l10nDe.actionSettings));
    await _settle(tester);
    await _tapText(tester, l10nDe.languageEnglish);
    expect(find.text(_en.settingsLanguageSaveFailed), findsOneWidget);
    expect(find.text(_en.settingsTitle), findsOneWidget);
    expect(app.languages.stored, AppLanguage.german);
  });
}

final class _AppInfo implements AppInfoPort {
  const _AppInfo();

  @override
  Future<AppInfo> load() async =>
      const AppInfo(versionName: '0.8.0', buildNumber: 87, gitCommit: 'abc');
}
