// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_character.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_painter.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_mood.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/shop/domain/pet_kind.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_shop_repository.dart';
import '../fakes/monitor_harness.dart';

void main() {
  testWidgets('a late wallet load preserves an away pet and recorder session', (
    tester,
  ) async {
    final monitor = MonitorHarness();
    final repo = InMemoryShopRepository(
      StarWallet(balance: 10).selectPet(PetKind.flocke),
    )..loadGate = Completer<void>();
    await tester.pumpWidget(
      RaumfreundApp(
        monitorController: monitor.controller,
        shopRepository: repo,
      ),
    );
    await tester.pump();
    await monitor.controller.start();
    await tester.pump();
    monitor.readings(redDbfs, 101);
    expect(monitor.state.kittyAway, isTrue);
    final starts = monitor.source.startCalls.length;
    repo.loadGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<HuskyCharacter>(find.byType(HuskyCharacter)).walkedAway,
      isTrue,
    );
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<HuskyPainter>()
        .single;
    expect(painter.walk, 1);
    expect(monitor.source.startCalls.length, starts);
    monitor.alarm.finish();
    await tester.pump();
    monitor.readings(greenDbfs, 30);
    await tester.pump();
    expect(
      tester.widget<HuskyCharacter>(find.byType(HuskyCharacter)).walkedAway,
      isFalse,
    );
    expect(monitor.source.startCalls.length, starts);
  });
  testWidgets(
    'late load during sleep shows Flocke asleep and wakes on return',
    (tester) async {
      final monitor = MonitorHarness();
      final repo = InMemoryShopRepository(
        StarWallet(balance: 10).selectPet(PetKind.flocke),
      )..loadGate = Completer<void>();
      await tester.pumpWidget(
        RaumfreundApp(
          monitorController: monitor.controller,
          settingsController: SettingsController(InMemorySettingsRepository()),
          shopRepository: repo,
        ),
      );
      await tester.pump();
      await tester.pump();
      await monitor.controller.start();
      await tester.pump();
      expect(monitor.state.status, MonitorStatus.measuring);
      monitor.controller.onLifecycleChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(monitor.state.status, MonitorStatus.sleeping);
      repo.loadGate!.complete();
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<HuskyCharacter>(find.byType(HuskyCharacter)).mood,
        KittyMood.sleeping,
      );
      expect(monitor.source.startCalls.length, 1);
      monitor.controller.onLifecycleChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(monitor.source.startCalls.length, 2);
      expect(
        tester.widget<HuskyCharacter>(find.byType(HuskyCharacter)).wakeUp,
        isTrue,
      );
    },
  );
}
