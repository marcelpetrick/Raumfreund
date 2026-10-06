// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// No-reading watchdog: a recorder that delivers nothing must not look like
// a calm room (ADR 0003).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_controller.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/domain/calibration.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

const _first = MonitorController.firstReadingTimeout;
const _stall = MonitorController.readingStallTimeout;
const _ms = Duration(milliseconds: 1);
const _output = MonitorController.alarmOutputTimeout;

void main() {
  _timeoutTests();
  _alarmOutputTests();
  _sessionTests();
}

Future<MonitorHarness> _measuring() async {
  final h = MonitorHarness();
  await h.controller.start();
  expect(h.state.status, MonitorStatus.measuring);
  return h;
}

Future<void> _expectNoReadingsError(MonitorHarness h) async {
  await settle();
  expect(h.state.status, MonitorStatus.error);
  expect(h.state.failure, MonitorFailure.noReadings);
  expect(h.state.zone, isNull);
  expect(h.state.displayLevelDb, isNull);
  expect(h.state.kittyAway, isFalse);
  expect(h.state.starProgress, 0);
  expect(h.scheduler.pendingCount, 0);
}

void _timeoutTests() {
  group('no-reading watchdog', () {
    test('values: generous first reading, 3 s stall', () {
      expect(_first, const Duration(seconds: 5));
      expect(_stall, const Duration(seconds: 3));
    });

    test('no first reading ends the session; start recovers', () async {
      final h = await _measuring();
      expect(h.state.zone, isNull);
      h.scheduler.elapse(_first - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      h.scheduler.elapse(_ms);
      await _expectNoReadingsError(h);
      expect(h.source.stopCalls, 1);
      expect(h.screen.calls.last, isFalse);
      await h.controller.start();
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.state.failure, isNull);
      h.readings(greenDbfs, 10);
      expect(h.state.zone, isNotNull);
    });

    test('a stall mid-session ends it instead of showing calm', () async {
      final h = await _measuring();
      h.readings(greenDbfs, 50);
      expect(h.state.zone, isNotNull);
      h.scheduler.elapse(_stall - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      h.scheduler.elapse(_ms);
      await _expectNoReadingsError(h);
    });

    test('the first reading switches to the stall timeout', () async {
      final h = await _measuring();
      h.reading(greenDbfs);
      h.scheduler.elapse(_stall);
      await _expectNoReadingsError(h);
    });

    test('regular and sparse readings keep it quiet', () async {
      final h = await _measuring();
      h.readings(greenDbfs, 600);
      for (var i = 0; i < 20; i++) {
        h.reading(greenDbfs, stepMs: 2900);
      }
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.scheduler.pendingCount, 1);
    });

    test('invalid readings do not count as measuring', () async {
      final h = await _measuring();
      h.readings(greenDbfs, 5);
      h.readings(double.nan, 29);
      expect(h.state.status, MonitorStatus.measuring);
      h.reading(double.negativeInfinity);
      await _expectNoReadingsError(h);
    });

    test('a muted microphone (digital silence) never looks calm', () async {
      final h = await _measuring();
      // Startup zeros are ignored; a real reading afterwards is fine.
      h.readings(Calibration.digitalSilenceDbfs, 10);
      h.readings(greenDbfs, 20);
      expect(h.state.zone, isNotNull);
      // A privacy toggle feeds zeros: no stars, then the error.
      h.readings(Calibration.digitalSilenceDbfs, 29);
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.state.stars, 0);
      h.reading(Calibration.digitalSilenceDbfs);
      await _expectNoReadingsError(h);
    });
  });
}

void _alarmOutputTests() {
  group('no-reading watchdog and the own alarm output', () {
    test('is paused while output plays, restarts after it', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      expect(h.state.alarmPlaying, isTrue);
      // Only the output safety timeout is pending, no watchdog.
      expect(h.scheduler.pendingCount, 1);
      // Ignored readings and silence during the output are both fine.
      h.readings(redDbfs, 15);
      h.scheduler.elapse(_output - _ms * 1501);
      expect(h.state.status, MonitorStatus.measuring);
      h.alarm.finish();
      await settle();
      expect(h.state.alarmPlaying, isFalse);
      expect(h.scheduler.nextDue, h.clock.now + _stall);
      h.readings(greenDbfs, 29);
      h.scheduler.elapse(_stall - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      h.scheduler.elapse(_ms);
      await _expectNoReadingsError(h);
    });

    test('a failed output restarts it too', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      h.alarm.fail();
      await settle();
      expect(h.state.alarmOutputFailed, isTrue);
      h.scheduler.elapse(_stall);
      await _expectNoReadingsError(h);
    });

    test('a replacement session waits for old output to end', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      await h.controller.stop();
      await h.controller.start();
      expect(h.state.alarmPlaying, isTrue);
      expect(h.scheduler.pendingCount, 1);
      h.scheduler.elapse(_output - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      h.alarm.finish();
      await settle();
      // No valid reading in this session yet: the first-reading timeout.
      h.scheduler.elapse(_first - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      h.scheduler.elapse(_ms);
      await _expectNoReadingsError(h);
    });

    test('an output that never answers ends after the timeout', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      expect(h.state.alarmPlaying, isTrue);
      h.scheduler.elapse(_output - _ms);
      expect(h.state.alarmPlaying, isTrue);
      h.scheduler.elapse(_ms);
      await settle();
      expect(h.state.alarmPlaying, isFalse);
      expect(h.state.alarmOutputFailed, isTrue);
      // Measuring and the watchdog resume.
      expect(h.scheduler.nextDue, h.clock.now + _stall);
      h.readings(greenDbfs, 10);
      expect(h.state.zone, isNotNull);
      // A very late answer of the old output changes nothing.
      final emitted = h.statuses.length;
      h.alarm.finish();
      await settle();
      expect(h.statuses, hasLength(emitted));
      expect(h.state.status, MonitorStatus.measuring);
    });

    test('output ending after stop arms nothing', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      await h.controller.stop();
      h.alarm.finish();
      await settle();
      expect(h.scheduler.pendingCount, 0);
      expect(h.state.status, MonitorStatus.stopped);
    });

    test('output ending while a new start is pending arms nothing', () async {
      final h = await _measuring();
      h.readings(redDbfs, 101);
      await h.controller.stop();
      h.source.holdStart = true;
      final starting = h.controller.start();
      await settle();
      expect(h.state.status, MonitorStatus.starting);
      h.alarm.finish();
      await settle();
      expect(h.scheduler.pendingCount, 0);
      h.source.completeStart();
      await starting;
      expect(h.scheduler.nextDue, h.clock.now + _first);
    });
  });
}

void _sessionTests() {
  group('no-reading watchdog across sessions', () {
    test('stop cancels it; the stopped state stays', () async {
      final h = await _measuring();
      await h.controller.stop();
      expect(h.scheduler.pendingCount, 0);
      h.scheduler.elapse(const Duration(minutes: 1));
      expect(h.state.status, MonitorStatus.stopped);
      expect(h.state.failure, isNull);
    });

    test('a restart gets its own full timeout', () async {
      final h = await _measuring();
      h.scheduler.elapse(_first - _ms);
      await h.controller.stop();
      await h.controller.start();
      expect(h.scheduler.pendingCount, 1);
      h.scheduler.elapse(_first - _ms);
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.controller.lastSessionId, 2);
      h.scheduler.elapse(_ms);
      await _expectNoReadingsError(h);
    });

    test('a native error first leaves no watchdog behind', () async {
      final h = await _measuring();
      h.reading(greenDbfs);
      await h.source.close();
      await settle();
      expect(h.state.failure, MonitorFailure.recordingAborted);
      expect(h.scheduler.pendingCount, 0);
    });

    test('dispose cancels it', () async {
      final h = await _measuring();
      h.controller.dispose();
      expect(h.scheduler.pendingCount, 0);
      h.scheduler.elapse(const Duration(minutes: 1));
      await settle();
    });

    test('not armed while starting; a timeout then is ignored', () async {
      final h = MonitorHarness();
      h.source.holdStart = true;
      final starting = h.controller.start();
      await settle();
      expect(h.state.status, MonitorStatus.starting);
      expect(h.scheduler.pendingCount, 0);
      // A reading may arrive before the native start call returns.
      h.reading(greenDbfs);
      expect(h.scheduler.pendingCount, 1);
      h.scheduler.elapse(const Duration(seconds: 10));
      expect(h.state.status, MonitorStatus.starting);
      h.source.completeStart();
      await starting;
      expect(h.state.status, MonitorStatus.measuring);
      expect(h.scheduler.nextDue, h.clock.now + _stall);
    });

    test('a stop during the watchdog teardown changes nothing', () async {
      final h = await _measuring();
      h.source.stopGate = Completer<void>();
      h.scheduler.elapse(_first);
      await settle();
      expect(h.state.status, MonitorStatus.stopping);
      final stopping = h.controller.stop();
      h.source.stopGate!.complete();
      await stopping;
      await settle();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.failure, MonitorFailure.noReadings);
      expect(h.source.stopCalls, 1);
    });
  });
}
