// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_character.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/shop/domain/pet_kind.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/presentation/shop_page.dart';

import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../fakes/monitor_harness.dart';
import '../shared/widgets/test_app.dart';

Future<void> _pumpWork(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpTeardown(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await _pumpWork(tester);
}

void main() {
  testWidgets('shop selection survives app recreation without restarting', (
    tester,
  ) async {
    final shopRepository = InMemoryShopRepository(StarWallet(balance: 10));
    final monitor = MonitorHarness();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(InMemorySettingsRepository()),
        monitorController: monitor.controller,
        shopRepository: shopRepository,
      ),
    );
    await _pumpWork(tester);
    await tester.tap(find.text(l10nDe.measureStart));
    await _pumpWork(tester);
    expect(monitor.state.status, MonitorStatus.measuring);
    expect(monitor.source.startCalls, hasLength(1));

    await tester.tap(find.byTooltip(l10nDe.actionShop));
    await _pumpTeardown(tester);
    expect(find.byType(ShopPage), findsOneWidget);
    expect(monitor.source.stopCalls, 1);
    expect(monitor.source.recordingSession, isNull);
    await tester.ensureVisible(find.text(l10nDe.shopPetFlocke));
    await tester.pump();
    await tester.tap(find.text(l10nDe.shopPetFlocke));
    await _pumpWork(tester);
    expect(shopRepository.stored.selectedPet, PetKind.flocke);
    expect(shopRepository.stored.balance, 10);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await _pumpWork(tester);
    expect(find.byType(HuskyCharacter), findsOneWidget);
    expect(find.text(l10nDe.measureStart), findsOneWidget);
    expect(monitor.source.startCalls, hasLength(1));
    expect(monitor.source.recordingSession, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    final restartedMonitor = MonitorHarness();
    await tester.pumpWidget(
      RaumfreundApp(
        settingsController: SettingsController(InMemorySettingsRepository()),
        monitorController: restartedMonitor.controller,
        shopRepository: shopRepository,
      ),
    );
    await _pumpWork(tester);
    expect(find.byType(HuskyCharacter), findsOneWidget);
    expect(find.text(l10nDe.measureStart), findsOneWidget);
    expect(restartedMonitor.source.startCalls, isEmpty);
    expect(restartedMonitor.source.recordingSession, isNull);
  });
}
