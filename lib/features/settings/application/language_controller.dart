// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';

import '../domain/app_language.dart';
import '../domain/language_repository.dart';

/// Holds the UI language: switches it live and persists it in the
/// background.
///
/// [select] changes [language] at once, so the whole app redraws in the new
/// language before the write has finished. Writes are serialized, so the
/// last choice is the one stored. A failed write keeps the chosen language
/// for this run; the next start uses the previously stored one.
final class LanguageController extends ChangeNotifier
    implements ValueListenable<AppLanguage> {
  /// Creates a controller backed by [_repository].
  LanguageController(this._repository);

  final LanguageRepository _repository;

  AppLanguage _language = AppLanguage.defaultLanguage;
  bool _chosen = false;
  bool _disposed = false;
  Future<void>? _loading;
  Future<void> _saveQueue = Future<void>.value();

  /// Current language.
  AppLanguage get language => _language;

  @override
  AppLanguage get value => _language;

  /// Loads the stored language. Repeated calls share the first load.
  Future<void> load() => _loading ??= _load();

  /// Switches to [language] immediately and stores it; completes with
  /// whether storing worked.
  Future<bool> select(AppLanguage language) {
    _chosen = true;
    if (language != _language) {
      _language = language;
      _notify();
    }
    final result = _saveQueue.then((_) => _save(language));
    _saveQueue = result;
    return result;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    final stored = await _repository.load();
    // A choice made while loading wins over the older stored value.
    if (_chosen || stored == _language) return;
    _language = stored;
    _notify();
  }

  Future<bool> _save(AppLanguage language) async {
    try {
      await _repository.save(language);
      return true;
    } on Exception {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
