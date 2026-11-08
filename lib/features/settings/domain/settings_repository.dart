// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'app_settings.dart';

/// Persistent storage of [AppSettings].
abstract interface class SettingsRepository {
  /// Loads validated settings. Missing or invalid fields in a readable schema
  /// fall back to [AppSettings.defaults]; unreadable or unsupported data and
  /// storage failures throw, so callers can avoid overwriting unknown data.
  Future<AppSettings> load();

  /// Persists [settings]. Throws on storage failure.
  Future<void> save(AppSettings settings);
}
