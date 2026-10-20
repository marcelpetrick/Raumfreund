// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

/// Sleeping in the background and waking up on return (ADR 0005).
void main() {
  sleepTests();
  wakeTests();
  teardownRaceTests();
  explicitStopTests();
}

Future<MonitorHarness> _measuring({AppSettings? settings}) async {
  final h = MonitorHarness(settings: settings);
  await h.controller.start();
  expect(h.state.status, MonitorStatus.measuring);
  return h;
}

Future<void> _lifecycle(MonitorHarness h, AppLifecycleState state) async {
  h.controller.onLifecycleChanged(state);
  await settle();
}

/// The sequence Flutter reports when the app leaves the screen.
Future<void> _leave(MonitorHarness h) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    await _lifecycle(h, state);
  }
}

void sleepTests() {
  group('falling asleep', () {
    test('releases the recorder once and keeps history and stars', () async {
      final h = await _measuring(
        settings: AppSettings.defaults.copyWith(quickStarModeEnabled: true),
      );
      h.readings(greenDbfs, 60);
      expect(h.state.stars, 1);
      final history = h.state.history;
      expect(history, isNotEmpty);
      await _leave(h);
      expect(h.state.status, MonitorStatus.sleeping);
      expect(h.source.stopCalls, 1);
      expect(h.screen.isOn, isFalse);
      expect(h.state.zone, isNull);
      expect(h.state.displayLevelDb, isNull);
      expect(h.state.starProgress, 0);
      expect(h.state.stars, 1);
      expect(h.state.history, history);
      expect(h.state.isBusy, isFalse);
    });

    test('clears alarm continuity and the "Mia is away" latch', () async {
      final h = await _measuring();
      h.readings(redDbfs, 40);
      h.readings(redDbfs, 80);
      expect(h.state.kittyAway, isTrue);
      await _leave(h);
      expect(h.state.kittyAway, isFalse);
      expect(h.state.alarmFiredInPhase, isFalse);
      expect(h.state.remainingUntilAlarm, isNull);
    });

    test('readings of the slept session are dropped', () async {
      final h = await _measuring();
      await _leave(h);
      h.source.emitReading(1, redDbfs);
      expect(h.state.zone, isNull);
      expect(h.state.status, MonitorStatus.sleeping);
    });

    test('does nothing while stopped or failed', () async {
      final h = MonitorHarness();
      await _leave(h);
      expect(h.state.status, MonitorStatus.stopped);
      h.permission.requestResult = MicrophonePermissionStatus.denied;
      h.permission.currentStatus = MicrophonePermissionStatus.denied;
      await h.controller.start();
      await _leave(h);
      expect(h.state.status, MonitorStatus.error);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.error);
    });
  });
}

void wakeTests() {
  group('waking up', () {
    test('marks the new session as waking until it measures', () async {
      final h = await _measuring();
      await _leave(h);
      h.source.holdStart = true;
      await _lifecycle(h, AppLifecycleState.hidden);
      await _lifecycle(h, AppLifecycleState.inactive);
      expect(h.state.status, MonitorStatus.starting);
      expect(h.state.waking, isTrue);
      h.source.completeStart();
      await settle();
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.state.waking, isFalse);
      expect(h.source.startCalls, [1, 2]);
      h.readings(greenDbfs, 15);
      expect(h.state.zone, Zone.green);
    });

    test('a manual start is never marked as waking', () async {
      final h = MonitorHarness();
      h.source.holdStart = true;
      unawaited(h.controller.start());
      await settle();
      expect(h.state.waking, isFalse);
      h.source.completeStart();
    });

    test('a further resumed event starts no second session', () async {
      final h = await _measuring();
      await _leave(h);
      await _lifecycle(h, AppLifecycleState.inactive);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.source.startCalls, [1, 2]);
    });

    test('checks the permission again and reports a denial', () async {
      final h = await _measuring();
      await _leave(h);
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..requestResult = MicrophonePermissionStatus.denied;
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.permission.requestCalls, 1);
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.permissionDenied);
      expect(h.state.waking, isFalse);
    });

    test('a busy microphone shows the error with retry', () async {
      final h = await _measuring();
      await _leave(h);
      h.source.startFailure = LevelFailure.microphoneBusy;
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.microphoneBusy);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.source.startCalls, [1, 2]);
    });

    test('leaving again during the permission dialog sleeps again', () async {
      final h = await _measuring();
      await _leave(h);
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..holdRequest = true;
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.permissionPending);
      await _leave(h);
      expect(h.state.status, MonitorStatus.permissionPending);
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await settle();
      expect(h.state.status, MonitorStatus.sleeping);
      expect(h.source.startCalls, [1]);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.source.startCalls, [1, h.controller.lastSessionId]);
    });

    test('leaving while the woken recorder starts sleeps again', () async {
      final h = await _measuring();
      await _leave(h);
      h.source.holdStart = true;
      await _lifecycle(h, AppLifecycleState.resumed);
      await _leave(h);
      h.source.completeStart();
      await settle();
      expect(h.state.status, MonitorStatus.sleeping);
      expect(h.source.recordingSession, isNull);
    });
  });
}

void teardownRaceTests() {
  group('return while the recorder is released', () {
    test('wakes right after the teardown', () async {
      final h = await _measuring();
      final gate = h.source.stopGate = Completer<void>();
      await _leave(h);
      expect(h.state.status, MonitorStatus.stopping);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.source.startCalls, [1]);
      h.source.stopGate = null;
      gate.complete();
      await settle();
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.source.startCalls, [1, 2]);
    });

    test('stays asleep when it left again before the end', () async {
      final h = await _measuring();
      final gate = h.source.stopGate = Completer<void>();
      await _leave(h);
      await _lifecycle(h, AppLifecycleState.resumed);
      await _leave(h);
      h.source.stopGate = null;
      gate.complete();
      await settle();
      expect(h.state.status, MonitorStatus.sleeping);
      expect(h.source.startCalls, [1]);
    });

    for (final (name, action)
        in <(String, Future<void> Function(MonitorHarness))>[
          ('stop', (h) => h.controller.stop()),
          (
            'applying settings',
            (h) => h.controller.applySettings(AppSettings.defaults),
          ),
          ('detached', (h) => _lifecycle(h, AppLifecycleState.detached)),
        ]) {
      test('$name during the teardown is not lost', () async {
        final h = await _measuring();
        final gate = h.source.stopGate = Completer<void>();
        await _leave(h);
        await action(h);
        await _lifecycle(h, AppLifecycleState.resumed);
        h.source.stopGate = null;
        gate.complete();
        await settle();
        expect(h.state.status, MonitorStatus.stopped);
        await _lifecycle(h, AppLifecycleState.resumed);
        expect(h.source.startCalls, [1]);
      });
    }

    test('dispose during the teardown never wakes', () async {
      final h = await _measuring();
      final gate = h.source.stopGate = Completer<void>();
      await _leave(h);
      await _lifecycle(h, AppLifecycleState.resumed);
      h.controller.dispose();
      h.source.stopGate = null;
      gate.complete();
      await settle();
      expect(h.source.startCalls, [1]);
    });
  });
}

void explicitStopTests() {
  group('explicit actions while asleep', () {
    test('stop ends the pause without restart on return', () async {
      final h = await _measuring();
      await _leave(h);
      await h.controller.stop();
      expect(h.state.status, MonitorStatus.stopped);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.source.startCalls, [1]);
    });

    test('applying settings ends the pause', () async {
      final h = await _measuring();
      await _leave(h);
      await h.controller.applySettings(AppSettings.defaults);
      expect(h.state.status, MonitorStatus.stopped);
    });

    test('detached ends the pause', () async {
      final h = await _measuring();
      await _leave(h);
      await _lifecycle(h, AppLifecycleState.detached);
      expect(h.state.status, MonitorStatus.stopped);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.source.startCalls, [1]);
    });

    test('toggle in the background never records', () async {
      final h = await _measuring();
      await _leave(h);
      await h.controller.toggle();
      expect(h.state.status, MonitorStatus.sleeping);
      expect(h.state.waking, isFalse);
      expect(h.source.startCalls, [1]);
      await _lifecycle(h, AppLifecycleState.resumed);
      expect(h.state.status, MonitorStatus.measuring);
    });
  });
}
