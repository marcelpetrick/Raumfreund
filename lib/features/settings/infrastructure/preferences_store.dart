// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value storage used by the settings repository.
///
/// Kept this narrow so the repository's validation, migration and error
/// handling can be tested against a fake (including writes that report
/// failure), independent of the shared_preferences plugin.
abstract interface class PreferencesStore {
  /// Raw stored value of [key] (any type) or null if absent.
  Object? read(String key);

  /// Writes an int; returns false if the platform rejected the write.
  Future<bool> writeInt(String key, int value);

  /// Writes a bool; returns false if the platform rejected the write.
  Future<bool> writeBool(String key, {required bool value});

  /// Writes a string; returns false if the platform rejected the write.
  Future<bool> writeString(String key, String value);
}

/// [PreferencesStore] backed by Android SharedPreferences.
final class SharedPreferencesStore implements PreferencesStore {
  /// Wraps an opened [SharedPreferences] instance.
  SharedPreferencesStore(this._preferences);

  /// Opens the app's SharedPreferences.
  static Future<PreferencesStore> open() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  final SharedPreferences _preferences;

  @override
  Object? read(String key) => _preferences.get(key);

  @override
  Future<bool> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  @override
  Future<bool> writeBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);

  @override
  Future<bool> writeString(String key, String value) =>
      _preferences.setString(key, value);
}
