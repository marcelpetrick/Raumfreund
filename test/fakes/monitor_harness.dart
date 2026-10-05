// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:raumfreund/features/monitor/application/monitor_controller.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

import 'fake_alarm_output.dart';
import 'fake_clock.dart';
import 'fake_level_source.dart';
import 'fake_permission.dart';
import 'fake_screen_awake.dart';

/// dBFS values that map to 50 / 70 / 90 dB without calibration correction
/// (green / yellow / red with default thresholds).
const double greenDbfs = -40;

/// See [greenDbfs].
const double yellowDbfs = -20;

/// See [greenDbfs].
const double redDbfs = 0;

/// Controller wired to fakes, recording every emitted status.
final class MonitorHarness {
  /// Creates the harness with [settings] (defaults if omitted).
  MonitorHarness({AppSettings? settings, StarEarnedSink? onStarEarned}) {
    controller = MonitorController(
      permission: permission,
      levelSource: source,
      alarmOutput: alarm,
      screenAwake: screen,
      clock: clock,
      settings: settings ?? AppSettings.defaults,
      onStarEarned: onStarEarned ?? ignoreStarEarned,
    );
    controller.addListener(() => statuses.add(controller.state.status));
  }

  /// Fake clock.
  final FakeClock clock = FakeClock(const Duration(seconds: 100));

  /// Fake permission.
  final FakePermission permission = FakePermission();

  /// Fake level source.
  final FakeLevelSource source = FakeLevelSource();

  /// Fake alarm output.
  final FakeAlarmOutput alarm = FakeAlarmOutput();

  /// Fake screen-awake port.
  final FakeScreenAwake screen = FakeScreenAwake();

  /// Controller under test.
  late final MonitorController controller;

  /// Every status emitted to listeners, in order.
  final List<MonitorStatus> statuses = [];

  /// Current state.
  MonitorState get state => controller.state;

  /// Advances the clock by [stepMs] and emits a reading for [session]
  /// (default: the latest session).
  void reading(double dbfs, {int? session, int stepMs = 100}) {
    clock.advanceMs(stepMs);
    source.emitReading(session ?? controller.lastSessionId, dbfs);
  }

  /// Emits [count] readings of [dbfs], 100 ms apart.
  void readings(double dbfs, int count) {
    for (var i = 0; i < count; i++) {
      reading(dbfs);
    }
  }
}
