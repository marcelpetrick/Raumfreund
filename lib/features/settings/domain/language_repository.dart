// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'app_language.dart';

/// Persistent storage of the chosen [AppLanguage].
abstract interface class LanguageRepository {
  /// Loads the stored language, or [AppLanguage.defaultLanguage] when none
  /// or an unknown one is stored or the storage is unavailable. Never throws.
  Future<AppLanguage> load();

  /// Persists [language]. Throws on storage failure.
  Future<void> save(AppLanguage language);
}
