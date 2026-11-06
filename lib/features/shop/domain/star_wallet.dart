// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'kitty_accessory.dart';
import 'pet_kind.dart';

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
/// every equipped item is owned, and the selected pet is unlocked. All
/// operations return new values, so
/// the wallet is trivially safe to share and to compare in tests. Pure
/// domain code: no Flutter, no storage, no clock.
final class StarWallet {
  /// Creates a wallet; throws [ArgumentError] if an invariant is violated.
  StarWallet({
    this.balance = 0,
    int? totalEarned,
    this.selectedPet = PetKind.mia,
    Set<KittyAccessory> owned = const {},
    Set<KittyAccessory> equipped = const {},
  }) : totalEarned = totalEarned ?? _reconstructedTotal(balance, owned),
       owned = Set.unmodifiable(owned),
       equipped = Set.unmodifiable(equipped) {
    if (balance < 0) {
      throw ArgumentError.value(balance, 'balance', 'must not be negative');
    }
    if (!owned.containsAll(equipped)) {
      throw ArgumentError.value(equipped, 'equipped', 'must be owned');
    }
    if (this.totalEarned < balance) {
      throw ArgumentError.value(
        totalEarned,
        'totalEarned',
        'must cover balance',
      );
    }
    if (selectedPet == PetKind.flocke && !isFlockeUnlocked) {
      throw ArgumentError.value(selectedPet, 'selectedPet', 'is locked');
    }
  }

  /// A wallet without stars and items.
  factory StarWallet.empty() => StarWallet();

  /// Repairing factory for persisted data: a negative balance becomes 0
  /// equipped items that are not owned are dropped, and a locked selected
  /// pet is replaced by Mia.
  factory StarWallet.sanitized({
    required int balance,
    required Set<KittyAccessory> owned,
    required Set<KittyAccessory> equipped,
    int? totalEarned,
    PetKind selectedPet = PetKind.mia,
  }) {
    final safeBalance = balance < 0 ? 0 : balance;
    final effectiveTotal = totalEarned == null
        ? _reconstructedTotal(safeBalance, owned)
        : totalEarned < safeBalance
        ? safeBalance
        : totalEarned;
    return StarWallet(
      balance: safeBalance,
      owned: owned,
      equipped: equipped.intersection(owned),
      totalEarned: effectiveTotal,
      selectedPet:
          selectedPet == PetKind.flocke &&
              effectiveTotal ~/ starsPerLevel + 1 < flockeUnlockLevel
          ? PetKind.mia
          : selectedPet,
    );
  }

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

  /// Number of earned stars needed to advance each level.
  static const int starsPerLevel = 5;

  /// Flocke becomes available after ten earned stars.
  static const int flockeUnlockLevel = 3;

  /// Companion shown on the monitor; Flocke must be unlocked first.
  final PetKind selectedPet;

  /// Stars available to spend.
  final int balance;

  /// Bought items.
  final Set<KittyAccessory> owned;

  /// Items Mia currently wears; always a subset of [owned].
  final Set<KittyAccessory> equipped;

  /// Stars earned since the last reset, including those spent on items.
  ///
  /// When omitted on construction, the total is reconstructed from the
  /// balance and item prices for migration from the original wallet format.
  final int totalEarned;

  static int _reconstructedTotal(int balance, Set<KittyAccessory> owned) =>
      owned.fold(balance, (total, item) => total + item.price);

  /// Mia starts at level one and advances for every [starsPerLevel] stars.
  int get level => totalEarned ~/ starsPerLevel + 1;

  /// Whether Flocke may be selected without spending stars.
  bool get isFlockeUnlocked => level >= flockeUnlockLevel;

  /// Earned stars in the current level, from zero to [starsPerLevel] minus one.
  int get starsTowardNextLevel => totalEarned % starsPerLevel;

  /// Adds [stars] (> 0) to the balance.
  StarWallet earn(int stars) {
    if (stars <= 0) {
      throw ArgumentError.value(stars, 'stars', 'must be positive');
    }
    return StarWallet(
      balance: balance + stars,
      totalEarned: totalEarned + stars,
      selectedPet: selectedPet,
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
        totalEarned: totalEarned,
        selectedPet: selectedPet,
        owned: {...owned, item},
        equipped: equipped,
      ),
    );
  }

  /// Puts an owned [item] on; returns this wallet if it is not owned.
  StarWallet equip(KittyAccessory item) => owned.contains(item)
      ? StarWallet(
          balance: balance,
          totalEarned: totalEarned,
          selectedPet: selectedPet,
          owned: owned,
          equipped: {...equipped, item},
        )
      : this;

  /// Takes [item] off (free); returns this wallet if it is not worn.
  StarWallet unequip(KittyAccessory item) => equipped.contains(item)
      ? StarWallet(
          balance: balance,
          totalEarned: totalEarned,
          selectedPet: selectedPet,
          owned: owned,
          equipped: equipped.difference({item}),
        )
      : this;

  /// Selects an unlocked companion; a locked or unchanged selection is a no-op.
  StarWallet selectPet(PetKind pet) {
    if (pet == selectedPet || (pet == PetKind.flocke && !isFlockeUnlocked)) {
      return this;
    }
    return StarWallet(
      balance: balance,
      totalEarned: totalEarned,
      owned: owned,
      equipped: equipped,
      selectedPet: pet,
    );
  }

  /// Teacher reset: no stars, no items.
  StarWallet reset() => StarWallet.empty();

  @override
  bool operator ==(Object other) =>
      other is StarWallet &&
      other.balance == balance &&
      other.totalEarned == totalEarned &&
      other.selectedPet == selectedPet &&
      other.owned.length == owned.length &&
      other.owned.containsAll(owned) &&
      other.equipped.length == equipped.length &&
      other.equipped.containsAll(equipped);

  @override
  int get hashCode => Object.hash(
    balance,
    totalEarned,
    selectedPet,
    Object.hashAllUnordered(owned),
    Object.hashAllUnordered(equipped),
  );

  @override
  String toString() =>
      'StarWallet($balance stars, owned: ${owned.map((e) => e.name)}, '
      'equipped: ${equipped.map((e) => e.name)})';
}
