// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:raumfreund/features/settings/infrastructure/preferences_store.dart';

/// In-memory [PreferencesStore] with injectable write failures.
final class FakePreferencesStore implements PreferencesStore {
  /// Creates a store with [initial] raw values.
  FakePreferencesStore([Map<String, Object?>? initial])
    : values = {...?initial};

  /// Raw stored values.
  final Map<String, Object?> values;

  /// Keys whose writes report `false`.
  final Set<String> rejectedKeys = {};

  /// Keys whose writes throw.
  final Set<String> throwingKeys = {};

  @override
  Object? read(String key) => values[key];

  @override
  Future<bool> writeInt(String key, int value) async => _write(key, value);

  @override
  Future<bool> writeBool(String key, {required bool value}) async =>
      _write(key, value);

  @override
  Future<bool> writeString(String key, String value) async =>
      _write(key, value);

  bool _write(String key, Object value) {
    if (throwingKeys.contains(key)) {
      throw const FormatException('disk full');
    }
    if (rejectedKeys.contains(key)) return false;
    values[key] = value;
    return true;
  }
}
