// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Zone hysteresis inside the alarm machine (ADR 0004), with fake
// timestamps only. Samples are 100 ms apart unless stated otherwise.

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/alarm_state_machine.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

const double green = 50;
const double yellow = 70;
const double red = 90;

Duration ms(int value) => Duration(milliseconds: value);

List<AlarmSnapshot> feed(
  AlarmStateMachine machine,
  double level, {
  required int fromMs,
  required int toMs,
}) => cycle(machine, [level], fromMs: fromMs, toMs: toMs);

/// Repeats [level] [count] times (for readable cycles).
List<double> rep(double level, int count) => List.filled(count, level);

/// Feeds the repeating [levels] every [stepMs] from [fromMs] to [toMs].
List<AlarmSnapshot> cycle(
  AlarmStateMachine machine,
  List<double> levels, {
  required int fromMs,
  required int toMs,
  int stepMs = 100,
}) => [
  for (var t = fromMs, i = 0; t <= toMs; t += stepMs, i++)
    machine.onSample(timestamp: ms(t), levelDb: levels[i % levels.length]),
];

int fireCount(Iterable<AlarmSnapshot> snapshots) =>
    snapshots.where((s) => s.shouldFireAlarm).length;

/// Timestamp (ms) of the snapshot that fired, given the feed start.
int firedAtMs(List<AlarmSnapshot> snapshots, int fromMs) =>
    fromMs + 100 * snapshots.indexWhere((s) => s.shouldFireAlarm);

void main() {
  steadyTests();
  patternTests();
  flickerTests();
  dipTests();
  burstTests();
  tailTests();
  sparseTests();
  gapResetAndSuppressionTests();
}

AlarmStateMachine defaultMachine() =>
    AlarmStateMachine(thresholds: Thresholds.defaults);

void steadyTests() {
  group('steady changes', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('defaults; alarm delay shorter than hold time is rejected', () {
      expect(machine.holdTime, const Duration(seconds: 1));
      expect(
        () => AlarmStateMachine(
          thresholds: Thresholds.defaults,
          alarmDelay: ms(999),
        ),
        throwsArgumentError,
      );
      final equal = AlarmStateMachine(
        thresholds: Thresholds.defaults,
        alarmDelay: const Duration(seconds: 1),
      );
      expect(equal.alarmDelay, equal.holdTime);
    });

    test('first sample after start is adopted immediately', () {
      final first = machine.onSample(timestamp: ms(0), levelDb: red);
      expect(first.zone, Zone.red);
      expect(first.phaseElapsed, Duration.zero);
      expect(first.remainingUntilAlarm, const Duration(seconds: 10));
      expect(first.zoneSettled, isFalse);
    });

    test('green → red: confirmed at 0.5 s, alarm at 10.0 s raw red time', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      final run = feed(machine, red, fromMs: 1100, toMs: 12000);
      expect(run[3].zone, Zone.green); // 0.4 s
      expect(run[4].zone, Zone.red); // 0.5 s
      expect(run[4].phaseElapsed, ms(400));
      expect(run[4].remainingUntilAlarm, ms(9600));
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 1100), 11100);
    });

    test('exact threshold samples belong to the higher zone', () {
      feed(machine, 59.999, fromMs: 0, toMs: 1000);
      expect(feed(machine, 80, fromMs: 1100, toMs: 2000).last.zone, Zone.red);
    });
  });
}

void patternTests() {
  group('review patterns', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('P1: 0.8 s red / 0.2 s green from green → red and alarms', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      // Starts with a dip: red runs begin at 1300, 2300, …
      const levels = [green, green, red, red, red, red, red, red, red, red];
      final run = cycle(machine, levels, fromMs: 1100, toMs: 30000);
      final confirmedAt = run.indexWhere((s) => s.zone == Zone.red);
      expect(1100 + 100 * confirmedAt, 1700); // red covers (1200, 1700]
      expect(run[confirmedAt].phaseElapsed, ms(400)); // run start 1300
      expect(run.skip(confirmedAt).every((s) => s.zone == Zone.red), isTrue);
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 1100), 11300); // latest red run start + 10 s
    });

    test('P2: green/yellow alternating from green → yellow and alarms', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      final run = cycle(machine, [yellow, green], fromMs: 1100, toMs: 20000);
      expect(run[7].zone, Zone.green);
      expect(run[8].zone, Zone.yellow); // t = 1900
      expect(run.skip(8).every((s) => s.zone == Zone.yellow), isTrue);
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 1100), 11900);
    });

    test('P3: confirmed yellow + 7 green : 1 red → green, no red alarm', () {
      feed(machine, yellow, fromMs: 0, toMs: 2000);
      const levels = [green, green, green, green, green, green, green, red];
      final run = cycle(machine, levels, fromMs: 2100, toMs: 60000);
      expect(run.every((s) => s.zone != Zone.red), isTrue);
      expect(run.skip(28).every((s) => s.zone == Zone.green), isTrue);
      expect(fireCount(run), 0);
    });

    test('P5: red, 0.9 s green, steady yellow from 2.9 s → alarm 12.9 s', () {
      feed(machine, red, fromMs: 0, toMs: 2000);
      feed(machine, green, fromMs: 2100, toMs: 2800);
      final run = feed(machine, yellow, fromMs: 2900, toMs: 14000);
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 2900), 12900);
    });
  });
}

void flickerTests() {
  group('flicker', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('yellow/red flicker from green → red, alarm 10 s after its run', () {
      feed(machine, green, fromMs: 0, toMs: 1000);
      final run = cycle(machine, [yellow, red], fromMs: 1100, toMs: 20000);
      final confirmedAt = run.indexWhere((s) => s.zone == Zone.red);
      final runStartMs = 1100 + 100 * confirmedAt; // single red sample
      expect(run[confirmedAt].phaseElapsed, Duration.zero);
      expect(run.skip(confirmedAt).every((s) => s.zone == Zone.red), isTrue);
      expect(firedAtMs(run, 1100), runStartMs + 10000);
    });

    test('confirmed red + yellow/red flicker stays red, alarms at 10 s', () {
      final run = cycle(
        machine,
        [red, yellow, red, yellow, yellow, red, red],
        fromMs: 0,
        toMs: 30000,
      );
      expect(run.every((s) => s.zone == Zone.red), isTrue);
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 0), 10000);
    });

    test('confirmed yellow + 1 red : 2 yellow alarms in yellow at 10 s', () {
      final run = cycle(machine, [yellow, yellow, red], fromMs: 0, toMs: 30000);
      expect(run.every((s) => s.zone == Zone.yellow), isTrue);
      expect(fireCount(run), 1);
      expect(firedAtMs(run, 0), 10000);
    });
  });
}

void dipTests() {
  group('dips', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('green dip of 0.7 s does not reset a red phase', () {
      feed(machine, red, fromMs: 0, toMs: 5000);
      final dip = feed(machine, green, fromMs: 5100, toMs: 5700);
      expect(dip.every((s) => s.zone == Zone.red), isTrue);
      final rest = feed(machine, red, fromMs: 5800, toMs: 11000);
      expect(firedAtMs(rest, 5800), 10000);
    });

    test('a 2.4 s pause does not reset a red phase', () {
      feed(machine, red, fromMs: 0, toMs: 5000);
      final pause = feed(machine, green, fromMs: 5100, toMs: 7500);
      expect(pause.every((s) => s.zone == Zone.red), isTrue);
      final rest = feed(machine, red, fromMs: 7600, toMs: 11000);
      expect(firedAtMs(rest, 7600), 10000);
    });

    test('steady green for 2.5 s resets the red phase', () {
      feed(machine, red, fromMs: 0, toMs: 5000);
      final held = feed(machine, green, fromMs: 5100, toMs: 7600).last;
      expect(held.zone, Zone.green);
      expect(held.phaseElapsed, Duration.zero);
      expect(held.remainingUntilAlarm, isNull);
      expect(held.zoneSettled, isTrue);
      final again = feed(machine, red, fromMs: 7700, toMs: 19000);
      expect(firedAtMs(again, 7700), 17700);
    });

    test('steady yellow after red: yellow phase from the first yellow', () {
      feed(machine, red, fromMs: 0, toMs: 12000);
      final run = feed(machine, yellow, fromMs: 12100, toMs: 25000);
      expect(run[24].zone, Zone.red);
      expect(run[25].zone, Zone.yellow); // t = 14600
      expect(run[25].phaseElapsed, ms(2500));
      expect(run[25].alarmFiredInPhase, isFalse);
      expect(firedAtMs(run, 12100), 22100);
    });

    test('red phase survives a 0.8 s stall with one green sample', () {
      feed(machine, red, fromMs: 0, toMs: 8000);
      expect(
        machine.onSample(timestamp: ms(8800), levelDb: green).zone,
        Zone.red,
      );
      final rest = feed(machine, red, fromMs: 8900, toMs: 11000);
      expect(firedAtMs(rest, 8900), 10000);
    });
  });
}

void burstTests() {
  group('bursts (fast attack, slow release)', () {
    for (final (name, levels, stepMs) in [
      ('red 1.2 s / green 0.8 s', [...rep(red, 12), ...rep(green, 8)], 100),
      ('red 1 s / green 1 s', [...rep(red, 10), ...rep(green, 10)], 100),
      ('red 0.6 s / green 1.4 s', [...rep(red, 6), ...rep(green, 14)], 100),
      ('red 40 % at 1.25 s period', [...rep(red, 10), ...rep(green, 15)], 50),
    ]) {
      test('$name: red, <= 2 changes per minute, alarm 10 s after burst', () {
        final machine = defaultMachine();
        feed(machine, green, fromMs: 0, toMs: 3000);
        final run = cycle(
          machine,
          levels,
          fromMs: 3100,
          toMs: 63000,
          stepMs: stepMs,
        );
        var changes = 0;
        for (var i = 1; i < run.length; i++) {
          if (run[i].zone != run[i - 1].zone) changes++;
        }
        expect(changes, lessThanOrEqualTo(2));
        expect(fireCount(run), 1);
        final fired = run.indexWhere((s) => s.shouldFireAlarm);
        expect(3100 + stepMs * fired, 13100);
      });
    }
  });
}

void gapResetAndSuppressionTests() {
  group('gap, reset and suppression', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('a gap > 1 s resets the hysteresis: next zone is immediate', () {
      feed(machine, yellow, fromMs: 0, toMs: 3000);
      final afterGap = machine.onSample(timestamp: ms(4001), levelDb: red);
      expect(afterGap.zone, Zone.red);
      expect(afterGap.phaseElapsed, Duration.zero);
      final run = feed(machine, red, fromMs: 4101, toMs: 15000);
      expect(firedAtMs(run, 4101), 14001);
    });

    test('reset clears the window', () {
      feed(machine, yellow, fromMs: 0, toMs: 500);
      feed(machine, red, fromMs: 600, toMs: 900);
      machine.reset();
      final first = machine.onSample(timestamp: ms(1000), levelDb: green);
      expect(first.zone, Zone.green);
      expect(first.phaseElapsed, Duration.zero);
    });

    test('suppression freezes the zone; afterwards immediate, unsettled', () {
      feed(machine, red, fromMs: 0, toMs: 10000);
      machine.onAlarmOutputStarted();
      final during = feed(machine, green, fromMs: 10100, toMs: 13000);
      expect(during.every((s) => s.zone == Zone.red && s.suppressed), isTrue);
      expect(fireCount(during), 0);
      machine.onAlarmOutputFinished();
      final first = machine.onSample(timestamp: ms(13100), levelDb: green);
      expect(first.zone, Zone.green);
      expect(first.suppressed, isFalse);
      expect(first.zoneSettled, isFalse);
      final held = feed(machine, green, fromMs: 13200, toMs: 14600);
      expect(held[13].zoneSettled, isFalse); // 1.4 s covered
      expect(held[14].zoneSettled, isTrue); // 1.5 s covered
    });
  });
}

void tailTests() {
  group('quiet tail does not count', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('red 8 s then silence: no alarm, elapsed frozen at 8 s', () {
      feed(machine, red, fromMs: 0, toMs: 8000);
      final tail = feed(machine, green, fromMs: 8100, toMs: 20000);
      expect(fireCount(tail), 0);
      expect(tail[24].zone, Zone.red); // 2.4 s of silence: still red
      expect(tail[24].phaseElapsed, const Duration(seconds: 8));
      expect(tail[24].remainingUntilAlarm, const Duration(seconds: 2));
      expect(tail.last.zone, Zone.green);
    });

    test('3 s loud then 16.7 % clicks: alarm only on a click sample', () {
      feed(machine, red, fromMs: 0, toMs: 3000);
      final clicks = cycle(
        machine,
        [...rep(green, 5), red],
        fromMs: 3100,
        toMs: 30000,
      );
      expect(clicks.every((s) => s.zone == Zone.red), isTrue);
      expect(fireCount(clicks), 1);
      // Clicks at 3600, 4200, …: the first one at or after 10 s is 10200.
      expect(firedAtMs(clicks, 3100), 10200);
      expect(clicks[(10100 - 3100) ~/ 100].phaseElapsed, ms(9600));
    });

    test('0.5 s shouts every 3 s hold red and alarm (owner decision)', () {
      feed(machine, green, fromMs: 0, toMs: 3000);
      final run = cycle(
        machine,
        [...rep(red, 5), ...rep(green, 25)],
        fromMs: 3100,
        toMs: 40000,
      );
      final confirmedAt = run.indexWhere((s) => s.zone == Zone.red);
      expect(run.skip(confirmedAt).every((s) => s.zone == Zone.red), isTrue);
      expect(fireCount(run), 1);
      // Shouts at 3100–3500, 6100–6500, …; the shout ending 12500 reaches
      // 9.4 s, so the next shout sample (15100) fires.
      expect(firedAtMs(run, 3100), 15100);
    });
  });
}

void sparseTests() {
  group('sparse samples', () {
    late AlarmStateMachine machine;
    setUp(() => machine = defaultMachine());

    test('red until 5 s, then green every 1 s: no alarm, becomes green', () {
      feed(machine, red, fromMs: 0, toMs: 5000);
      final sparse = [
        for (var t = 6000; t <= 20000; t += 1000)
          machine.onSample(timestamp: ms(t), levelDb: green),
      ];
      expect(fireCount(sparse), 0);
      expect(sparse.last.zone, Zone.green);
    });

    test('red continuing every 1 s: thin data never fires', () {
      feed(machine, red, fromMs: 0, toMs: 5000);
      final sparse = [
        for (var t = 6000; t <= 40000; t += 1000)
          machine.onSample(timestamp: ms(t), levelDb: red),
      ];
      expect(fireCount(sparse), 0);
      // The blocked countdown never goes negative.
      expect(
        sparse.every((s) => !(s.remainingUntilAlarm?.isNegative ?? false)),
        isTrue,
      );
    });
  });
}
