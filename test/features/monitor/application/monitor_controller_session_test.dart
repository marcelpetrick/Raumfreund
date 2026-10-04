// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

void main() {
  startStopTests();
  permissionTests();
  permissionLifecycleTests();
  lifecycleTests();
  staleSessionTests();
  failureTests();
  disposeTests();
}

void startStopTests() {
  group('start/stop', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    test('is stopped initially', () {
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.state.isBusy, isFalse);
      expect(h.controller.lastSessionId, 0);
      expect(h.state.thresholds, h.controller.settings.thresholds);
    });

    test(
      'start with granted permission measures and keeps screen on',
      () async {
        await h.controller.start();
        expect(h.statuses, [
          MonitorStatus.permissionPending,
          MonitorStatus.starting,
          MonitorStatus.measuring,
        ]);
        expect(h.permission.statusCalls, 1);
        expect(h.permission.requestCalls, 0);
        expect(h.source.startCalls, [1]);
        expect(h.source.hasListener, isTrue);
        expect(h.screen.isOn, isTrue);
      },
    );

    test('stop ends the session, releases everything, is idempotent', () async {
      await h.controller.start();
      await h.controller.stop();
      await h.controller.stop();
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.statuses.last, MonitorStatus.stopped);
      expect(h.statuses, contains(MonitorStatus.stopping));
      expect(h.source.stopCalls, 1);
      expect(h.source.hasListener, isFalse);
      expect(h.screen.calls, [true, false]);
    });

    test('stop without a session does nothing', () async {
      await h.controller.stop();
      expect(h.source.stopCalls, 0);
      expect(h.statuses, isEmpty);
    });

    test('rapid repeated starts create only one session', () async {
      final first = h.controller.start();
      final second = h.controller.start();
      unawaited(h.controller.toggle());
      await Future.wait([first, second]);
      expect(h.source.startCalls, [1]);
      expect(h.controller.lastSessionId, 1);
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('toggle starts when stopped and stops when measuring', () async {
      await h.controller.toggle();
      expect(h.state.status, MonitorStatus.measuring);
      await h.controller.toggle();
      expect(h.state.status, MonitorStatus.stopped);
      await h.controller.toggle();
      expect(h.controller.lastSessionId, 2);
      expect(h.source.startCalls, [1, 2]);
    });

    test('start is ignored while stopping', () async {
      await h.controller.start();
      final stopping = h.controller.stop();
      expect(h.state.status, MonitorStatus.stopping);
      await h.controller.start();
      await h.controller.toggle();
      await stopping;
      expect(h.controller.lastSessionId, 1);
      expect(h.state.status, MonitorStatus.stopped);
    });
  });
}

void permissionTests() {
  group('permission', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    test('requests when not granted and starts after grant', () async {
      h.permission.currentStatus = MicrophonePermissionStatus.denied;
      await h.controller.start();
      expect(h.permission.requestCalls, 1);
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('denied ends in error permissionDenied without recording', () async {
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..requestResult = MicrophonePermissionStatus.denied;
      await h.controller.start();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.permissionDenied);
      expect(h.source.startCalls, isEmpty);
      expect(h.screen.isOn, isFalse);
    });

    test('permanently denied offers the app settings', () async {
      h.permission
        ..currentStatus = MicrophonePermissionStatus.permanentlyDenied
        ..requestResult = MicrophonePermissionStatus.permanentlyDenied;
      await h.controller.start();
      expect(h.state.failure, MonitorFailure.permissionPermanentlyDenied);
      expect(await h.controller.openAppSettings(), isTrue);
      expect(h.permission.openSettingsCalls, 1);
      h.permission.openSettingsException = const FormatException('none');
      expect(await h.controller.openAppSettings(), isFalse);
    });

    test('start after an error retries and clears the failure', () async {
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..requestResult = MicrophonePermissionStatus.denied;
      await h.controller.start();
      h.permission.requestResult = MicrophonePermissionStatus.granted;
      await h.controller.start();
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.state.failure, isNull);
    });

    test('a failing permission query ends in error unavailable', () async {
      final errors = captureFlutterErrors();
      h.permission.statusException = const FormatException('channel');
      await h.controller.start();
      expect(h.state.failure, MonitorFailure.unavailable);
      expect(errors, hasLength(1));
    });

    test('stop while the dialog is open ignores the late answer', () async {
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..holdRequest = true;
      final starting = h.controller.start();
      await settle();
      expect(h.state.status, MonitorStatus.permissionPending);
      await h.controller.stop();
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await starting;
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.source.startCalls, isEmpty);
    });
  });
}

void permissionLifecycleTests() {
  group('lifecycle during the permission dialog', () {
    late MonitorHarness h;
    setUp(() {
      h = MonitorHarness();
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..holdRequest = true;
    });

    late Future<void> starting;

    Future<void> openDialog() async {
      starting = h.controller.start();
      await settle();
      expect(h.permission.isRequestPending, isTrue);
    }

    test('inactive/paused do not cancel the request', () async {
      await openDialog();
      h.controller.onLifecycleChanged(AppLifecycleState.inactive);
      h.controller.onLifecycleChanged(AppLifecycleState.hidden);
      h.controller.onLifecycleChanged(AppLifecycleState.paused);
      await settle();
      expect(h.state.status, MonitorStatus.permissionPending);
      h.controller.onLifecycleChanged(AppLifecycleState.resumed);
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await starting;
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('grant while inactive (dialog closing) starts recording', () async {
      await openDialog();
      h.controller.onLifecycleChanged(AppLifecycleState.inactive);
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await starting;
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('grant while in the background does not auto start', () async {
      await openDialog();
      h.controller.onLifecycleChanged(AppLifecycleState.hidden);
      h.controller.onLifecycleChanged(AppLifecycleState.paused);
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await starting;
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.source.startCalls, isEmpty);
      h.controller.onLifecycleChanged(AppLifecycleState.resumed);
      await settle();
      expect(h.state.status, MonitorStatus.stopped);
    });

    test('denial while in the background is still reported', () async {
      await openDialog();
      h.controller.onLifecycleChanged(AppLifecycleState.paused);
      h.permission.completeRequest(MicrophonePermissionStatus.denied);
      await starting;
      expect(h.state.failure, MonitorFailure.permissionDenied);
    });
  });
}

void lifecycleTests() {
  group('lifecycle while measuring', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    for (final background in [
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      test('$background stops without restart on resume', () async {
        await h.controller.start();
        h.controller.onLifecycleChanged(background);
        await settle();
        expect(h.state.status, MonitorStatus.stopped);
        expect(h.screen.isOn, isFalse);
        h.controller.onLifecycleChanged(AppLifecycleState.resumed);
        await settle();
        expect(h.state.status, MonitorStatus.stopped);
        expect(h.source.startCalls, [1]);
      });
    }

    test('inactive (notification shade) keeps measuring', () async {
      await h.controller.start();
      h.controller.onLifecycleChanged(AppLifecycleState.inactive);
      await settle();
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('background while stopped does nothing', () async {
      h.controller.onLifecycleChanged(AppLifecycleState.paused);
      await settle();
      expect(h.statuses, isEmpty);
      expect(h.source.stopCalls, 0);
    });
  });
}

void staleSessionTests() {
  group('stale sessions', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    test('stop while starting stops the late native start', () async {
      h.source.holdStart = true;
      final starting = h.controller.start();
      await settle();
      expect(h.state.status, MonitorStatus.starting);
      await h.controller.stop();
      expect(h.source.stopCalls, 1);
      h.source.completeStart();
      await starting;
      expect(h.source.stopCalls, 2);
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.screen.isOn, isFalse);
    });

    test('background while starting stops', () async {
      h.source.holdStart = true;
      final starting = h.controller.start();
      await settle();
      h.controller.onLifecycleChanged(AppLifecycleState.paused);
      await settle();
      h.source.completeStart();
      await starting;
      expect(h.state.status, MonitorStatus.stopped);
    });

    test('late start of an old session does not stop a newer one', () async {
      h.source.holdStart = true;
      final first = h.controller.start();
      await settle();
      await h.controller.stop();
      await h.controller.start();
      expect(h.state.status, MonitorStatus.measuring);
      final stops = h.source.stopCalls;
      h.source.completeStart();
      await first;
      expect(h.source.stopCalls, stops);
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('late start failure of an old session is ignored', () async {
      h.source.holdStart = true;
      final first = h.controller.start();
      await settle();
      await h.controller.stop();
      h.source.failStart(LevelFailure.microphoneBusy);
      await first;
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.state.failure, isNull);
    });

    test('events of other sessions are dropped', () async {
      await h.controller.start();
      h.reading(redDbfs, session: 7);
      h.source.emitError(7, LevelFailure.recordingAborted);
      expect(h.state.alarmLevelDb, isNull);
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('events of the previous session are dropped after restart', () async {
      await h.controller.start();
      await h.controller.stop();
      await h.controller.start();
      h.source.emitError(1, LevelFailure.recordingAborted);
      h.reading(greenDbfs, session: 1);
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.state.alarmLevelDb, isNull);
      h.reading(greenDbfs);
      expect(h.state.alarmLevelDb, 50);
    });
  });
}

void failureTests() {
  group('recording failures', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    final mapping = {
      LevelFailure.microphoneBusy: MonitorFailure.microphoneBusy,
      LevelFailure.recordingAborted: MonitorFailure.recordingAborted,
      LevelFailure.unavailable: MonitorFailure.unavailable,
      LevelFailure.permissionMissing: MonitorFailure.permissionDenied,
    };

    for (final entry in mapping.entries) {
      test('start failure ${entry.key.name} → ${entry.value.name}', () async {
        h.source.startFailure = entry.key;
        await h.controller.start();
        expect(h.state.status, MonitorStatus.error);
        expect(h.state.failure, entry.value);
        expect(h.source.hasListener, isFalse);
        expect(h.screen.isOn, isFalse);
      });

      test('stream error ${entry.key.name} → ${entry.value.name}', () async {
        await h.controller.start();
        h.source.emitError(1, entry.key);
        await settle();
        expect(h.state.status, MonitorStatus.error);
        expect(h.state.failure, entry.value);
        expect(h.source.hasListener, isFalse);
        expect(h.screen.isOn, isFalse);
      });
    }

    test('unexpected start exception → unavailable and reported', () async {
      final errors = captureFlutterErrors();
      h.source.startException = const FormatException('boom');
      await h.controller.start();
      expect(h.state.failure, MonitorFailure.unavailable);
      expect(errors, hasLength(1));
    });

    test('transport stream error stops safely and is reported', () async {
      final errors = captureFlutterErrors();
      await h.controller.start();
      h.source.emitStreamError(const FormatException('bad event'));
      await settle();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.unavailable);
      expect(h.source.hasListener, isFalse);
      expect(h.screen.isOn, isFalse);
      expect(errors, hasLength(1));
    });

    test('unexpected stream completion stops as aborted', () async {
      await h.controller.start();
      await h.source.close();
      await settle();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.recordingAborted);
      expect(h.screen.isOn, isFalse);
    });

    test('failing cleanup calls are reported but stop completes', () async {
      final errors = captureFlutterErrors();
      await h.controller.start();
      h.source.stopException = const FormatException('stop');
      h.screen.exception = const FormatException('screen');
      await h.controller.stop();
      expect(h.state.status, MonitorStatus.stopped);
      expect(errors, hasLength(2));
    });
  });
}

void disposeTests() {
  group('dispose', () {
    late MonitorHarness h;
    setUp(() => h = MonitorHarness());

    test('releases everything and is idempotent', () async {
      await h.controller.start();
      h.controller
        ..dispose()
        ..dispose();
      await settle();
      expect(h.source.hasListener, isFalse);
      expect(h.source.stopCalls, 1);
      expect(h.screen.isOn, isFalse);
    });

    test('ignores calls and late answers after dispose', () async {
      h.permission
        ..currentStatus = MicrophonePermissionStatus.denied
        ..holdRequest = true;
      final starting = h.controller.start();
      await settle();
      h.controller.dispose();
      h.permission.completeRequest(MicrophonePermissionStatus.granted);
      await starting;
      await h.controller.start();
      await h.controller.applySettings(h.controller.settings);
      expect(h.source.startCalls, isEmpty);
      expect(h.state.status, MonitorStatus.permissionPending);
    });
  });
}
