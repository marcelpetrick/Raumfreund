// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/domain/settings_repository.dart';

/// [SettingsRepository] keeping settings in memory.
final class InMemorySettingsRepository implements SettingsRepository {
  /// Creates a repository holding [initial] (defaults if omitted).
  InMemorySettingsRepository([AppSettings? initial])
    : stored = initial ?? AppSettings.defaults;

  /// Currently stored settings.
  AppSettings stored;

  /// When set, [save] throws it.
  Exception? saveException;

  /// When set, [load] throws it.
  Exception? loadException;

  /// When set, [load] and [save] wait for this completer first.
  Completer<void>? gate;

  /// Number of [save] calls.
  int saveCalls = 0;

  @override
  Future<AppSettings> load() async {
    await gate?.future;
    final exception = loadException;
    if (exception != null) throw exception;
    return stored;
  }

  @override
  Future<void> save(AppSettings settings) async {
    saveCalls++;
    await gate?.future;
    final exception = saveException;
    if (exception != null) throw exception;
    stored = settings;
  }
}
