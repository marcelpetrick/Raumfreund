// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Confirmed zone (ADR 0004) and the "Mia is away" latch in the controller.

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

void main() {
  zoneTests();
  kittyTests();
  kittyResetTests();
}

/// Starts a harness and reaches the alarm of a confirmed red phase.
Future<MonitorHarness> redAlarm({AppSettings? settings}) async {
  final h = MonitorHarness(settings: settings);
  await h.controller.start();
  h.readings(redDbfs, 101);
  expect(h.state.alarmFiredInPhase, isTrue);
  return h;
}

void zoneTests() {
  group('confirmed zone', () {
    late MonitorHarness h;
    setUp(() async {
      h = MonitorHarness();
      await h.controller.start();
    });

    test('UI zone switches only once the new zone has 50 % of 1 s', () {
      h.readings(greenDbfs, 11);
      h.readings(redDbfs, 4);
      expect(h.state.zone, Zone.green);
      expect(h.state.alarmLevelDb, 90);
      h.reading(redDbfs);
      expect(h.state.zone, Zone.red);
      expect(h.state.remainingUntilAlarm, const Duration(milliseconds: 9600));
    });

    test('red/yellow flicker does not flicker the UI zone', () {
      h.reading(redDbfs);
      for (var i = 0; i < 20; i++) {
        h
          ..readings(yellowDbfs, 2)
          ..reading(redDbfs);
        expect(h.state.zone, Zone.red);
      }
    });

    test('readings during the alarm tone leave gauge and chart alone', () {
      h.readings(redDbfs, 101);
      expect(h.state.alarmPlaying, isTrue);
      final history = h.state.history;
      final display = h.state.displayLevelDb;
      final now = h.state.historyNow;
      h.readings(greenDbfs, 30);
      expect(h.state.history, same(history));
      expect(h.state.displayLevelDb, display);
      expect(h.state.alarmLevelDb, 90);
      expect(h.state.historyNow, now);
    });

    test('a short red blip does not interrupt the quiet minute', () {
      h.readings(greenDbfs, 300);
      h.readings(redDbfs, 4);
      expect(h.state.zone, Zone.green);
      h.readings(greenDbfs, 300);
      expect(h.state.stars, 1);
    });
  });
}

void kittyTests() {
  group('Mia away latch', () {
    test('not away before the red alarm or after a yellow alarm', () async {
      final h = MonitorHarness();
      await h.controller.start();
      h.readings(redDbfs, 100);
      expect(h.state.kittyAway, isFalse);
      await h.controller.stop();
      await h.controller.start();
      h.readings(yellowDbfs, 101);
      expect(h.state.alarmFiredInPhase, isTrue);
      expect(h.state.kittyAway, isFalse);
    });

    test('leaves at the red alarm and stays away after the tone', () async {
      final h = await redAlarm();
      expect(h.state.kittyAway, isTrue);
      expect(h.state.alarmPlaying, isTrue);
      h.alarm.finish();
      await settle();
      expect(h.state.alarmFiredInPhase, isFalse);
      expect(h.state.kittyAway, isTrue);
      h.readings(redDbfs, 5);
      expect(h.state.kittyAway, isTrue);
    });

    test('after the tone a single green sample does not bring her back, '
        'settled green does', () async {
      final h = await redAlarm();
      h.alarm.finish();
      await settle();
      h.reading(greenDbfs); // adopted immediately, not settled
      expect(h.state.zone, Zone.green);
      expect(h.state.kittyAway, isTrue);
      h.readings(redDbfs, 3);
      h.readings(greenDbfs, 17); // 2.0 s covered, 15 % red
      expect(h.state.zone, Zone.green);
      expect(h.state.kittyAway, isTrue);
      h.reading(greenDbfs); // 14.3 % red: settled green
      expect(h.state.kittyAway, isFalse);
    });

    test('yellow after the red alarm keeps her away; confirmed green '
        'brings her back', () async {
      final h = await redAlarm(
        settings: AppSettings.defaults.copyWith(
          alarmSoundEnabled: false,
          vibrationEnabled: false,
        ),
      );
      h.readings(yellowDbfs, 30);
      expect(h.state.zone, Zone.yellow);
      expect(h.state.kittyAway, isTrue);
      h.readings(greenDbfs, 25);
      expect(h.state.zone, Zone.yellow);
      expect(h.state.kittyAway, isTrue);
      h.reading(greenDbfs);
      expect(h.state.zone, Zone.green);
      expect(h.state.kittyAway, isFalse);
      h.readings(redDbfs, 20);
      expect(h.state.zone, Zone.red);
      expect(h.state.kittyAway, isFalse);
    });
  });
}

void kittyResetTests() {
  group('Mia comes back on stop, reset and error', () {
    test('stop while away', () async {
      final h = await redAlarm();
      await h.controller.stop();
      expect(h.state.kittyAway, isFalse);
      await h.controller.start();
      h.reading(redDbfs);
      expect(h.state.kittyAway, isFalse);
    });

    test('error while away', () async {
      final h = await redAlarm();
      h.source.emitError(h.controller.lastSessionId, LevelFailure.unavailable);
      await settle();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.kittyAway, isFalse);
    });

    test('settings change while away', () async {
      final h = await redAlarm();
      await h.controller.applySettings(AppSettings.defaults);
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.state.kittyAway, isFalse);
    });
  });
}
