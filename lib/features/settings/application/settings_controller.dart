// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// Holds the current [AppSettings] for the UI: loads them once at startup
/// and saves edits, exposing loading/saving/error flags.
///
/// Until [load] has finished, [settings] are the defaults and [isLoading]
/// is true. Saves are serialized; a failed save keeps the previous settings.
final class SettingsController extends ChangeNotifier {
  /// Creates a controller backed by the given settings repository.
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = AppSettings.defaults;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isSaving = false;
  bool _saveFailed = false;
  bool _disposed = false;
  Future<void>? _loading;
  Future<void> _saveQueue = Future<void>.value();

  /// Current (last loaded or successfully saved) settings.
  AppSettings get settings => _settings;

  /// True until the first [load] has completed.
  bool get isLoading => _isLoading;

  /// Whether loading threw (defaults are used then).
  bool get loadFailed => _loadFailed;

  /// Whether a save is in progress.
  bool get isSaving => _isSaving;

  /// Whether the most recent save failed.
  bool get saveFailed => _saveFailed;

  /// Loads the stored settings. Repeated calls share the first load.
  Future<void> load() => _loading ??= _load();

  /// Persists [settings]; returns whether it worked. On failure
  /// [saveFailed] is set and [settings] stay unchanged.
  Future<bool> save(AppSettings settings) {
    final result = _saveQueue.then((_) => _save(settings));
    _saveQueue = result;
    return result;
  }

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

  Future<void> _load() async {
    try {
      _settings = await _repository.load();
    } on Exception {
      // The repository already falls back per field; this covers an
      // unexpected failure of the storage itself.
      _loadFailed = true;
    }
    _isLoading = false;
    _notify();
  }

  Future<bool> _save(AppSettings settings) async {
    _isSaving = true;
    _saveFailed = false;
    _notify();
    var ok = true;
    try {
      await _repository.save(settings);
      _settings = settings;
    } on Exception {
      ok = false;
      _saveFailed = true;
    }
    _isSaving = false;
    _notify();
    return ok;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
