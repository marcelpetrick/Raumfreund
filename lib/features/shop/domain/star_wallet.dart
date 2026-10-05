// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'kitty_accessory.dart';

/// Why [StarWallet.buy] did not buy an item.
enum PurchaseFailure {
  /// The item is already in the inventory; purchases are one-time.
  alreadyOwned,

  /// The balance is lower than the price.
  notEnoughStars,

  /// The wallet is not loaded yet (reported by the shop controller only).
  notReady,
}

/// Result of [StarWallet.buy]: the new wallet, or the reason it failed.
final class PurchaseResult {
  const PurchaseResult._(this.wallet, this.failure);

  /// A successful purchase leading to [wallet].
  const PurchaseResult.bought(StarWallet wallet) : this._(wallet, null);

  /// A refused purchase; [wallet] is the unchanged wallet.
  const PurchaseResult.failed(StarWallet wallet, PurchaseFailure failure)
    : this._(wallet, failure);

  /// Wallet after the operation (unchanged on failure).
  final StarWallet wallet;

  /// Reason of the failure, null on success.
  final PurchaseFailure? failure;

  /// Whether the item was bought.
  bool get isSuccess => failure == null;
}

/// Immutable stars balance plus inventory of the child's shop.
///
/// Invariants (enforced in the constructor): the balance is not negative
/// and every equipped item is owned. All operations return new values, so
/// the wallet is trivially safe to share and to compare in tests. Pure
/// domain code: no Flutter, no storage, no clock.
final class StarWallet {
  /// Creates a wallet; throws [ArgumentError] if an invariant is violated.
  StarWallet({
    this.balance = 0,
    Set<KittyAccessory> owned = const {},
    Set<KittyAccessory> equipped = const {},
  }) : owned = Set.unmodifiable(owned),
       equipped = Set.unmodifiable(equipped) {
    if (balance < 0) {
      throw ArgumentError.value(balance, 'balance', 'must not be negative');
    }
    if (!owned.containsAll(equipped)) {
      throw ArgumentError.value(equipped, 'equipped', 'must be owned');
    }
  }

  /// A wallet without stars and items.
  factory StarWallet.empty() => StarWallet();

  /// Repairing factory for persisted data: a negative balance becomes 0
  /// and equipped items that are not owned are dropped.
  factory StarWallet.sanitized({
    required int balance,
    required Set<KittyAccessory> owned,
    required Set<KittyAccessory> equipped,
  }) => StarWallet(
    balance: balance < 0 ? 0 : balance,
    owned: owned,
    equipped: equipped.intersection(owned),
  );

  /// Validating factory for persisted data: null if an invariant is
  /// violated.
  static StarWallet? tryCreate({
    required int balance,
    required Set<KittyAccessory> owned,
    required Set<KittyAccessory> equipped,
  }) {
    if (balance < 0 || !owned.containsAll(equipped)) return null;
    return StarWallet(balance: balance, owned: owned, equipped: equipped);
  }

  /// Stars available to spend.
  final int balance;

  /// Bought items.
  final Set<KittyAccessory> owned;

  /// Items Mia currently wears; always a subset of [owned].
  final Set<KittyAccessory> equipped;

  /// Adds [stars] (> 0) to the balance.
  StarWallet earn(int stars) {
    if (stars <= 0) {
      throw ArgumentError.value(stars, 'stars', 'must be positive');
    }
    return StarWallet(
      balance: balance + stars,
      owned: owned,
      equipped: equipped,
    );
  }

  /// Buys [item] for its price. Bought items are not equipped
  /// automatically.
  PurchaseResult buy(KittyAccessory item) {
    if (owned.contains(item)) {
      return PurchaseResult.failed(this, PurchaseFailure.alreadyOwned);
    }
    if (balance < item.price) {
      return PurchaseResult.failed(this, PurchaseFailure.notEnoughStars);
    }
    return PurchaseResult.bought(
      StarWallet(
        balance: balance - item.price,
        owned: {...owned, item},
        equipped: equipped,
      ),
    );
  }

  /// Puts an owned [item] on; returns this wallet if it is not owned.
  StarWallet equip(KittyAccessory item) => owned.contains(item)
      ? StarWallet(
          balance: balance,
          owned: owned,
          equipped: {...equipped, item},
        )
      : this;

  /// Takes [item] off (free); returns this wallet if it is not worn.
  StarWallet unequip(KittyAccessory item) => equipped.contains(item)
      ? StarWallet(
          balance: balance,
          owned: owned,
          equipped: equipped.difference({item}),
        )
      : this;

  /// Teacher reset: no stars, no items.
  StarWallet reset() => StarWallet.empty();

  @override
  bool operator ==(Object other) =>
      other is StarWallet &&
      other.balance == balance &&
      other.owned.length == owned.length &&
      other.owned.containsAll(owned) &&
      other.equipped.length == equipped.length &&
      other.equipped.containsAll(equipped);

  @override
  int get hashCode => Object.hash(
    balance,
    Object.hashAllUnordered(owned),
    Object.hashAllUnordered(equipped),
  );

  @override
  String toString() =>
      'StarWallet($balance stars, owned: ${owned.map((e) => e.name)}, '
      'equipped: ${equipped.map((e) => e.name)})';
}
