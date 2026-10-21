// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/settings/application/language_controller.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';

import '../../../fakes/in_memory_language_repository.dart';

LanguageController _controller(InMemoryLanguageRepository repository) {
  final controller = LanguageController(repository);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  _loadTests();
  _selectTests();

  test('dispose twice is harmless', () {
    LanguageController(InMemoryLanguageRepository())
      ..dispose()
      ..dispose();
  });
}

void _loadTests() {
  test('starts in German before loading', () {
    final controller = _controller(InMemoryLanguageRepository());
    expect(controller.language, AppLanguage.german);
    expect(controller.value, AppLanguage.german);
  });

  test('loading applies the stored language and notifies', () async {
    final controller = _controller(
      InMemoryLanguageRepository(AppLanguage.croatian),
    );
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.load();
    expect(controller.language, AppLanguage.croatian);
    expect(notified, 1);
  });

  test('loading the default does not notify', () async {
    final controller = _controller(InMemoryLanguageRepository());
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.load();
    expect(notified, 0);
  });

  test('repeated loads share the first one', () async {
    final repository = InMemoryLanguageRepository(AppLanguage.english);
    final controller = _controller(repository);
    final first = controller.load();
    expect(controller.load(), same(first));
    await first;
  });

  test('a choice made while loading wins over the stored one', () async {
    final repository = InMemoryLanguageRepository(AppLanguage.croatian)
      ..loadGate = Completer<void>();
    final controller = _controller(repository);
    final loading = controller.load();
    await controller.select(AppLanguage.chinese);
    repository.loadGate!.complete();
    await loading;
    expect(controller.language, AppLanguage.chinese);
  });

  test('a load finishing after dispose does not notify', () async {
    final repository = InMemoryLanguageRepository(AppLanguage.english)
      ..loadGate = Completer<void>();
    final controller = LanguageController(repository);
    final loading = controller.load();
    controller.dispose();
    repository.loadGate!.complete();
    await loading;
    expect(controller.language, AppLanguage.english);
  });
}

void _selectTests() {
  test('selecting switches before the write has finished', () async {
    final repository = InMemoryLanguageRepository()
      ..saveGate = Completer<void>();
    final controller = _controller(repository);
    var notified = 0;
    controller.addListener(() => notified++);
    final saving = controller.select(AppLanguage.english);
    expect(controller.language, AppLanguage.english);
    expect(notified, 1);
    expect(repository.stored, AppLanguage.german);
    repository.saveGate!.complete();
    expect(await saving, isTrue);
    expect(repository.stored, AppLanguage.english);
  });

  test('a failed write keeps the language for this run', () async {
    final repository = InMemoryLanguageRepository()
      ..saveException = Exception('disk full');
    final controller = _controller(repository);
    expect(await controller.select(AppLanguage.croatian), isFalse);
    expect(controller.language, AppLanguage.croatian);
    expect(repository.stored, AppLanguage.german);
  });

  test('writes are serialized and the last choice is stored', () async {
    final repository = InMemoryLanguageRepository()
      ..saveGate = Completer<void>();
    final controller = _controller(repository);
    final first = controller.select(AppLanguage.english);
    final second = controller.select(AppLanguage.chinese);
    await Future<void>.delayed(Duration.zero);
    // The second write waits until the first one has finished.
    expect(repository.saved, [AppLanguage.english]);
    repository.saveGate!.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(repository.saved, [AppLanguage.english, AppLanguage.chinese]);
    expect(repository.stored, AppLanguage.chinese);
  });

  test('selecting the current language stores it without notifying', () async {
    final repository = InMemoryLanguageRepository();
    final controller = _controller(repository);
    var notified = 0;
    controller.addListener(() => notified++);
    expect(await controller.select(AppLanguage.german), isTrue);
    expect(notified, 0);
    expect(repository.saved, [AppLanguage.german]);
  });
}
