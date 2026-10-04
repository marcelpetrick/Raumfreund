// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/alarm_state_machine.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

const double green = 50;
const double yellow = 70;
const double red = 90;

Duration ms(int value) => Duration(milliseconds: value);

/// Feeds [level] every 100 ms from [fromMs] (inclusive) to [toMs]
/// (inclusive) and returns all snapshots.
List<AlarmSnapshot> feed(
  AlarmStateMachine machine,
  double level, {
  required int fromMs,
  required int toMs,
  int stepMs = 100,
}) => [
  for (var t = fromMs; t <= toMs; t += stepMs)
    machine.onSample(timestamp: ms(t), levelDb: level),
];

int fireCount(Iterable<AlarmSnapshot> snapshots) =>
    snapshots.where((s) => s.shouldFireAlarm).length;

void main() {
  initialStateTests();
  tenSecondRuleTests();
  phaseChangeTests();
  gapTests();
  resetTests();
  ownAlarmTests();
}

AlarmStateMachine defaultMachine() =>
    AlarmStateMachine(thresholds: Thresholds.defaults);

void initialStateTests() {
  group('initial state and zones', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('is idle before the first sample', () {
      expect(machine.snapshot.zone, isNull);
      expect(machine.snapshot.remainingUntilAlarm, isNull);
      expect(machine.snapshot.phaseElapsed, Duration.zero);
      expect(machine.snapshot.suppressed, isFalse);
      expect(machine.alarmDelay, const Duration(seconds: 10));
      expect(machine.maxGap, const Duration(seconds: 1));
    });

    test('exact limits belong to the higher zone', () {
      expect(
        machine.onSample(timestamp: ms(0), levelDb: 59.999).zone,
        Zone.green,
      );
      expect(
        machine.onSample(timestamp: ms(100), levelDb: 60).zone,
        Zone.yellow,
      );
      expect(
        machine.onSample(timestamp: ms(200), levelDb: 79.999).zone,
        Zone.yellow,
      );
      expect(machine.onSample(timestamp: ms(300), levelDb: 80).zone, Zone.red);
    });

    test('green never fires and has no countdown', () {
      final snapshots = feed(machine, green, fromMs: 0, toMs: 60000);
      expect(fireCount(snapshots), 0);
      expect(snapshots.last.zone, Zone.green);
      expect(snapshots.last.remainingUntilAlarm, isNull);
      expect(snapshots.last.phaseElapsed, Duration.zero);
    });

    test('entering yellow starts the timer at zero', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      final first = machine.onSample(timestamp: ms(1100), levelDb: yellow);
      expect(first.zone, Zone.yellow);
      expect(first.phaseElapsed, Duration.zero);
      expect(first.remainingUntilAlarm, const Duration(seconds: 10));
      final later = machine.onSample(timestamp: ms(1600), levelDb: yellow);
      expect(later.phaseElapsed, ms(500));
      expect(later.remainingUntilAlarm, ms(9500));
    });
  });
}

void tenSecondRuleTests() {
  group('10 second rule', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    for (final level in [yellow, red]) {
      test('fires at exactly 10 s, not at 9.9 s (level $level)', () {
        final snapshots = feed(machine, level, fromMs: 0, toMs: 9900);
        expect(fireCount(snapshots), 0);
        expect(snapshots.last.remainingUntilAlarm, ms(100));
        final at10 = machine.onSample(timestamp: ms(10000), levelDb: level);
        expect(at10.shouldFireAlarm, isTrue);
        expect(at10.alarmFiredInPhase, isTrue);
        expect(at10.remainingUntilAlarm, isNull);
        final at101 = machine.onSample(timestamp: ms(10100), levelDb: level);
        expect(at101.shouldFireAlarm, isFalse);
        expect(at101.alarmFiredInPhase, isTrue);
      });
    }

    test('fires with the first sample after 10 s (9.9 s then 10.1 s)', () {
      machine.onSample(timestamp: ms(0), levelDb: yellow);
      for (var t = 900; t <= 9900; t += 1000) {
        expect(
          machine.onSample(timestamp: ms(t), levelDb: yellow).shouldFireAlarm,
          isFalse,
        );
      }
      final at101 = machine.onSample(timestamp: ms(10100), levelDb: yellow);
      expect(at101.shouldFireAlarm, isTrue);
      expect(at101.phaseElapsed, ms(10100));
    });

    test('only one alarm per phase, even after minutes', () {
      final snapshots = feed(machine, red, fromMs: 0, toMs: 300000);
      expect(fireCount(snapshots), 1);
      expect(snapshots.last.alarmFiredInPhase, isTrue);
    });

    test('phase start is the first valid sample, not the machine start', () {
      final first = machine.onSample(timestamp: ms(5000), levelDb: yellow);
      expect(first.phaseElapsed, Duration.zero);
      expect(
        machine.onSample(timestamp: ms(14900), levelDb: yellow).shouldFireAlarm,
        isFalse,
      );
    });

    test('custom delay is honoured', () {
      machine = AlarmStateMachine(
        thresholds: Thresholds.defaults,
        alarmDelay: const Duration(seconds: 2),
      );
      final snapshots = feed(machine, red, fromMs: 0, toMs: 2000);
      expect(snapshots.last.shouldFireAlarm, isTrue);
      expect(fireCount(snapshots), 1);
    });
  });
}

void phaseChangeTests() {
  group('phase changes', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('yellow to red starts a new phase and timer', () {
      feed(machine, yellow, fromMs: 0, toMs: 9000);
      final red0 = machine.onSample(timestamp: ms(9100), levelDb: red);
      expect(red0.zone, Zone.red);
      expect(red0.phaseElapsed, Duration.zero);
      final snapshots = feed(machine, red, fromMs: 9200, toMs: 19000);
      expect(fireCount(snapshots), 0);
      expect(
        machine.onSample(timestamp: ms(19100), levelDb: red).shouldFireAlarm,
        isTrue,
      );
    });

    test('yellow ↔ red after an alarm gets a new fired flag', () {
      final yellowRun = feed(machine, yellow, fromMs: 0, toMs: 10000);
      expect(fireCount(yellowRun), 1);
      final redRun = feed(machine, red, fromMs: 10100, toMs: 20100);
      expect(fireCount(redRun), 1);
      final backToYellow = feed(machine, yellow, fromMs: 20200, toMs: 30200);
      expect(fireCount(backToYellow), 1);
    });

    test('return to green resets time and fired flag', () {
      feed(machine, yellow, fromMs: 0, toMs: 10000);
      final greenSnap = machine.onSample(timestamp: ms(10100), levelDb: green);
      expect(greenSnap.zone, Zone.green);
      expect(greenSnap.alarmFiredInPhase, isFalse);
      expect(greenSnap.remainingUntilAlarm, isNull);
      final again = feed(machine, yellow, fromMs: 10200, toMs: 20200);
      expect(fireCount(again), 1);
      expect(again.first.phaseElapsed, Duration.zero);
    });

    test('a single green sample interrupts the phase', () {
      feed(machine, yellow, fromMs: 0, toMs: 9000);
      machine.onSample(timestamp: ms(9100), levelDb: green);
      final snapshots = feed(machine, yellow, fromMs: 9200, toMs: 18000);
      expect(fireCount(snapshots), 0);
    });
  });
}

void gapTests() {
  group('gaps', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('a gap of exactly 1 s keeps continuity', () {
      machine.onSample(timestamp: ms(0), levelDb: yellow);
      var t = 0;
      AlarmSnapshot? last;
      while (t < 10000) {
        t += 1000;
        last = machine.onSample(timestamp: ms(t), levelDb: yellow);
      }
      expect(last!.shouldFireAlarm, isTrue);
      expect(last.phaseElapsed, const Duration(seconds: 10));
    });

    test('a gap of 1.001 s starts a new phase with the later sample', () {
      feed(machine, yellow, fromMs: 0, toMs: 9000);
      final after = machine.onSample(timestamp: ms(10001), levelDb: yellow);
      expect(after.shouldFireAlarm, isFalse);
      expect(after.phaseElapsed, Duration.zero);
      expect(after.alarmFiredInPhase, isFalse);
      final snapshots = feed(machine, yellow, fromMs: 10101, toMs: 19901);
      expect(fireCount(snapshots), 0);
      expect(
        machine.onSample(timestamp: ms(20001), levelDb: yellow).shouldFireAlarm,
        isTrue,
      );
    });

    test('a gap after an alarm allows a new alarm (new phase)', () {
      expect(fireCount(feed(machine, red, fromMs: 0, toMs: 10000)), 1);
      expect(fireCount(feed(machine, red, fromMs: 12000, toMs: 22000)), 1);
    });

    test('a timestamp going backwards breaks continuity', () {
      feed(machine, yellow, fromMs: 5000, toMs: 9000);
      final back = machine.onSample(timestamp: ms(4000), levelDb: yellow);
      expect(back.phaseElapsed, Duration.zero);
    });

    test('custom max gap is honoured', () {
      machine = AlarmStateMachine(
        thresholds: Thresholds.defaults,
        maxGap: ms(200),
      );
      machine.onSample(timestamp: ms(0), levelDb: yellow);
      expect(
        machine.onSample(timestamp: ms(300), levelDb: yellow).phaseElapsed,
        Duration.zero,
      );
    });
  });
}

void resetTests() {
  group('invalid samples, reset and thresholds', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('non-finite levels are ignored', () {
      feed(machine, yellow, fromMs: 0, toMs: 500);
      final nan = machine.onSample(timestamp: ms(600), levelDb: double.nan);
      expect(nan.phaseElapsed, ms(500));
      expect(nan.shouldFireAlarm, isFalse);
    });

    test('reset forgets the phase; restart begins a new phase', () {
      feed(machine, red, fromMs: 0, toMs: 9900);
      machine.reset();
      expect(machine.snapshot.zone, isNull);
      expect(machine.snapshot.alarmFiredInPhase, isFalse);
      final restarted = feed(machine, red, fromMs: 10000, toMs: 19900);
      expect(fireCount(restarted), 0);
      expect(restarted.first.phaseElapsed, Duration.zero);
    });

    test('changed thresholds classify differently in a new machine', () {
      final strict = AlarmStateMachine(
        thresholds: Thresholds(yellowDb: 40, redDb: 45),
      );
      expect(strict.onSample(timestamp: ms(0), levelDb: green).zone, Zone.red);
      expect(
        machine.onSample(timestamp: ms(0), levelDb: green).zone,
        Zone.green,
      );
      expect(strict.thresholds.redDb, 45);
    });
  });
}

void ownAlarmTests() {
  group('own alarm output', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('samples during the tone are ignored and never fire', () {
      feed(machine, red, fromMs: 0, toMs: 10000);
      machine.onAlarmOutputStarted();
      expect(machine.snapshot.suppressed, isTrue);
      expect(machine.snapshot.alarmFiredInPhase, isTrue);
      final during = feed(machine, red, fromMs: 10100, toMs: 40000);
      expect(fireCount(during), 0);
      expect(during.every((s) => s.suppressed), isTrue);
      expect(during.last.phaseElapsed, const Duration(seconds: 10));
    });

    test('after the tone a new phase starts with the next valid sample', () {
      feed(machine, red, fromMs: 0, toMs: 10000);
      machine.onAlarmOutputStarted();
      feed(machine, red, fromMs: 10100, toMs: 11000);
      machine.onAlarmOutputFinished();
      expect(machine.snapshot.zone, isNull);
      expect(machine.snapshot.suppressed, isFalse);
      final first = machine.onSample(timestamp: ms(11500), levelDb: red);
      expect(first.phaseElapsed, Duration.zero);
      expect(first.alarmFiredInPhase, isFalse);
      final after = feed(machine, red, fromMs: 11600, toMs: 21500);
      expect(fireCount(after), 1);
      expect(after.last.shouldFireAlarm, isTrue);
    });

    test('reset also ends a suppression', () {
      machine.onAlarmOutputStarted();
      machine.reset();
      expect(machine.snapshot.suppressed, isFalse);
      expect(machine.onSample(timestamp: ms(0), levelDb: red).zone, Zone.red);
    });
  });
}
