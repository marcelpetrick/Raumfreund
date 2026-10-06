// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_theme.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

import '../../../shared/widgets/test_app.dart';

Widget _host(
  ValueChanged<AppSettings?> onResult, {
  Future<bool> Function(AppSettings)? onSave,
  AppSettings? initial,
  double textScale = 1,
}) => MaterialApp(
  theme: buildAppTheme(),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
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
              builder: (_) => SettingsPage(
                initialSettings: initial ?? AppSettings.defaults,
                onSave: onSave ?? (_) async => true,
              ),
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
  ValueChanged<AppSettings?> onResult, {
  Future<bool> Function(AppSettings)? onSave,
  AppSettings? initial,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _host(onResult, onSave: onSave, initial: initial, textScale: textScale),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _pumpWithReset(
  WidgetTester tester,
  Future<StarResetResult> Function() onReset,
) async {
  await tester.pumpWidget(
    testApp(
      SettingsPage(
        initialSettings: AppSettings.defaults,
        onSave: (_) async => true,
        onResetStars: onReset,
      ),
      scaffold: false,
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(l10nDe.settingsResetButton));
  await tester.pumpAndSettle();
}

void _resetTests() {
  testWidgets('star reset is hidden unless the app offers it', (tester) async {
    await _open(tester, (_) {});
    expect(find.text(l10nDe.settingsResetHeading), findsNothing);
  });

  testWidgets('star reset needs confirmation and can be cancelled', (
    tester,
  ) async {
    var resets = 0;
    await _pumpWithReset(tester, () async {
      resets++;
      return StarResetResult.done;
    });
    expect(find.text(l10nDe.settingsResetBody), findsOneWidget);
    await tester.tap(find.text(l10nDe.settingsResetButton));
    await tester.pumpAndSettle();
    expect(find.text(l10nDe.settingsResetConfirmTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10nDe.shopConfirmCancel),
      ),
    );
    await tester.pumpAndSettle();
    expect(resets, 0);
    expect(find.text(l10nDe.settingsResetDone), findsNothing);
  });

  testWidgets('confirmed star reset runs once and says so', (tester) async {
    var resets = 0;
    await _pumpWithReset(tester, () async {
      resets++;
      return StarResetResult.done;
    });
    await tester.tap(find.text(l10nDe.settingsResetButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(resets, 1);
    expect(find.text(l10nDe.settingsResetDone), findsOneWidget);
  });

  testWidgets('star reset reports a wallet that is not loaded yet', (
    tester,
  ) async {
    await _pumpWithReset(tester, () async => StarResetResult.notReady);
    await tester.tap(find.text(l10nDe.settingsResetButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(find.text(l10nDe.settingsResetNotReady), findsOneWidget);
  });

  testWidgets('star reset says when storing failed', (tester) async {
    await _pumpWithReset(tester, () async => StarResetResult.saveFailed);
    await tester.tap(find.text(l10nDe.settingsResetButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nDe.settingsResetConfirm));
    await tester.pumpAndSettle();
    expect(find.text(l10nDe.settingsResetSaveFailed), findsOneWidget);
    expect(find.text(l10nDe.settingsResetDone), findsNothing);
  });
}

void main() {
  _resetTests();
  testWidgets('renders all controls and cancel discards the draft', (
    tester,
  ) async {
    AppSettings? result = AppSettings.defaults;
    await _open(tester, (value) => result = value);
    expect(find.text(l10nDe.settingsThresholdsHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsCalibrationHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsAlarmHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsStarTestHeading), findsOneWidget);
    expect(find.text(l10nDe.settingsStarTestModeHint), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(4));
    expect(find.byType(SwitchListTile), findsNWidgets(3));
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
    switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .toList();
    switches[2].onChanged!(true);
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
    expect(result?.quickStarModeEnabled, isTrue);
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

  _registerSaveRetryTest();
  _registerAlarmDelayTests();
}

Finder _delaySlider() => find.byType(Slider).at(3);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _registerAlarmDelayTests() {
  group('alarm delay', _alarmDelayTests);
}

void _alarmDelayTests() {
  testWidgets('slider and steppers change the delay and save it', (
    tester,
  ) async {
    AppSettings? result;
    await _open(tester, (value) => result = value);
    expect(find.text(l10nDe.settingsSecondsValue(10)), findsOneWidget);
    expect(find.text(l10nDe.settingsAlarmDelayRule(10, 3, 60, 10)), findsOne);
    tester.widget<Slider>(_delaySlider()).onChanged!(5);
    await tester.pump();
    expect(find.text(l10nDe.settingsSecondsValue(5)), findsOneWidget);
    expect(find.text(l10nDe.settingsAlarmDelayRule(5, 3, 60, 10)), findsOne);
    await _tapVisible(
      tester,
      find.byTooltip(l10nDe.settingsAlarmDelayIncrease),
    );
    await _tapVisible(
      tester,
      find.byTooltip(l10nDe.settingsAlarmDelayIncrease),
    );
    await _tapVisible(
      tester,
      find.byTooltip(l10nDe.settingsAlarmDelayDecrease),
    );
    await _tapVisible(tester, find.text(l10nDe.settingsSave));
    expect(result?.alarmDelaySeconds, 6);
  });

  testWidgets('cancel discards a changed delay', (tester) async {
    AppSettings? result = AppSettings.defaults;
    await _open(tester, (value) => result = value);
    tester.widget<Slider>(_delaySlider()).onChanged!(42);
    await tester.pump();
    await _tapVisible(tester, find.text(l10nDe.settingsCancel));
    expect(result, isNull);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(l10nDe.settingsSecondsValue(10)), findsOneWidget);
  });

  testWidgets('steppers stop at the limits; defaults restore 10 s', (
    tester,
  ) async {
    AppSettings? result;
    final atMax = AppSettings.defaults.copyWith(alarmDelaySeconds: 60);
    await _open(tester, (value) => result = value, initial: atMax);
    final plus = find.byTooltip(l10nDe.settingsAlarmDelayIncrease);
    await tester.ensureVisible(plus);
    expect(_iconButton(tester, plus).onPressed, isNull);
    tester.widget<Slider>(_delaySlider()).onChanged!(3);
    await tester.pump();
    final minus = find.byTooltip(l10nDe.settingsAlarmDelayDecrease);
    expect(_iconButton(tester, minus).onPressed, isNull);
    await _tapVisible(tester, find.text(l10nDe.settingsDefaults));
    await _tapVisible(tester, find.text(l10nDe.settingsSave));
    expect(result?.alarmDelaySeconds, 10);
  });

  _registerAlarmDelayAccessibilityTest();
}

IconButton _iconButton(WidgetTester tester, Finder tooltip) => tester.widget(
  find.ancestor(of: tooltip, matching: find.byType(IconButton)),
);

void _registerAlarmDelayAccessibilityTest() {
  testWidgets('delay control is labelled, large enough and never clipped', (
    tester,
  ) async {
    setScreenSize(tester, const Size(320, 900));
    final handle = tester.ensureSemantics();
    final slowest = AppSettings.defaults.copyWith(alarmDelaySeconds: 60);
    await _open(tester, (_) {}, initial: slowest, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_delaySlider());
    await tester.pumpAndSettle();
    // The slider merges into one node with its name (MergeSemantics).
    final merged = find.ancestor(
      of: _delaySlider(),
      matching: find.byType(MergeSemantics),
    );
    final data = tester.getSemantics(merged.first).getSemanticsData();
    expect(data.label, contains(l10nDe.settingsAlarmDelayLabel));
    expect(data.value, l10nDe.settingsSecondsValue(60));
    expect(data.decreasedValue, l10nDe.settingsSecondsValue(59));
    expect(data.flagsCollection.isSlider, isTrue);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}

void _registerSaveRetryTest() {
  testWidgets('failed save keeps draft open and can be retried', (
    tester,
  ) async {
    AppSettings? result;
    var attempts = 0;
    await _open(
      tester,
      (value) => result = value,
      onSave: (settings) async {
        attempts++;
        return attempts > 1;
      },
    );
    await tester.tap(find.byTooltip(l10nDe.settingsIncrease('Gelb ab')));
    await tester.ensureVisible(find.text(l10nDe.settingsSave));
    await tester.tap(find.text(l10nDe.settingsSave));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text(l10nDe.settingsSaveError), findsOneWidget);
    expect(find.text(l10nDe.settingsRetrySave), findsOneWidget);
    expect(result, isNull);

    await tester.ensureVisible(find.text(l10nDe.settingsRetrySave));
    await tester.pump();
    await tester.tap(find.text(l10nDe.settingsRetrySave));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(result?.thresholds.yellowDb, 61);
  });
}
