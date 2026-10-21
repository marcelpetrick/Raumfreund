// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/features/settings/domain/language_repository.dart';

/// [LanguageRepository] keeping the language in memory.
final class InMemoryLanguageRepository implements LanguageRepository {
  /// Creates a repository holding [stored].
  InMemoryLanguageRepository([this.stored = AppLanguage.defaultLanguage]);

  /// Currently stored language.
  AppLanguage stored;

  /// When set, [save] throws it.
  Exception? saveException;

  /// When set, [load] waits for it first.
  Completer<void>? loadGate;

  /// When set, [save] waits for it first.
  Completer<void>? saveGate;

  /// Languages passed to [save], in call order.
  final List<AppLanguage> saved = [];

  @override
  Future<AppLanguage> load() async {
    await loadGate?.future;
    return stored;
  }

  @override
  Future<void> save(AppLanguage language) async {
    saved.add(language);
    await saveGate?.future;
    final exception = saveException;
    if (exception != null) throw exception;
    stored = language;
  }
}
