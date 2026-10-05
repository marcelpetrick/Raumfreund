// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

const bow = KittyAccessory.bow;
const hat = KittyAccessory.hat;

void main() {
  constructionTests();
  operationTests();
  equalityTests();
}

void constructionTests() {
  group('construction', () {
    test('empty wallet', () {
      final wallet = StarWallet.empty();
      expect(wallet.balance, 0);
      expect(wallet.owned, isEmpty);
      expect(wallet.equipped, isEmpty);
    });

    test('rejects a negative balance', () {
      expect(() => StarWallet(balance: -1), throwsArgumentError);
    });

    test('rejects equipped items that are not owned', () {
      expect(
        () => StarWallet(owned: {bow}, equipped: {hat}),
        throwsArgumentError,
      );
    });

    test('sets are unmodifiable and copied', () {
      final source = {bow};
      final wallet = StarWallet(owned: source);
      source.add(hat);
      expect(wallet.owned, {bow});
      expect(() => wallet.owned.add(hat), throwsUnsupportedError);
    });

    test('tryCreate validates', () {
      expect(
        StarWallet.tryCreate(balance: -1, owned: {}, equipped: {}),
        isNull,
      );
      expect(
        StarWallet.tryCreate(balance: 1, owned: {}, equipped: {bow}),
        isNull,
      );
      expect(
        StarWallet.tryCreate(balance: 2, owned: {bow}, equipped: {bow}),
        StarWallet(balance: 2, owned: {bow}, equipped: {bow}),
      );
    });

    test('sanitized repairs', () {
      final wallet = StarWallet.sanitized(
        balance: -5,
        owned: {bow},
        equipped: {bow, hat},
      );
      expect(wallet, StarWallet(owned: {bow}, equipped: {bow}));
    });
  });
}

void operationTests() {
  group('operations', () {
    test('earn adds stars and rejects non-positive amounts', () {
      expect(StarWallet().earn(2).earn(3).balance, 5);
      expect(() => StarWallet().earn(0), throwsArgumentError);
      expect(() => StarWallet().earn(-1), throwsArgumentError);
    });

    test('buy pays the price and does not equip', () {
      final result = StarWallet(balance: 4).buy(bow);
      expect(result.isSuccess, isTrue);
      expect(result.failure, isNull);
      expect(result.wallet.balance, 1);
      expect(result.wallet.owned, {bow});
      expect(result.wallet.equipped, isEmpty);
    });

    test('buy with exactly the price works', () {
      expect(StarWallet(balance: 3).buy(bow).wallet.balance, 0);
    });

    test('buy fails without enough stars', () {
      final wallet = StarWallet(balance: 2);
      final result = wallet.buy(bow);
      expect(result.failure, PurchaseFailure.notEnoughStars);
      expect(result.isSuccess, isFalse);
      expect(result.wallet, wallet);
    });

    test('buy fails for an owned item, even if affordable', () {
      final wallet = StarWallet(balance: 50, owned: {bow});
      final result = wallet.buy(bow);
      expect(result.failure, PurchaseFailure.alreadyOwned);
      expect(result.wallet, wallet);
    });

    test('equip and unequip only work for owned items', () {
      final wallet = StarWallet(owned: {bow});
      expect(wallet.equip(hat), same(wallet));
      final worn = wallet.equip(bow);
      expect(worn.equipped, {bow});
      expect(worn.unequip(bow).equipped, isEmpty);
      expect(wallet.unequip(bow), same(wallet));
    });

    test('reset clears everything', () {
      final wallet = StarWallet(balance: 9, owned: {bow}, equipped: {bow});
      expect(wallet.reset(), StarWallet.empty());
    });
  });
}

void equalityTests() {
  group('equality', () {
    test('compares balance and both sets regardless of order', () {
      final a = StarWallet(balance: 1, owned: {bow, hat}, equipped: {hat});
      final b = StarWallet(balance: 1, owned: {hat, bow}, equipped: {hat});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(StarWallet(balance: 2, owned: {bow, hat})));
      expect(a, isNot(StarWallet(balance: 1, owned: {bow, hat})));
      expect(a, isNot(StarWallet(balance: 1, owned: {bow}, equipped: {bow})));
      expect(a == Object(), isFalse);
    });

    test('toString names the contents', () {
      expect(
        StarWallet(balance: 1, owned: {bow}, equipped: {bow}).toString(),
        'StarWallet(1 stars, owned: (bow), equipped: (bow))',
      );
    });
  });
}
