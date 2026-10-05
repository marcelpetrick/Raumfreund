// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:convert';

import '../../settings/infrastructure/preferences_store.dart';
import '../domain/kitty_accessory.dart';
import '../domain/shop_repository.dart';
import '../domain/star_wallet.dart';

/// Thrown by [SharedPreferencesShopRepository.save] when the wallet could
/// not be stored.
final class ShopStorageException implements Exception {
  /// Creates the exception.
  const ShopStorageException(this.message, [this.cause]);

  /// What failed (no user data).
  final String message;

  /// Underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'ShopStorageException: $message';
}

/// Versioned, validating persistence of the [StarWallet] in
/// SharedPreferences, in its own `shop.` key namespace.
///
/// Balance and inventory belong together, so they are written as one JSON
/// snapshot under [snapshotKey] (atomic replace). The snapshot holds the
/// balance, the names of the owned and of the equipped items, and the
/// schema version. Nothing else is stored, and it never leaves the device.
///
/// Loading never throws and follows the settings policy:
///
/// * Every field is validated on its own: a missing, mistyped or negative
///   balance becomes 0; unknown item names are ignored; equipped items that
///   are not owned are dropped.
/// * Unreadable JSON, a missing or non-integer version and a *newer* version
///   (e.g. after an app downgrade) cannot be interpreted safely and load an
///   empty wallet. The stored data stays untouched until the next save.
final class SharedPreferencesShopRepository implements ShopRepository {
  /// Creates the repository; [openStore] defaults to the real
  /// SharedPreferences.
  SharedPreferencesShopRepository({
    Future<PreferencesStore> Function()? openStore,
  }) : _openStore = openStore ?? SharedPreferencesStore.open;

  /// Current schema version written by [save].
  static const int schemaVersion = 1;

  /// Storage key of the snapshot.
  static const String snapshotKey = 'shop.snapshot';

  final Future<PreferencesStore> Function() _openStore;
  Future<PreferencesStore>? _store;

  @override
  Future<StarWallet> load() async {
    final PreferencesStore store;
    try {
      store = await _storeOnce();
    } on Exception {
      // Storage unavailable: the app must still work, with an empty wallet.
      return StarWallet.empty();
    }
    return decode(store.read(snapshotKey));
  }

  @override
  Future<void> save(StarWallet wallet) async {
    final PreferencesStore store;
    try {
      store = await _storeOnce();
    } on Exception catch (error) {
      throw ShopStorageException('storage unavailable', error);
    }
    final bool ok;
    try {
      ok = await store.writeString(snapshotKey, jsonEncode(encode(wallet)));
    } on Exception catch (error) {
      throw ShopStorageException('writing the wallet failed', error);
    }
    if (!ok) {
      throw const ShopStorageException('writing the wallet was rejected');
    }
  }

  /// The JSON map written by [save].
  static Map<String, Object> encode(StarWallet wallet) => {
    'schemaVersion': schemaVersion,
    'balance': wallet.balance,
    'owned': [for (final item in wallet.owned) item.name],
    'equipped': [for (final item in wallet.equipped) item.name],
  };

  /// Builds a valid wallet from the raw stored value (see class comment).
  static StarWallet decode(Object? raw) {
    final data = _parse(raw);
    if (data == null) return StarWallet.empty();
    final version = data['schemaVersion'];
    if (version is! int || version > schemaVersion || version < 1) {
      return StarWallet.empty();
    }
    final balance = data['balance'];
    return StarWallet.sanitized(
      balance: balance is int ? balance : 0,
      owned: _items(data['owned']),
      equipped: _items(data['equipped']),
    );
  }

  static Map<String, dynamic>? _parse(Object? raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Set<KittyAccessory> _items(Object? raw) {
    if (raw is! List<Object?>) return {};
    final byName = {for (final item in KittyAccessory.values) item.name: item};
    return {for (final name in raw) ?byName[name]};
  }

  Future<PreferencesStore> _storeOnce() async {
    final pending = _store ??= _openStore();
    try {
      return await pending;
    } on Exception {
      _store = null; // allow a retry on the next call
      rethrow;
    }
  }
}
