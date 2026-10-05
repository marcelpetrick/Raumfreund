// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/infrastructure/shared_preferences_shop_repository.dart';

import '../../../fakes/fake_preferences_store.dart';

typedef Repo = SharedPreferencesShopRepository;

final StarWallet stored = StarWallet(
  balance: 50,
  owned: {KittyAccessory.bow},
  equipped: {KittyAccessory.bow},
);

Map<String, Object?> data(Map<String, Object?> snapshot) => {
  Repo.snapshotKey: jsonEncode(snapshot),
};

void main() {
  test('a failing first open never overwrites stored stars', () async {
    final store = FakePreferencesStore(data(Repo.encode(stored)));
    var opens = 0;
    final controller = ShopController(
      Repo(
        openStore: () async {
          if (opens++ == 0) throw Exception('storage busy');
          return store;
        },
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loadFailed, isTrue);
    controller.earn(1);
    await controller.flush();
    expect(Repo.decode(store.values[Repo.snapshotKey]), stored);

    await controller.retryPending();
    await controller.flush();
    expect(controller.loadFailed, isFalse);
    expect(controller.wallet.balance, 51);
    expect(controller.wallet.owned, {KittyAccessory.bow});
    expect(Repo.decode(store.values[Repo.snapshotKey]).balance, 51);
  });

  test('newer stored data is never overwritten', () async {
    final raw = data({'schemaVersion': 2, 'balance': 50});
    final store = FakePreferencesStore(raw);
    final controller = ShopController(Repo(openStore: () async => store));
    addTearDown(controller.dispose);
    await controller.load();
    controller.earn(1);
    await controller.retryPending();
    await controller.flush();
    expect(controller.loadFailed, isTrue);
    expect(controller.resetAll(), isFalse);
    expect(store.values, raw);
  });

  test('corrupt data loads an empty wallet that may be saved', () async {
    final store = FakePreferencesStore({Repo.snapshotKey: '{broken'});
    final controller = ShopController(Repo(openStore: () async => store));
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loadFailed, isFalse);
    controller.earn(1);
    await controller.flush();
    expect(Repo.decode(store.values[Repo.snapshotKey]).balance, 1);
  });
}
