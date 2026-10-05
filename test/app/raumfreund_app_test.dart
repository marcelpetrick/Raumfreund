// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_character.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/presentation/shop_page.dart';

import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../fakes/monitor_harness.dart';
import '../shared/widgets/test_app.dart';

void main() {
  testWidgets('measurement stays disabled until stored settings are applied', (
    tester,
  ) async {
    final repository = InMemorySettingsRepository();
    repository.gate = Completer<void>();
    final monitor = MonitorHarness();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(repository),
        monitorController: monitor.controller,
        appInfoPort: const _FakeAppInfoPort(),
      ),
    );
    await tester.pump();

    expect(_measurementButton(tester).onPressed, isNull);
    expect(monitor.source.startCalls, isEmpty);

    repository.gate!.complete();
    await _finishAsyncWork(tester);
    expect(_measurementButton(tester).onPressed, isNotNull);
  });

  testWidgets('rapid secondary actions open only one route', (tester) async {
    final monitor = MonitorHarness();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(InMemorySettingsRepository()),
        monitorController: monitor.controller,
        appInfoPort: const _FakeAppInfoPort(),
      ),
    );
    await _finishAsyncWork(tester);

    final settingsAction = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.settings_rounded),
    );
    final aboutAction = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.info_outline_rounded),
    );
    settingsAction.onPressed!();
    aboutAction.onPressed!();
    await _finishAsyncWork(tester);
    expect(find.byType(SettingsPage), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await _finishAsyncWork(tester);
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.text(l10nDe.appTitle), findsOneWidget);
  });
  _shopTests();
}

void _shopTests() {
  testWidgets('the shop action stops a measurement and does not restart it', (
    tester,
  ) async {
    final monitor = MonitorHarness();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(InMemorySettingsRepository()),
        monitorController: monitor.controller,
        shopRepository: InMemoryShopRepository(),
        appInfoPort: const _FakeAppInfoPort(),
      ),
    );
    await _finishAsyncWork(tester);
    await tester.tap(find.text(l10nDe.measureStart));
    await _finishAsyncWork(tester);
    expect(monitor.source.startCalls, hasLength(1));
    expect(find.text(l10nDe.measureStop), findsOneWidget);

    await tester.tap(find.byTooltip(l10nDe.actionShop));
    await _finishWithRealAsync(tester);
    expect(find.byType(ShopPage), findsOneWidget);
    expect(monitor.source.stopCalls, 1);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await _finishAsyncWork(tester);
    expect(find.text(l10nDe.measureStart), findsOneWidget);
    expect(monitor.source.startCalls, hasLength(1));
  });

  testWidgets('earned stars reach the wallet and equipped items reach Mia', (
    tester,
  ) async {
    final repository = InMemoryShopRepository(
      StarWallet(
        balance: 2,
        owned: {KittyAccessory.bow},
        equipped: {KittyAccessory.bow},
      ),
    );
    late MonitorHarness monitor;
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(InMemorySettingsRepository()),
        monitorFactory: (onStarEarned) {
          monitor = MonitorHarness(onStarEarned: onStarEarned);
          return monitor.controller;
        },
        shopRepository: repository,
        appInfoPort: const _FakeAppInfoPort(),
      ),
    );
    await _finishAsyncWork(tester);
    expect(
      tester.widget<KittyCharacter>(find.byType(KittyCharacter)).accessories,
      {KittyAccessory.bow},
    );

    await tester.tap(find.text(l10nDe.measureStart));
    await _finishAsyncWork(tester);
    monitor.readings(greenDbfs, 601);
    await _finishAsyncWork(tester);
    expect(repository.stored.balance, 3);

    await tester.tap(find.byTooltip(l10nDe.actionShop));
    await _finishWithRealAsync(tester);
    expect(find.text(l10nDe.shopBalance(3)), findsOneWidget);
  });
}

FilledButton _measurementButton(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, l10nDe.measureStart));

/// Stopping a live measurement cancels a real stream subscription whose
/// future completes outside of FakeAsync, so the test must let real time pass.
Future<void> _finishWithRealAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await _finishAsyncWork(tester);
}

Future<void> _finishAsyncWork(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

final class _FakeAppInfoPort implements AppInfoPort {
  const _FakeAppInfoPort();

  @override
  Future<AppInfo> load() async =>
      const AppInfo(versionName: '0.1.0', buildNumber: 12, gitCommit: 'test');
}
