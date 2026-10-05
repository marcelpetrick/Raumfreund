// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/shop/domain/shop_repository.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

/// [ShopRepository] keeping the wallet in memory with injectable failures.
final class InMemoryShopRepository implements ShopRepository {
  /// Creates a repository holding [initial] (empty if omitted).
  InMemoryShopRepository([StarWallet? initial])
    : stored = initial ?? StarWallet.empty();

  /// Currently stored wallet.
  StarWallet stored;

  /// When set, [save] throws it.
  Exception? saveException;

  /// When set, [save] throws it (an unexpected programming error).
  Error? saveError;

  /// When set, [load] throws it.
  Exception? loadException;

  /// When set, [load] throws it (an unexpected programming error).
  Error? loadError;

  /// When set, [load] waits for this completer first.
  Completer<void>? loadGate;

  /// When set, [save] waits for this completer first.
  Completer<void>? saveGate;

  /// Wallets passed to [save], in call order.
  final List<StarWallet> saves = [];

  @override
  Future<StarWallet> load() async {
    await loadGate?.future;
    final exception = loadException;
    if (exception != null) throw exception;
    final error = loadError;
    if (error != null) throw error;
    return stored;
  }

  @override
  Future<void> save(StarWallet wallet) async {
    saves.add(wallet);
    await saveGate?.future;
    final exception = saveException;
    if (exception != null) throw exception;
    final error = saveError;
    if (error != null) throw error;
    stored = wallet;
  }
}
