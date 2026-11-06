// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/pet_kind.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/infrastructure/shared_preferences_shop_repository.dart';

import '../../fakes/fake_preferences_store.dart';
import '../../fakes/in_memory_shop_repository.dart';

void main() {
  _walletTests();
  _persistenceTests();
  _controllerTests();
}

void _walletTests() {
  test(
    'Flocke unlocks at ten earned stars without automatically replacing Mia',
    () {
      final before = StarWallet(balance: 9);
      expect(before.isFlockeUnlocked, isFalse);
      expect(before.selectPet(PetKind.flocke), same(before));
      final unlocked = before.earn(1);
      expect(unlocked.isFlockeUnlocked, isTrue);
      expect(unlocked.selectedPet, PetKind.mia);
      expect(unlocked.selectPet(PetKind.flocke).selectedPet, PetKind.flocke);
      expect(
        () => StarWallet(balance: 9, selectedPet: PetKind.flocke),
        throwsArgumentError,
      );
    },
  );

  test(
    'spending, equipping and earning preserve Flocke; reset returns Mia',
    () {
      final selected = StarWallet(balance: 10).selectPet(PetKind.flocke);
      final bought = selected.buy(KittyAccessory.bow).wallet;
      expect(bought.balance, 7);
      expect(bought.totalEarned, 10);
      expect(bought.selectedPet, PetKind.flocke);
      expect(bought.equip(KittyAccessory.bow).selectedPet, PetKind.flocke);
      expect(
        bought
            .equip(KittyAccessory.bow)
            .unequip(KittyAccessory.bow)
            .selectedPet,
        PetKind.flocke,
      );
      expect(bought.earn(1).selectedPet, PetKind.flocke);
      expect(bought.selectPet(PetKind.mia).selectedPet, PetKind.mia);
      expect(bought.reset().selectedPet, PetKind.mia);
    },
  );

  test('selection affects equality and hash identity', () {
    final mia = StarWallet(balance: 10);
    final flocke = mia.selectPet(PetKind.flocke);
    expect(mia, isNot(flocke));
    expect({mia, flocke}, hasLength(2));
  });
}

void _persistenceTests() {
  test('v1 and v2 migrate to Mia and preserve existing inventory', () {
    for (final version in [1, 2]) {
      final wallet = SharedPreferencesShopRepository.decode(
        jsonEncode({
          'schemaVersion': version,
          'balance': 10,
          'totalEarned': 20,
          'owned': ['bow'],
          'equipped': ['bow'],
          'selectedPet': 'flocke',
        }),
      );
      expect(wallet.selectedPet, PetKind.mia);
      expect(wallet.balance, 10);
      expect(wallet.owned, {KittyAccessory.bow});
      expect(wallet.equipped, {KittyAccessory.bow});
      expect(wallet.totalEarned, version == 1 ? 13 : 20);
    }
  });

  test('v3 stores selected pet and sanitizes invalid or locked values', () {
    final selected = StarWallet(balance: 10).selectPet(PetKind.flocke);
    final encoded = SharedPreferencesShopRepository.encode(selected);
    expect(encoded['schemaVersion'], 3);
    expect(encoded['selectedPet'], 'flocke');
    expect(
      SharedPreferencesShopRepository.decode(jsonEncode(encoded)),
      selected,
    );
    for (final raw in [null, 'unknown', 42, true]) {
      final repaired = SharedPreferencesShopRepository.decode(
        jsonEncode({'schemaVersion': 3, 'balance': 10, 'selectedPet': raw}),
      );
      expect(repaired.selectedPet, PetKind.mia);
    }
    final locked = SharedPreferencesShopRepository.decode(
      jsonEncode({
        'schemaVersion': 3,
        'balance': 9,
        'totalEarned': 9,
        'selectedPet': 'flocke',
      }),
    );
    expect(locked.selectedPet, PetKind.mia);
  });

  test(
    'v3 round-trip writes selection atomically and future data is rejected',
    () async {
      final store = FakePreferencesStore();
      final repo = SharedPreferencesShopRepository(
        openStore: () async => store,
      );
      final wallet = StarWallet(balance: 10).selectPet(PetKind.flocke);
      await repo.save(wallet);
      expect(store.values.keys, [SharedPreferencesShopRepository.snapshotKey]);
      expect(await repo.load(), wallet);
      final newer = jsonEncode({'schemaVersion': 4, 'selectedPet': 'flocke'});
      store.values[SharedPreferencesShopRepository.snapshotKey] = newer;
      await expectLater(repo.load(), throwsA(isA<ShopNewerSchemaException>()));
      expect(store.values[SharedPreferencesShopRepository.snapshotKey], newer);
    },
  );
}

void _controllerTests() {
  test(
    'loading, locked selection and failed loads cannot modify the wallet',
    () async {
      final repo = InMemoryShopRepository(StarWallet(balance: 9));
      final controller = ShopController(repo);
      addTearDown(controller.dispose);
      expect(controller.selectPet(PetKind.flocke), isFalse);
      expect(controller.selectPet(PetKind.mia), isFalse);
      repo.loadException = const FormatException('storage');
      await controller.load();
      expect(controller.selectPet(PetKind.flocke), isFalse);
      expect(repo.saves, isEmpty);
      repo.loadException = null;
      await controller.load();
      expect(controller.selectPet(PetKind.flocke), isFalse);
      controller.earn(1);
      expect(controller.selectPet(PetKind.flocke), isTrue);
      await controller.flush();
      expect(repo.stored.selectedPet, PetKind.flocke);
      expect(controller.resetAll(), isTrue);
      await controller.flush();
      expect(repo.stored.selectedPet, PetKind.mia);
    },
  );

  test(
    'retry merges pre-load stars with stored selection exactly once',
    () async {
      final original = StarWallet(balance: 10).selectPet(PetKind.flocke);
      final repo = InMemoryShopRepository(original)
        ..loadGate = Completer<void>();
      final controller = ShopController(repo);
      addTearDown(controller.dispose);
      final loading = controller.load();
      controller.earn(2);
      expect(controller.selectPet(PetKind.mia), isFalse);
      repo.loadGate!.complete();
      await loading;
      await controller.flush();
      expect(controller.wallet.selectedPet, PetKind.flocke);
      expect(repo.stored.totalEarned, 12);
      await controller.retryPending();
      expect(repo.stored.totalEarned, 12);
    },
  );

  test(
    'a failed save retries the current selection and keeps earnings',
    () async {
      final repo = InMemoryShopRepository(StarWallet(balance: 10));
      final controller = ShopController(repo);
      addTearDown(controller.dispose);
      await controller.load();
      repo.saveException = const FormatException('storage');
      expect(controller.selectPet(PetKind.flocke), isTrue);
      await controller.flush();
      expect(controller.saveFailed, isTrue);
      controller.earn(1);
      repo.saveException = null;
      await controller.retryPending();
      expect(repo.stored.selectedPet, PetKind.flocke);
      expect(repo.stored.totalEarned, 11);
    },
  );
}
