// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'star_wallet.dart';

/// Persistent storage of the [StarWallet].
abstract interface class ShopRepository {
  /// Loads a valid wallet. Missing, corrupt or too new data falls back
  /// to an empty wallet (per field where possible); never throws for bad
  /// data.
  Future<StarWallet> load();

  /// Persists [wallet]. Throws on storage failure.
  Future<void> save(StarWallet wallet);
}
