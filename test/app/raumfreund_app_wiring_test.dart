// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';
import 'package:raumfreund/features/about/presentation/about_page.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../fakes/monitor_harness.dart';
import '../shared/widgets/test_app.dart';

/// How the app connects its pages to the controllers: About, saving
/// settings, the teacher's star reset and the Android settings shortcut.
void main() {
  _aboutTests();
  _settingsTests();
  _starResetTests();
  _androidSettingsTest();
}

/// The app under test with its fakes.
final class _App {
  final MonitorHarness monitor = MonitorHarness();
  final InMemorySettingsRepository settings = InMemorySettingsRepository();
  final InMemoryShopRepository shop = InMemoryShopRepository(
    StarWallet.empty().earn(5),
  );

  Future<void> pump(WidgetTester tester, {AppInfoPort? appInfo}) async {
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(settings),
        monitorController: monitor.controller,
        shopRepository: shop,
        appInfoPort: appInfo ?? const _AppInfo(),
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

Future<SettingsPage> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip(l10nDe.actionSettings));
  await _settle(tester);
  return tester.widget<SettingsPage>(find.byType(SettingsPage));
}

void _aboutTests() {
  testWidgets('About shows the loaded build information', (tester) async {
    await _App().pump(tester);
    await tester.tap(find.byTooltip(l10nDe.actionAbout));
    await _settle(tester);
    final about = tester.widget<AboutPage>(find.byType(AboutPage));
    expect(about.info.versionName, '0.7.2');
    expect(about.info.gitCommit, 'abc1234');
  });

  testWidgets('About still opens when the build information fails', (
    tester,
  ) async {
    await _App().pump(tester, appInfo: const _AppInfo(fails: true));
    await tester.tap(find.byTooltip(l10nDe.actionAbout));
    await _settle(tester);
    final about = tester.widget<AboutPage>(find.byType(AboutPage));
    expect(about.info.versionName, '–');
    expect(about.info.gitCommit, 'unknown');
  });
}

void _settingsTests() {
  final edited = AppSettings.defaults.copyWith(alarmDelaySeconds: 20);

  testWidgets('saved settings reach the monitor', (tester) async {
    final app = _App();
    await app.pump(tester);
    final page = await _openSettings(tester);
    expect(await page.onSave(edited), isTrue);
    expect(app.monitor.controller.settings, edited);
    expect(app.settings.stored, edited);
  });

  testWidgets('a failed save leaves the monitor settings alone', (
    tester,
  ) async {
    final app = _App();
    await app.pump(tester);
    app.settings.saveException = Exception('disk full');
    final page = await _openSettings(tester);
    expect(await page.onSave(edited), isFalse);
    expect(app.monitor.controller.settings, AppSettings.defaults);
  });
}

void _starResetTests() {
  testWidgets('the star reset clears and stores the wallet', (tester) async {
    final app = _App();
    await app.pump(tester);
    final page = await _openSettings(tester);
    expect(await page.onResetStars!(), StarResetResult.done);
    expect(app.shop.stored.balance, 0);
  });

  testWidgets('the star reset reports a failed save', (tester) async {
    final app = _App();
    await app.pump(tester);
    app.shop.saveException = Exception('disk full');
    final page = await _openSettings(tester);
    expect(await page.onResetStars!(), StarResetResult.saveFailed);
  });

  testWidgets('the star reset waits for a loaded wallet', (tester) async {
    final app = _App();
    app.shop.loadException = Exception('locked');
    await app.pump(tester);
    final page = await _openSettings(tester);
    expect(await page.onResetStars!(), StarResetResult.notReady);
    expect(app.shop.stored.balance, 5);
  });
}

void _androidSettingsTest() {
  testWidgets('a permanent denial opens the Android app settings', (
    tester,
  ) async {
    final app = _App();
    app.monitor.permission
      ..currentStatus = MicrophonePermissionStatus.permanentlyDenied
      ..requestResult = MicrophonePermissionStatus.permanentlyDenied;
    await app.pump(tester);
    await tester.tap(find.text(l10nDe.measureStart));
    await _settle(tester);
    expect(
      app.monitor.state.failure,
      MonitorFailure.permissionPermanentlyDenied,
    );
    await tester.ensureVisible(find.text(l10nDe.errorOpenSettings));
    await tester.tap(find.text(l10nDe.errorOpenSettings));
    await _settle(tester);
    expect(app.monitor.permission.openSettingsCalls, 1);
  });
}

final class _AppInfo implements AppInfoPort {
  const _AppInfo({this.fails = false});

  final bool fails;

  @override
  Future<AppInfo> load() async {
    if (fails) throw Exception('package info unavailable');
    return const AppInfo(
      versionName: '0.7.2',
      buildNumber: 81,
      gitCommit: 'abc1234',
    );
  }
}
