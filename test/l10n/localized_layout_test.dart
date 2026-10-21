// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';
import 'package:raumfreund/features/about/presentation/about_page.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_page.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';
import 'package:raumfreund/features/settings/application/language_controller.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/presentation/shop_page.dart';

import '../fakes/in_memory_language_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../shared/widgets/test_app.dart';

/// Every page in every language on a small phone, at normal and doubled
/// text size: a longer translation must wrap, never overflow or clip.
void main() {
  for (final language in AppLanguage.values) {
    for (final scale in const [1.0, 2.0]) {
      final name = '${language.code} at ${scale}x';
      final locale = Locale(language.code);

      testWidgets('monitor states fit in $name', (tester) async {
        for (final data in _monitorStates) {
          await _pump(tester, locale, scale, _monitor(data));
        }
      });

      testWidgets('settings fit in $name', (tester) async {
        final controller = LanguageController(
          InMemoryLanguageRepository(language),
        );
        addTearDown(controller.dispose);
        await _pump(tester, locale, scale, _settings(controller));
      });

      testWidgets('shop and about fit in $name', (tester) async {
        final shop = ShopController(InMemoryShopRepository(_wallet));
        addTearDown(shop.dispose);
        await shop.load();
        await _pump(tester, locale, scale, ShopPage(controller: shop));
        await _pump(tester, locale, scale, const AboutPage(info: _info));
      });
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  double scale,
  Widget page,
) async {
  setScreenSize(tester, const Size(360, 780));
  await tester.pumpWidget(
    testApp(
      page,
      scaffold: false,
      disableAnimations: true,
      textScale: scale,
      locale: locale,
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Widget _monitor(MonitorViewData data) => MonitorPage(
  data: data,
  onToggleMeasurement: () {},
  onRetry: () {},
  onOpenAndroidSettings: () {},
  onOpenSettings: () async {},
  onOpenAbout: () async {},
  onOpenShop: () async {},
);

Widget _settings(LanguageController controller) => SettingsPage(
  initialSettings: AppSettings.defaults,
  onSave: (_) async => true,
  onResetStars: () async => StarResetResult.done,
  languageController: controller,
);

final StarWallet _wallet = StarWallet(
  balance: 7,
  owned: const {KittyAccessory.bow, KittyAccessory.hat},
  equipped: const {KittyAccessory.bow},
);

const AppInfo _info = AppInfo(
  versionName: '0.8.0',
  buildNumber: 87,
  gitCommit: 'abc1234',
);

final List<MonitorViewData> _monitorStates = [
  _state(MonitorPhase.idle),
  _state(MonitorPhase.measuring, zone: Zone.yellow, countdown: 4),
  _state(MonitorPhase.measuring, zone: Zone.red, alarmFired: true),
  _state(MonitorPhase.sleeping),
  _state(MonitorPhase.starting, waking: true),
  _state(MonitorPhase.error, error: MonitorErrorKind.noReadings),
  _state(MonitorPhase.error, error: MonitorErrorKind.microphoneBusy),
];

MonitorViewData _state(
  MonitorPhase phase, {
  Zone? zone,
  int? countdown,
  bool alarmFired = false,
  bool waking = false,
  MonitorErrorKind? error,
}) => MonitorViewData(
  phase: phase,
  thresholds: Thresholds.defaults,
  levelDb: zone == null ? null : 72,
  zone: zone,
  history: const [
    LevelHistoryPoint(timestamp: Duration.zero, levelDb: 40),
    LevelHistoryPoint(timestamp: Duration(minutes: 5), levelDb: 72),
  ],
  alarmSecondsRemaining: countdown,
  alarmFired: alarmFired,
  alarmOutputFailed: alarmFired,
  signalThin: alarmFired,
  kittyWalkedAway: alarmFired,
  kittyAccessories: const {KittyAccessory.bow},
  stars: 3,
  walletStars: 12,
  starProgress: .4,
  waking: waking,
  error: error,
);
