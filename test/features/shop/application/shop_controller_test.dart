// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

import '../../../fakes/in_memory_shop_repository.dart';

const bow = KittyAccessory.bow;
const scarf = KittyAccessory.scarf;

late InMemoryShopRepository repository;
late ShopController controller;
late int notifications;

void main() {
  setUp(() {
    repository = InMemoryShopRepository(StarWallet(balance: 4));
    controller = ShopController(repository);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  loadTests();
  changeTests();
}

void loadTests() {
  group('load', () {
    test('is loading with an empty wallet until loaded', () async {
      expect(controller.isLoading, isTrue);
      expect(controller.wallet, StarWallet.empty());
      await controller.load();
      expect(controller.isLoading, isFalse);
      expect(controller.loadFailed, isFalse);
      expect(controller.wallet.balance, 4);
      expect(notifications, 1);
    });

    test('repeated load calls share one load', () async {
      repository.loadGate = Completer<void>();
      final first = controller.load();
      expect(identical(first, controller.load()), isTrue);
      repository.loadGate!.complete();
      await first;
    });

    test('a failing load keeps an empty wallet and flags it', () async {
      repository.loadException = const FormatException('broken');
      await controller.load();
      expect(controller.loadFailed, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.wallet, StarWallet.empty());
    });

    test('stars earned while loading are added and saved', () async {
      repository.loadGate = Completer<void>();
      final loading = controller.load();
      controller
        ..earn(1)
        ..earn(2);
      expect(controller.wallet.balance, 3);
      repository.loadGate!.complete();
      await loading;
      await controller.flush();
      expect(controller.wallet.balance, 7);
      expect(repository.stored.balance, 7);
      expect(repository.saves, hasLength(1));
    });

    test('stars earned while a load fails are kept', () async {
      repository
        ..loadGate = Completer<void>()
        ..loadException = const FormatException('broken');
      final loading = controller.load();
      controller.earn(2);
      repository.loadGate!.complete();
      await loading;
      expect(controller.wallet.balance, 2);
    });

    test('a failed load never saves; a retry merges and saves once', () async {
      repository.loadException = const FormatException('broken');
      await controller.load();
      controller.earn(3);
      await controller.flush();
      expect(repository.saves, isEmpty);
      expect(controller.buy(bow).failure, PurchaseFailure.notReady);
      expect(controller.toggleEquipped(bow), isFalse);
      expect(controller.resetAll(), isFalse);
      repository
        ..loadException = null
        ..stored = StarWallet(balance: 5);
      await controller.load();
      await controller.flush();
      expect(controller.loadFailed, isFalse);
      expect(controller.wallet.balance, 8);
      expect(repository.saves, hasLength(1));
      expect(repository.stored.balance, 8);
    });

    test('other changes are refused while loading', () async {
      repository.loadGate = Completer<void>();
      final loading = controller.load();
      expect(controller.buy(bow).failure, PurchaseFailure.notReady);
      expect(controller.toggleEquipped(bow), isFalse);
      expect(controller.resetAll(), isFalse);
      repository.loadGate!.complete();
      await loading;
      expect(repository.saves, isEmpty);
    });
  });
}

void changeTests() {
  group('changes', () {
    setUp(() => controller.load());

    test('earn persists', () async {
      controller.earn(1);
      expect(controller.wallet.balance, 5);
      await controller.flush();
      expect(repository.stored.balance, 5);
      expect(controller.saveFailed, isFalse);
      expect(controller.isSaving, isFalse);
    });

    test('buy, equip, unequip persist; failures change nothing', () async {
      expect(controller.buy(scarf).failure, PurchaseFailure.notEnoughStars);
      expect(controller.buy(bow).isSuccess, isTrue);
      expect(controller.buy(bow).failure, PurchaseFailure.alreadyOwned);
      expect(controller.toggleEquipped(scarf), isFalse);
      expect(controller.toggleEquipped(bow), isTrue);
      await controller.flush();
      expect(repository.stored.equipped, {bow});
      expect(controller.toggleEquipped(bow), isTrue);
      await controller.flush();
      expect(repository.stored.equipped, isEmpty);
      expect(repository.stored.balance, 1);
    });

    test('resetAll clears stars and items', () async {
      controller.buy(bow);
      expect(controller.resetAll(), isTrue);
      await controller.flush();
      expect(repository.stored, StarWallet.empty());
    });

    test('rapid operations build on each other and are serialized', () async {
      repository.saveGate = Completer<void>();
      controller
        ..earn(10)
        ..buy(KittyAccessory.hat)
        ..earn(1);
      expect(controller.buy(scarf).isSuccess, isTrue);
      expect(controller.buy(bow).isSuccess, isFalse);
      controller.toggleEquipped(scarf);
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSaving, isTrue);
      repository.saveGate!.complete();
      await controller.flush();
      expect(repository.stored, controller.wallet);
      expect(repository.stored.balance, 2);
      expect(repository.stored.equipped, {scarf});
      // Only the first save started before the newest change; the queued
      // ones are coalesced into a single write of the newest wallet.
      expect(repository.saves.length, lessThan(6));
    });

    test('a failing save is flagged, keeps the wallet, retries', () async {
      repository.saveException = const FormatException('disk');
      controller.earn(1);
      await controller.flush();
      expect(controller.saveFailed, isTrue);
      expect(controller.wallet.balance, 5);
      expect(repository.stored.balance, 4);
      repository.saveException = null;
      controller.earn(1);
      await controller.flush();
      expect(controller.saveFailed, isFalse);
      expect(repository.stored.balance, 6);
    });

    test('clearSaveError hides the error once', () async {
      repository.saveException = const FormatException('disk');
      controller.earn(1);
      await controller.flush();
      controller.clearSaveError();
      expect(controller.saveFailed, isFalse);
      final before = notifications;
      controller.clearSaveError();
      expect(notifications, before);
    });

    test('earn rejects non-positive amounts', () {
      expect(() => controller.earn(0), throwsArgumentError);
    });

    test('dispose is idempotent and silences listeners', () async {
      repository.saveGate = Completer<void>();
      controller
        ..earn(1)
        ..dispose()
        ..dispose();
      repository.saveGate!.complete();
      await controller.flush();
      expect(repository.stored.balance, 5);
    });
  });
}
