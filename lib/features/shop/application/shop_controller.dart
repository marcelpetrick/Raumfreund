// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';

import '../domain/kitty_accessory.dart';
import '../domain/shop_repository.dart';
import '../domain/star_wallet.dart';

/// Holds the child's [StarWallet] for the UI and keeps it persisted.
///
/// Operations change the wallet immediately (so rapid taps and earned
/// stars always build on the latest state) and are then written in the
/// background. Saves are serialized and coalesced: each one writes the
/// newest wallet. A failed save never throws; it sets [saveFailed], keeps
/// the in-memory wallet (a star earned must not vanish from the screen) and
/// is retried together with the next change. Use [flush] to await pending
/// saves.
///
/// Until [load] has succeeded, [wallet] only holds the stars earned so far
/// and every other change is refused ([PurchaseFailure.notReady] / false),
/// because it would act on data the child has not seen yet. Nothing is
/// saved before that: a failed [load] (storage unavailable, [loadFailed])
/// must never lead to stored stars being overwritten. Stars keep being
/// earned in memory; a later successful [load] merges them into the stored
/// wallet and saves once. ([isLoading] is true only until the first attempt
/// has finished.)
final class ShopController extends ChangeNotifier {
  /// Creates a controller backed by [_repository].
  ShopController(this._repository);

  final ShopRepository _repository;

  StarWallet _wallet = StarWallet.empty();
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isSaving = false;
  bool _saveFailed = false;
  bool _disposed = false;
  bool _loaded = false;
  int _unsavedStars = 0;
  int _revision = 0;
  int _savedRevision = 0;
  Future<void>? _loading;
  Future<void> _saveQueue = Future<void>.value();

  /// Current stars and inventory.
  StarWallet get wallet => _wallet;

  /// True until the first [load] has completed.
  bool get isLoading => _isLoading;

  /// Whether loading threw (an empty wallet is used then).
  bool get loadFailed => _loadFailed;

  /// Whether a save is in progress.
  bool get isSaving => _isSaving;

  /// Whether the most recent save failed.
  bool get saveFailed => _saveFailed;

  /// Loads the stored wallet. Repeated calls share the first load.
  Future<void> load() => _loading ??= _load();

  /// Adds [stars] (> 0), e.g. one quiet-minute star from the monitor.
  void earn(int stars) {
    final next = _wallet.earn(stars);
    if (!_loaded) _unsavedStars += stars;
    _apply(next);
  }

  /// Buys [item]; the result says why it failed, if it did.
  PurchaseResult buy(KittyAccessory item) {
    if (!_loaded) {
      return PurchaseResult.failed(_wallet, PurchaseFailure.notReady);
    }
    final result = _wallet.buy(item);
    if (result.isSuccess) _apply(result.wallet);
    return result;
  }

  /// Puts an owned [item] on or takes it off. Returns false if it is not
  /// owned (or the wallet is not loaded).
  bool toggleEquipped(KittyAccessory item) {
    if (!_loaded || !_wallet.owned.contains(item)) return false;
    _apply(
      _wallet.equipped.contains(item)
          ? _wallet.unequip(item)
          : _wallet.equip(item),
    );
    return true;
  }

  /// Teacher reset: clears stars and items. Returns false while loading.
  bool resetAll() {
    if (!_loaded) return false;
    _apply(_wallet.reset());
    return true;
  }

  /// Completes when all pending saves have finished.
  Future<void> flush() => _saveQueue;

  /// Hides a shown save error.
  void clearSaveError() {
    if (!_saveFailed) return;
    _saveFailed = false;
    _notify();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  void _apply(StarWallet wallet) {
    _wallet = wallet;
    _notify();
    if (_loaded) _scheduleSave();
  }

  Future<void> _load() async {
    try {
      final loaded = await _repository.load();
      _wallet = _unsavedStars > 0 ? loaded.earn(_unsavedStars) : loaded;
      _loaded = true;
      _loadFailed = false;
      if (_unsavedStars > 0) _scheduleSave();
      _unsavedStars = 0;
    } on Exception {
      // The repository already falls back for bad data; this covers an
      // unexpected failure of the storage itself. Allow a retry.
      _loadFailed = true;
      _loading = null;
    }
    _isLoading = false;
    _notify();
  }

  void _scheduleSave() {
    _revision++;
    _saveQueue = _saveQueue.then((_) => _save());
  }

  Future<void> _save() async {
    final revision = _revision;
    if (revision == _savedRevision) return; // a later save covered it
    _isSaving = true;
    _notify();
    try {
      await _repository.save(_wallet);
      _savedRevision = revision;
      _saveFailed = false;
    } on Exception {
      _saveFailed = true;
    }
    _isSaving = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
