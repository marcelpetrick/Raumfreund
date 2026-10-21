// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import '../domain/app_language.dart';
import '../domain/language_repository.dart';
import 'preferences_store.dart';
import 'shared_preferences_settings_repository.dart';

/// Stores the [AppLanguage] code under its own key in SharedPreferences.
///
/// The language is deliberately not part of the settings snapshot: it is
/// switched immediately, while the other settings wait for Save, so one
/// write must never overwrite the other (ADR 0006).
final class SharedPreferencesLanguageRepository implements LanguageRepository {
  /// Creates the repository; [openStore] defaults to the real
  /// SharedPreferences.
  SharedPreferencesLanguageRepository({
    Future<PreferencesStore> Function()? openStore,
  }) : _openStore = openStore ?? SharedPreferencesStore.open;

  /// Storage key of the language code.
  static const String languageKey = 'settings.language';

  final Future<PreferencesStore> Function() _openStore;
  Future<PreferencesStore>? _store;

  @override
  Future<AppLanguage> load() async {
    try {
      final store = await _storeOnce();
      return AppLanguage.fromCode(store.read(languageKey)) ??
          AppLanguage.defaultLanguage;
    } on Exception {
      // Storage unavailable: the app must still start, in German.
      return AppLanguage.defaultLanguage;
    }
  }

  @override
  Future<void> save(AppLanguage language) async {
    final PreferencesStore store;
    final bool ok;
    try {
      store = await _storeOnce();
      ok = await store.writeString(languageKey, language.code);
    } on Exception catch (error) {
      throw SettingsStorageException('writing $languageKey failed', error);
    }
    if (!ok) throw const SettingsStorageException('writing was rejected');
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
