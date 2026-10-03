// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'app_settings.dart';

/// Persistent storage of [AppSettings].
abstract interface class SettingsRepository {
  /// Loads validated settings. Invalid or missing stored values fall back to
  /// [AppSettings.defaults] per field; never throws for bad data.
  Future<AppSettings> load();

  /// Persists [settings]. Throws on storage failure.
  Future<void> save(AppSettings settings);
}
