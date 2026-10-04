// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_theme.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

import '../../../shared/widgets/test_app.dart';

Widget _host(ValueChanged<AppSettings?> onResult) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('de'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: FilledButton(
        onPressed: () async {
          final result = await Navigator.push<AppSettings>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SettingsPage(initialSettings: AppSettings.defaults),
            ),
          );
          onResult(result);
        },
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _open(
  WidgetTester tester,
  ValueChanged<AppSettings?> onResult,
) async {
  await tester.pumpWidget(_host(onResult));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders all controls and cancel discards the draft', (
    tester,
  ) async {
    AppSettings? result = AppSettings.defaults;
    await _open(tester, (value) => result = value);
    expect(find.text(l10nDe.settingsThresholdsHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsCalibrationHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsAlarmHeading), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    await tester.ensureVisible(find.text(l10nDe.settingsCancel));
    await tester.tap(find.text(l10nDe.settingsCancel));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('edits coupled limits, calibration and alarm options', (
    tester,
  ) async {
    AppSettings? result;
    await _open(tester, (value) => result = value);

    var sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    sliders[0].onChanged!(80);
    await tester.pump();
    sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    sliders[1].onChanged!(40);
    await tester.pump();
    sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    sliders[2].onChanged!(7);
    await tester.pump();

    var switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    switches[0].onChanged!(false);
    await tester.pump();
    switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    switches[1].onChanged!(false);
    await tester.pump();

    await tester.ensureVisible(find.text(l10nDe.settingsSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsSave));
    await tester.pumpAndSettle();
    expect(result?.thresholds.yellowDb, 39);
    expect(result?.thresholds.redDb, 40);
    expect(result?.calibrationCorrectionDb, 7);
    expect(result?.alarmSoundEnabled, isFalse);
    expect(result?.vibrationEnabled, isFalse);
  });

  testWidgets('step buttons clamp limits and defaults reset the draft', (
    tester,
  ) async {
    AppSettings? result;
    await _open(tester, (value) => result = value);
    await tester.tap(find.byTooltip(l10nDe.settingsIncrease('Gelb ab')));
    await tester.pump();
    await tester.ensureVisible(find.text(l10nDe.settingsDefaults));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsDefaults));
    await tester.pump();
    expect(find.text(l10nDe.settingsDefaultsApplied), findsOneWidget);
    await tester.ensureVisible(find.text(l10nDe.settingsSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsSave));
    await tester.pumpAndSettle();
    expect(result, AppSettings.defaults);
  });
}
