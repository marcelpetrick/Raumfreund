// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// AlarmSnapshot.signalThin: sparse readings are reported, alarms unchanged.

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/alarm_state_machine.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';

const double red = 90;

Duration ms(int value) => Duration(milliseconds: value);

List<AlarmSnapshot> feed(
  AlarmStateMachine machine, {
  required int fromMs,
  required int toMs,
  int stepMs = 100,
}) => [
  for (var t = fromMs; t <= toMs; t += stepMs)
    machine.onSample(timestamp: ms(t), levelDb: red),
];

AlarmStateMachine machine() =>
    AlarmStateMachine(thresholds: Thresholds.defaults);

void main() {
  group('signal thin', () {
    test('is false when idle', () {
      expect(AlarmSnapshot.idle.signalThin, isFalse);
      expect(machine().snapshot.signalThin, isFalse);
    });

    test('10 Hz red alarms and is never thin', () {
      final snapshots = feed(machine(), fromMs: 0, toMs: 12000);
      expect(snapshots.where((s) => s.signalThin), isEmpty);
      expect(snapshots.where((s) => s.shouldFireAlarm), hasLength(1));
    });

    test('1 Hz red never alarms, but reports a thin signal', () {
      final snapshots = feed(machine(), fromMs: 0, toMs: 60000, stepMs: 1000);
      expect(snapshots.where((s) => s.shouldFireAlarm), isEmpty);
      // Poor from the second reading (1 s) on, thin 2 s later.
      expect(snapshots[2].signalThin, isFalse);
      expect(snapshots.skip(3).map((s) => s.signalThin), everyElement(isTrue));
    });

    test('an ignored invalid sample keeps the flag', () {
      final m = machine();
      feed(m, fromMs: 0, toMs: 5000, stepMs: 1000);
      final invalid = m.onSample(timestamp: ms(5100), levelDb: double.nan);
      expect(invalid.signalThin, isTrue);
    });

    test('reset clears the flag', () {
      final m = machine();
      feed(m, fromMs: 0, toMs: 5000, stepMs: 1000);
      m.reset();
      expect(m.snapshot.signalThin, isFalse);
    });

    test('the alarm tone pause is not reported as thin', () {
      final m = machine();
      feed(m, fromMs: 0, toMs: 5000, stepMs: 1000);
      m.onAlarmOutputStarted();
      expect(m.snapshot.signalThin, isFalse);
      // Samples during the tone are ignored and do not count either.
      final during = feed(m, fromMs: 6000, toMs: 9000, stepMs: 1000);
      expect(during.map((s) => s.signalThin), everyElement(isFalse));
      m.onAlarmOutputFinished();
      expect(m.snapshot.signalThin, isFalse);
      // A long tone pause followed by normal readings stays clear.
      final after = feed(m, fromMs: 20000, toMs: 25000);
      expect(after.map((s) => s.signalThin), everyElement(isFalse));
    });
  });
}
