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

/// Thrown by [SharedPreferencesShopRepository.load] when the stored wallet was
/// written by a newer app version and cannot be interpreted safely.
///
/// Distinct from corrupt data (decided policy: empty wallet): the data is
/// valid for a later release, so it must not be replaced. The shop controller
/// treats it like a failed load and never saves over it.
final class ShopNewerSchemaException extends ShopStorageException {
  /// Creates the exception for the found [version].
  const ShopNewerSchemaException(int version)
    : super('stored wallet has newer schema version $version');
}

/// Versioned, validating persistence of the [StarWallet] in
/// SharedPreferences, in its own `shop.` key namespace.
///
/// Balance and inventory belong together, so they are written as one JSON
/// snapshot under [snapshotKey] (atomic replace). The snapshot holds the
/// balance, the names of the owned and of the equipped items, and the
/// schema version. Nothing else is stored, and it never leaves the device.
///
/// Loading follows the settings policy for *bad data* and throws for
/// *unavailable or unreadable storage* and for *newer data*, so the caller
/// never mistakes those for an empty wallet and overwrites stored stars:
///
/// * Storage that cannot be opened or read: [ShopStorageException]. The
///   stored data may be perfectly fine.
/// * A *newer* schema version (e.g. after an app downgrade):
///   [ShopNewerSchemaException]. The stored data stays untouched.
/// * Every field is validated on its own: a missing, mistyped or negative
///   balance becomes 0; unknown item names are ignored; equipped items that
///   are not owned are dropped.
/// * Unreadable JSON and a missing, non-integer or too old version are
///   genuinely corrupt and load an empty wallet (decided policy).
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
    try {
      final store = await _storeOnce();
      return decode(store.read(snapshotKey));
    } on ShopStorageException {
      rethrow;
    } on Exception catch (error) {
      throw ShopStorageException('storage unavailable', error);
    }
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

  /// Builds a valid wallet from the raw stored value (see class comment);
  /// throws [ShopNewerSchemaException] for newer data.
  static StarWallet decode(Object? raw) {
    final data = _parse(raw);
    if (data == null) return StarWallet.empty();
    final version = data['schemaVersion'];
    if (version is int && version > schemaVersion) {
      throw ShopNewerSchemaException(version);
    }
    if (version is! int || version < 1) return StarWallet.empty();
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
