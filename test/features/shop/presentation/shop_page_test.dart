// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_character.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/presentation/shop_page.dart';

import '../../../fakes/in_memory_shop_repository.dart';
import '../../../shared/widgets/test_app.dart';

Future<ShopController> _pump(
  WidgetTester tester, {
  StarWallet? wallet,
  InMemoryShopRepository? repository,
  double textScale = 1,
  bool load = true,
}) async {
  final repo = repository ?? InMemoryShopRepository(wallet);
  final controller = ShopController(repo);
  addTearDown(controller.dispose);
  if (load) await controller.load();
  await tester.pumpWidget(
    testApp(
      ShopPage(controller: rt(controller)),
      scaffold: false,
      disableAnimations: true,
      textScale: textScale,
    ),
  );
  await tester.pump();
  return controller;
}

Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
);

void _purchaseTests() {
  testWidgets('buying asks first and cancel keeps the stars', (tester) async {
    final shop = await _pump(tester, wallet: StarWallet(balance: 5));
    await tester.tap(_button(l10nDe.shopBuy).first);
    await tester.pumpAndSettle();
    expect(find.text('Schleife für 3 Sterne kaufen?'), findsOneWidget);
    await tester.tap(find.text(l10nDe.shopConfirmCancel));
    await tester.pumpAndSettle();
    expect(shop.wallet.balance, 5);
    expect(shop.wallet.owned, isEmpty);
  });

  testWidgets('confirmed purchase spends stars and offers equipping', (
    tester,
  ) async {
    final shop = await _pump(tester, wallet: StarWallet(balance: 5));
    await tester.tap(_button(l10nDe.shopBuy).first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10nDe.shopConfirmBuy),
      ),
    );
    await tester.pumpAndSettle();
    expect(shop.wallet.balance, 2);
    expect(shop.wallet.owned, {KittyAccessory.bow});
    expect(find.text(l10nDe.shopBalance(2)), findsOneWidget);
    expect(find.text(l10nDe.shopOwned), findsOneWidget);
    expect(_button(l10nDe.shopEquip), findsOneWidget);
  });

  testWidgets(
    'not enough stars disables the button and shows what is missing',
    (tester) async {
      final shop = await _pump(tester, wallet: StarWallet(balance: 1));
      final button = tester.widget<ButtonStyleButton>(
        _button(l10nDe.shopMissing(2)),
      );
      expect(button.onPressed, isNull);
      await tester.tap(_button(l10nDe.shopMissing(2)), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(shop.wallet.balance, 1);
    },
  );
}

void main() {
  testWidgets('shows balance, Mia and all five items', (tester) async {
    await _pump(tester, wallet: StarWallet(balance: 4));
    expect(find.text(l10nDe.shopBalance(4)), findsOneWidget);
    expect(find.byType(KittyCharacter), findsOneWidget);
    for (final item in KittyAccessory.values) {
      expect(find.text(l10nDe.shopPrice(item.price)), findsOneWidget);
    }
    expect(_button(l10nDe.shopBuy), findsOneWidget);
    expect(_button(l10nDe.shopMissing(1)), findsOneWidget);
  });

  _purchaseTests();
  testWidgets('owned items can be put on and taken off', (tester) async {
    final shop = await _pump(
      tester,
      wallet: StarWallet(owned: {KittyAccessory.bow}),
    );
    await tester.tap(_button(l10nDe.shopEquip));
    await tester.pump();
    expect(shop.wallet.equipped, {KittyAccessory.bow});
    expect(find.text(l10nDe.shopWorn), findsOneWidget);
    expect(
      tester.widget<KittyCharacter>(find.byType(KittyCharacter)).accessories,
      {KittyAccessory.bow},
    );
    await tester.tap(_button(l10nDe.shopUnequip));
    await tester.pump();
    expect(shop.wallet.equipped, isEmpty);
    expect(find.text(l10nDe.shopWorn), findsNothing);
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    final repository = InMemoryShopRepository()..loadGate = Completer<void>();
    final shop = await _pump(tester, repository: repository, load: false);
    unawaited(shop.load());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(KittyCharacter), findsNothing);
    repository.loadGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(KittyCharacter), findsOneWidget);
  });
  _hintAndLayoutTests();
}

void _hintAndLayoutTests() {
  testWidgets('a failed load shows a non-blocking hint', (tester) async {
    final repository = InMemoryShopRepository()
      ..loadException = Exception('storage');
    await _pump(tester, repository: repository);
    expect(find.text(l10nDe.shopLoadFailed), findsOneWidget);
    expect(find.text(l10nDe.shopBalance(0)), findsOneWidget);
    expect(find.byType(KittyCharacter), findsOneWidget);
  });

  testWidgets('a failed load never offers purchases with unmerged stars', (
    tester,
  ) async {
    final repository = InMemoryShopRepository()
      ..loadException = Exception('storage');
    final shop = await _pump(tester, repository: repository);
    shop.earn(12);
    await tester.pump();
    expect(shop.wallet.balance, 12);
    expect(shop.isReady, isFalse);
    final buy = tester.widget<ButtonStyleButton>(_button(l10nDe.shopBuy).first);
    expect(buy.onPressed, isNull);
    await tester.tap(_button(l10nDe.shopBuy).first, warnIfMissed: false);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a failed save shows a hint that can be dismissed', (
    tester,
  ) async {
    final repository = InMemoryShopRepository(
      StarWallet(owned: {KittyAccessory.bow}),
    )..saveException = Exception('disk full');
    final shop = await _pump(tester, repository: repository);
    await tester.tap(_button(l10nDe.shopEquip));
    await tester.pump();
    await shop.flush();
    await tester.pump();
    expect(find.text(l10nDe.shopSaveFailed), findsOneWidget);
    await tester.tap(find.text(l10nDe.shopDismiss));
    await tester.pump();
    expect(find.text(l10nDe.shopSaveFailed), findsNothing);
  });

  testWidgets('item summary is one spoken sentence with the state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      wallet: StarWallet(
        owned: {KittyAccessory.bow},
        equipped: {KittyAccessory.bow},
      ),
    );
    expect(
      find.bySemanticsLabel(
        '${l10nDe.accessoryBow}, ${l10nDe.shopPrice(3)}, ${l10nDe.shopWorn}',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('${l10nDe.accessoryScarf}, ${l10nDe.shopPrice(5)}'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('fits 320 dp at 200 % text without overflow and keeps 48 dp', (
    tester,
  ) async {
    setScreenSize(tester, const Size(320, 640));
    await _pump(tester, wallet: StarWallet(balance: 12), textScale: 2);
    expect(tester.takeException(), isNull);
    for (final button in tester.widgetList(find.byType(ButtonStyleButton))) {
      expect(button, isA<ButtonStyleButton>());
    }
    final buy = tester.getSize(_button(l10nDe.shopBuy).first);
    expect(buy.height, greaterThanOrEqualTo(48));
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
