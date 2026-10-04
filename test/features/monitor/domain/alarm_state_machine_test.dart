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
      // Fresh machines: the first sample is adopted without hysteresis.
      Zone? first(double level) =>
          defaultMachine().onSample(timestamp: ms(0), levelDb: level).zone;
      expect(first(59.999), Zone.green);
      expect(first(60), Zone.yellow);
      expect(first(79.999), Zone.yellow);
      expect(first(80), Zone.red);
    });

    test('green never fires and has no countdown', () {
      final snapshots = feed(machine, green, fromMs: 0, toMs: 60000);
      expect(fireCount(snapshots), 0);
      expect(snapshots.last.zone, Zone.green);
      expect(snapshots.last.remainingUntilAlarm, isNull);
      expect(snapshots.last.phaseElapsed, Duration.zero);
    });

    test('entering yellow is confirmed at 0.5 s, timer from first sample', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      final first = machine.onSample(timestamp: ms(1100), levelDb: yellow);
      expect(first.zone, Zone.green);
      expect(first.phaseElapsed, Duration.zero);
      expect(first.remainingUntilAlarm, isNull);
      final confirmed = feed(machine, yellow, fromMs: 1200, toMs: 1500).last;
      expect(confirmed.zone, Zone.yellow);
      expect(confirmed.phaseElapsed, ms(400));
      expect(confirmed.remainingUntilAlarm, ms(9600));
      feed(machine, yellow, fromMs: 1600, toMs: 2100);
      final later = machine.onSample(timestamp: ms(2600), levelDb: yellow);
      expect(later.phaseElapsed, ms(1500));
      expect(later.remainingUntilAlarm, ms(8500));
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
      expect(fireCount(feed(machine, yellow, fromMs: 0, toMs: 9900)), 0);
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

    test('yellow to red starts a new, backdated phase and timer', () {
      feed(machine, yellow, fromMs: 0, toMs: 5000);
      final pending = feed(machine, red, fromMs: 5100, toMs: 5400);
      expect(pending.every((s) => s.zone == Zone.yellow), isTrue);
      final red0 = machine.onSample(timestamp: ms(5500), levelDb: red);
      expect(red0.zone, Zone.red);
      expect(red0.phaseElapsed, ms(400));
      expect(red0.alarmFiredInPhase, isFalse);
      feed(machine, red, fromMs: 5600, toMs: 6100);
      final snapshots = feed(machine, red, fromMs: 6200, toMs: 15000);
      expect(fireCount(snapshots), 0);
      expect(
        machine.onSample(timestamp: ms(15100), levelDb: red).shouldFireAlarm,
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

    test('confirmed return to green resets time and fired flag', () {
      feed(machine, yellow, fromMs: 0, toMs: 10000);
      final greenSnap = feed(machine, green, fromMs: 10100, toMs: 12600).last;
      expect(greenSnap.zone, Zone.green);
      expect(greenSnap.alarmFiredInPhase, isFalse);
      expect(greenSnap.remainingUntilAlarm, isNull);
      expect(greenSnap.phaseElapsed, Duration.zero);
      final again = feed(machine, yellow, fromMs: 12700, toMs: 22700);
      expect(fireCount(again), 1);
      expect(again.last.shouldFireAlarm, isTrue);
      expect(again.first.phaseElapsed, Duration.zero);
      expect(again[10].phaseElapsed, ms(1000));
    });

    test('a single green sample does not interrupt the phase', () {
      feed(machine, yellow, fromMs: 0, toMs: 9000);
      final blip = machine.onSample(timestamp: ms(9100), levelDb: green);
      expect(blip.zone, Zone.yellow);
      final snapshots = feed(machine, yellow, fromMs: 9200, toMs: 10000);
      expect(fireCount(snapshots), 1);
      expect(snapshots.last.shouldFireAlarm, isTrue);
    });
  });
}

void gapTests() {
  group('gaps', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('a gap of exactly 1 s keeps continuity', () {
      feed(machine, yellow, fromMs: 0, toMs: 5000);
      final kept = machine.onSample(timestamp: ms(6000), levelDb: yellow);
      expect(kept.phaseElapsed, ms(6000));
      final rest = feed(machine, yellow, fromMs: 6100, toMs: 10000);
      expect(rest.last.shouldFireAlarm, isTrue);
    });

    test('samples only every 1 s are too thin: no alarm, re-adopted', () {
      final run = [
        for (var t = 0; t <= 30000; t += 1000)
          machine.onSample(timestamp: ms(t), levelDb: yellow),
      ];
      expect(fireCount(run), 0);
      expect(run.last.phaseElapsed, lessThan(const Duration(seconds: 5)));
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
