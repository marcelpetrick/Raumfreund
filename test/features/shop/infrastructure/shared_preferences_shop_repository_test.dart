// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/settings/infrastructure/preferences_store.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/infrastructure/shared_preferences_shop_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_preferences_store.dart';

typedef Repo = SharedPreferencesShopRepository;

Future<StarWallet> loadRaw(Object? raw) =>
    Repo(openStore: () async => FakePreferencesStore({Repo.snapshotKey: raw}))
        .load();

String snapshot(Map<String, Object?> data) => jsonEncode(data);

final StarWallet sample = StarWallet(
  balance: 7,
  owned: {KittyAccessory.bow, KittyAccessory.hat},
  equipped: {KittyAccessory.hat},
);

void main() {
  loadTests();
  saveTests();
  test('works on top of real SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = Repo();
    expect(await repo.load(), StarWallet.empty());
    await repo.save(sample);
    final again = Repo(openStore: SharedPreferencesStore.open);
    expect(await again.load(), sample);
  });
}

void loadTests() {
  group('load', () {
    test('empty storage gives an empty wallet', () async {
      final repo = Repo(openStore: () async => FakePreferencesStore());
      expect(await repo.load(), StarWallet.empty());
    });

    test('a saved wallet round-trips', () async {
      final store = FakePreferencesStore();
      final repo = Repo(openStore: () async => store);
      await repo.save(sample);
      expect(store.values.keys, [Repo.snapshotKey]);
      expect(await repo.load(), sample);
    });

    test('negative or mistyped balance becomes 0, items stay', () async {
      for (final balance in [-3, 'x', 1.5, null]) {
        final wallet = await loadRaw(
          snapshot({
            'schemaVersion': 1,
            'balance': balance,
            'owned': ['bow'],
            'equipped': <String>[],
          }),
        );
        expect(wallet, StarWallet(owned: {KittyAccessory.bow}));
      }
    });

    test('unknown, mistyped and duplicate items are ignored', () async {
      final wallet = await loadRaw(
        snapshot({
          'schemaVersion': 1,
          'balance': 2,
          'owned': ['bow', 'dragon', 5, 'bow'],
          'equipped': 'scarf',
        }),
      );
      expect(wallet, StarWallet(balance: 2, owned: {KittyAccessory.bow}));
    });

    test('equipped but not owned is dropped', () async {
      final wallet = await loadRaw(
        snapshot({
          'schemaVersion': 1,
          'balance': 2,
          'owned': ['bow'],
          'equipped': ['bow', 'hat'],
        }),
      );
      expect(wallet.equipped, {KittyAccessory.bow});
    });

    test('corrupt data gives an empty wallet', () async {
      for (final raw in ['{not json', '[1]', '"x"', 42, true]) {
        expect(await loadRaw(raw), StarWallet.empty());
      }
    });

    test(
      'missing, mistyped, too old or newer version gives defaults',
      () async {
        for (final version in [null, '1', 0, 2, 99]) {
          final wallet = await loadRaw(
            snapshot({'schemaVersion': version, 'balance': 5}),
          );
          expect(wallet, StarWallet.empty());
        }
      },
    );

    test('unavailable storage gives an empty wallet and retries', () async {
      var calls = 0;
      final store = FakePreferencesStore({
        Repo.snapshotKey: jsonEncode(Repo.encode(sample)),
      });
      final repo = Repo(
        openStore: () async {
          if (calls++ == 0) throw Exception('no storage');
          return store;
        },
      );
      expect(await repo.load(), StarWallet.empty());
      expect(await repo.load(), sample);
    });
  });
}

void saveTests() {
  group('save', () {
    test('a rejected write throws', () async {
      final store = FakePreferencesStore()..rejectedKeys.add(Repo.snapshotKey);
      final repo = Repo(openStore: () async => store);
      await expectLater(
        repo.save(sample),
        throwsA(isA<ShopStorageException>()),
      );
    });

    test('a throwing write is wrapped', () async {
      final store = FakePreferencesStore()..throwingKeys.add(Repo.snapshotKey);
      final repo = Repo(openStore: () async => store);
      await expectLater(
        repo.save(sample),
        throwsA(
          isA<ShopStorageException>().having(
            (e) => e.toString(),
            'toString',
            contains('writing the wallet failed'),
          ),
        ),
      );
    });

    test('unavailable storage throws', () async {
      final repo = Repo(openStore: () async => throw Exception('no'));
      await expectLater(
        repo.save(sample),
        throwsA(
          isA<ShopStorageException>().having(
            (e) => e.cause,
            'cause',
            isA<Exception>(),
          ),
        ),
      );
    });

    test('a newer snapshot stays untouched by load', () async {
      final raw = snapshot({'schemaVersion': 9, 'balance': 5});
      final store = FakePreferencesStore({Repo.snapshotKey: raw});
      await Repo(openStore: () async => store).load();
      expect(store.values[Repo.snapshotKey], raw);
    });
  });
}
