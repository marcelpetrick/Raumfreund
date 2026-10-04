// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

void main() {
  readingTests();
  alarmTests();
  alarmOutputTests();
  settingsTests();
  starsTests();
}

void readingTests() {
  group('readings', () {
    late MonitorHarness h;
    setUp(() async {
      h = MonitorHarness();
      await h.controller.start();
    });

    test('a reading updates levels, zone, history and countdown', () {
      h.reading(yellowDbfs);
      expect(h.state.alarmLevelDb, 70);
      expect(h.state.displayLevelDb, 70);
      expect(h.state.zone, Zone.yellow);
      expect(h.state.remainingUntilAlarm, const Duration(seconds: 10));
      expect(h.state.history, hasLength(1));
      expect(h.state.historyNow, h.clock.now);
    });

    test('display is smoothed, alarm value is not', () {
      h
        ..reading(greenDbfs)
        ..reading(redDbfs);
      expect(h.state.alarmLevelDb, 90);
      expect(h.state.zone, Zone.red);
      expect(h.state.displayLevelDb, greaterThan(50));
      expect(h.state.displayLevelDb, lessThan(90));
    });

    test('invalid readings are ignored', () {
      h
        ..reading(greenDbfs)
        ..reading(double.nan)
        ..reading(double.infinity);
      expect(h.state.alarmLevelDb, 50);
      expect(h.state.history, hasLength(1));
    });

    test('stop clears live values but keeps the history', () async {
      // 10.5 s of readings span two 10 s history buckets.
      h.readings(greenDbfs, 105);
      await h.controller.stop();
      expect(h.state.alarmLevelDb, isNull);
      expect(h.state.displayLevelDb, isNull);
      expect(h.state.zone, isNull);
      expect(h.state.history, hasLength(2));
    });

    test('a new session starts smoothing afresh', () async {
      h.reading(greenDbfs);
      await h.controller.stop();
      await h.controller.start();
      h.reading(redDbfs);
      expect(h.state.displayLevelDb, 90);
    });
  });
}

void alarmTests() {
  group('alarm timing', () {
    late MonitorHarness h;
    setUp(() async {
      h = MonitorHarness();
      await h.controller.start();
    });

    test('fires once after 10 s of red, with the configured options', () {
      h.readings(redDbfs, 100); // first sample at t0, last at t0 + 9.9 s
      expect(h.alarm.calls, isEmpty);
      expect(h.state.remainingUntilAlarm, const Duration(milliseconds: 100));
      h.reading(redDbfs); // t0 + 10 s
      expect(h.alarm.calls, hasLength(1));
      expect(h.alarm.calls.single.sound, isTrue);
      expect(h.alarm.calls.single.vibrate, isTrue);
      expect(h.state.alarmFiredInPhase, isTrue);
      expect(h.state.alarmPlaying, isTrue);
      expect(h.state.remainingUntilAlarm, isNull);
    });

    test('no alarm while the tone plays; new phase after it', () async {
      h.readings(redDbfs, 101);
      h.readings(redDbfs, 200);
      expect(h.alarm.calls, hasLength(1));
      h.alarm.finish();
      await settle();
      expect(h.state.alarmPlaying, isFalse);
      expect(h.state.alarmFiredInPhase, isFalse);
      h.readings(redDbfs, 100);
      expect(h.alarm.calls, hasLength(1));
      h.reading(redDbfs);
      expect(h.alarm.calls, hasLength(2));
    });

    test('gap over 1 s restarts the phase', () {
      h.readings(redDbfs, 95);
      h.reading(redDbfs, stepMs: 1001);
      h.readings(redDbfs, 99);
      expect(h.alarm.calls, isEmpty);
      h.reading(redDbfs);
      expect(h.alarm.calls, hasLength(1));
    });

    test('stop and restart begin a new phase', () async {
      h.readings(redDbfs, 90);
      await h.controller.stop();
      await h.controller.start();
      h.readings(redDbfs, 100);
      expect(h.alarm.calls, isEmpty);
      h.reading(redDbfs);
      expect(h.alarm.calls, hasLength(1));
    });
  });
}

void alarmOutputTests() {
  group('alarm output', () {
    test(
      'a failing output is non-fatal and flagged until next start',
      () async {
        final h = MonitorHarness();
        await h.controller.start();
        h.readings(redDbfs, 101);
        h.alarm.fail();
        await settle();
        expect(h.state.status, MonitorStatus.measuring);
        expect(h.state.alarmPlaying, isFalse);
        expect(h.state.alarmOutputFailed, isTrue);
        h.readings(redDbfs, 101);
        expect(h.alarm.calls, hasLength(2));
        await h.controller.stop();
        await h.controller.start();
        expect(h.state.alarmOutputFailed, isFalse);
      },
    );

    test('without sound and vibration no output is played', () async {
      final h = MonitorHarness(
        settings: AppSettings.defaults.copyWith(
          alarmSoundEnabled: false,
          vibrationEnabled: false,
        ),
      );
      await h.controller.start();
      h.readings(redDbfs, 101);
      expect(h.alarm.calls, isEmpty);
      expect(h.state.alarmFiredInPhase, isTrue);
      expect(h.state.alarmPlaying, isFalse);
    });

    test('options are passed through', () async {
      final h = MonitorHarness(
        settings: AppSettings.defaults.copyWith(alarmSoundEnabled: false),
      );
      await h.controller.start();
      h.readings(redDbfs, 101);
      expect(h.alarm.calls.single.sound, isFalse);
      expect(h.alarm.calls.single.vibrate, isTrue);
    });

    test('completion of an old session does not touch the new one', () async {
      final h = MonitorHarness();
      await h.controller.start();
      h.readings(redDbfs, 101);
      await h.controller.stop();
      expect(h.state.alarmPlaying, isFalse);
      await h.controller.start();
      h.readings(redDbfs, 50); // 4.9 s into the new phase
      h.alarm.finish();
      await settle();
      h.readings(redDbfs, 50); // 9.9 s
      expect(h.alarm.calls, hasLength(1));
      h.reading(redDbfs); // 10 s: the new phase was not reset
      expect(h.alarm.calls, hasLength(2));
    });
  });
}

void settingsTests() {
  group('applySettings', () {
    test('stops and uses new thresholds and calibration next time', () async {
      final h = MonitorHarness();
      await h.controller.start();
      final yellow = h.state.thresholds.yellowDb - 20;
      final settings = AppSettings(
        thresholds: Thresholds(yellowDb: yellow, redDb: yellow + 5),
        calibrationCorrectionDb: 10,
        alarmSoundEnabled: true,
        vibrationEnabled: false,
      );
      await h.controller.applySettings(settings);
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.state.thresholds, settings.thresholds);
      expect(h.controller.settings, settings);
      await h.controller.start();
      h.reading(greenDbfs);
      expect(h.state.alarmLevelDb, 60);
      expect(h.state.zone, Zone.red);
    });

    test('while stopped only updates the thresholds', () async {
      final h = MonitorHarness();
      final settings = AppSettings.defaults.copyWith(
        thresholds: Thresholds(yellowDb: 50, redDb: 70),
      );
      await h.controller.applySettings(settings);
      expect(h.state.thresholds, settings.thresholds);
      expect(h.source.stopCalls, 0);
    });
  });
}

void starsTests() {
  group('quiet stars', () {
    test('a green minute earns a star, kept after stop', () async {
      final h = MonitorHarness();
      await h.controller.start();
      h.readings(greenDbfs, 600);
      expect(h.state.stars, 0);
      expect(h.state.starProgress, closeTo(59.9 / 60, 1e-9));
      h.reading(greenDbfs);
      expect(h.state.stars, 1);
      expect(h.state.starJustEarned, isTrue);
      h.reading(greenDbfs);
      expect(h.state.starJustEarned, isFalse);
      await h.controller.stop();
      expect(h.state.stars, 1);
      expect(h.state.starProgress, 0);
    });
  });
}
