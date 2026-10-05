// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/settings/application/settings_controller.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

import '../../../fakes/in_memory_settings_repository.dart';
import '../../../fakes/settle.dart';

final AppSettings custom = AppSettings.defaults.copyWith(
  thresholds: Thresholds(yellowDb: 50, redDb: 70),
  calibrationCorrectionDb: 4,
  alarmDelaySeconds: 30,
);

void main() {
  late InMemorySettingsRepository repository;
  late SettingsController controller;
  late int notifications;

  setUp(() {
    repository = InMemorySettingsRepository(custom);
    controller = SettingsController(repository);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  test('is loading with defaults until loaded', () async {
    expect(controller.isLoading, isTrue);
    expect(controller.settings, AppSettings.defaults);
    await controller.load();
    expect(controller.isLoading, isFalse);
    expect(controller.loadFailed, isFalse);
    expect(controller.settings, custom);
    expect(notifications, 1);
  });

  test('repeated load calls share one load', () async {
    repository.gate = Completer<void>();
    final first = controller.load();
    final second = controller.load();
    expect(identical(first, second), isTrue);
    repository.gate!.complete();
    await first;
    expect(notifications, 1);
  });

  test('a failing load keeps defaults and flags it', () async {
    repository.loadException = const FormatException('broken');
    await controller.load();
    expect(controller.isLoading, isFalse);
    expect(controller.loadFailed, isTrue);
    expect(controller.settings, AppSettings.defaults);
  });

  test('save stores and exposes the new settings', () async {
    final changes = <bool>[];
    controller.addListener(() => changes.add(controller.isSaving));
    expect(await controller.save(custom), isTrue);
    expect(controller.settings, custom);
    expect(repository.stored, custom);
    expect(controller.saveFailed, isFalse);
    expect(changes, [true, false]);
  });

  test('a failing save keeps the old settings and flags the error', () async {
    await controller.load();
    repository.saveException = const FormatException('disk');
    expect(await controller.save(AppSettings.defaults), isFalse);
    expect(controller.saveFailed, isTrue);
    expect(controller.settings, custom);
    controller.clearSaveError();
    expect(controller.saveFailed, isFalse);
    final before = notifications;
    controller.clearSaveError();
    expect(notifications, before);
  });

  test('the alarm delay is loaded, saved and kept on failure', () async {
    await controller.load();
    expect(controller.settings.alarmDelaySeconds, 30);
    final faster = custom.copyWith(alarmDelaySeconds: 5);
    expect(await controller.save(faster), isTrue);
    expect(repository.stored.alarmDelaySeconds, 5);
    repository.saveException = const FormatException('disk');
    expect(await controller.save(AppSettings.defaults), isFalse);
    expect(controller.settings.alarmDelaySeconds, 5);
  });

  test('saves are serialized in call order', () async {
    repository.gate = Completer<void>();
    final first = controller.save(custom);
    final second = controller.save(AppSettings.defaults);
    await settle();
    expect(repository.saveCalls, 1);
    repository.gate!.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(repository.stored, AppSettings.defaults);
    expect(controller.settings, AppSettings.defaults);
  });

  test('dispose is idempotent and silences late completions', () async {
    repository.gate = Completer<void>();
    final loading = controller.load();
    controller
      ..dispose()
      ..dispose();
    repository.gate!.complete();
    await loading;
    expect(notifications, 0);
    expect(controller.settings, custom);
  });
}
