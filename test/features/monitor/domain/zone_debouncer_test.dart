// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/domain/zone_debouncer.dart';

Duration ms(int value) => Duration(milliseconds: value);

const g = Zone.green;
const y = Zone.yellow;
const r = Zone.red;

/// Feeds [zone] every 100 ms from [fromMs] to [toMs] (both inclusive).
List<ZoneDecision> feed(
  ZoneDebouncer debouncer,
  Zone zone, {
  required int fromMs,
  required int toMs,
}) => cycle(debouncer, [zone], fromMs: fromMs, toMs: toMs);

/// Feeds the repeating [cycle] every [stepMs] from [fromMs] to [toMs].
List<ZoneDecision> cycle(
  ZoneDebouncer debouncer,
  List<Zone> cycle, {
  required int fromMs,
  required int toMs,
  int stepMs = 100,
}) => [
  for (var t = fromMs, i = 0; t <= toMs; t += stepMs, i++)
    debouncer.onSample(timestamp: ms(t), zone: cycle[i % cycle.length]),
];

/// Repeats [count] times [zone] (for readable cycles).
List<Zone> times(Zone zone, int count) => List.filled(count, zone);

void main() {
  basicTests();
  attackTests();
  releaseTests();
  patternTests();
  stallTests();
  dutyTests();
  gapAndResetTests();
  settleTests();
}

void basicTests() {
  group('basics', () {
    test('defaults and validation', () {
      final d = ZoneDebouncer();
      expect(d.holdTime, const Duration(seconds: 1));
      expect(d.releaseTime, const Duration(seconds: 3));
      expect(d.maxGap, const Duration(seconds: 1));
      expect(d.maxSampleWeight, ms(200));
      expect(d.enterShare, 0.5);
      expect(d.leaveShare, 0.15);
      expect(d.zone, isNull);
      expect(() => ZoneDebouncer(holdTime: Duration.zero), throwsArgumentError);
      expect(
        () => ZoneDebouncer(maxSampleWeight: Duration.zero),
        throwsArgumentError,
      );
      expect(() => ZoneDebouncer(releaseTime: ms(500)), throwsArgumentError);
      expect(() => ZoneDebouncer(leaveShare: 0), throwsArgumentError);
      expect(() => ZoneDebouncer(enterShare: 1.1), throwsArgumentError);
    });

    test('the first sample is adopted immediately, not settled', () {
      final d = ZoneDebouncer();
      final first = d.onSample(timestamp: ms(500), zone: r);
      expect(first.zone, r);
      expect(first.since, ms(500));
      expect(first.started, isTrue);
      expect(first.settled, isFalse);
      final next = d.onSample(timestamp: ms(600), zone: r);
      expect(next.started, isFalse);
      expect(next.since, ms(500));
    });

    test('the adopted zone is held for the hold time', () {
      final d = ZoneDebouncer();
      d.onSample(timestamp: ms(0), zone: g);
      final early = feed(d, r, fromMs: 100, toMs: 900);
      expect(early.every((x) => x.zone == g), isTrue);
      final at1s = d.onSample(timestamp: ms(1000), zone: r);
      expect(at1s.zone, r);
      expect(at1s.since, ms(100));
    });

    test('memory is bounded by the release window', () {
      final d = ZoneDebouncer();
      cycle(d, [g, y, r], fromMs: 0, toMs: 60000);
      expect(d.windowLength, lessThanOrEqualTo(30));
    });
  });
}

void attackTests() {
  group('attack (fast)', () {
    for (final (from, to) in [(g, r), (g, y), (y, r)]) {
      test('$from → $to: confirmed at 50 % of 1 s, since first sample', () {
        final d = ZoneDebouncer();
        feed(d, from, fromMs: 0, toMs: 3000);
        final pending = feed(d, to, fromMs: 3100, toMs: 3400);
        expect(pending.every((x) => x.zone == from), isTrue);
        final confirmed = d.onSample(timestamp: ms(3500), zone: to);
        expect(confirmed.zone, to);
        expect(confirmed.since, ms(3100));
        expect(confirmed.started, isTrue);
        expect(confirmed.settled, isTrue);
      });
    }

    test('up to red waits for a red sample; phase starts there', () {
      final d = ZoneDebouncer();
      d.onSample(timestamp: ms(0), zone: g);
      feed(d, r, fromMs: 100, toMs: 900); // held: adopted < 1 s ago
      // Red 80 %, but this sample is yellow: wait.
      expect(d.onSample(timestamp: ms(1000), zone: y).zone, g);
      final confirmed = d.onSample(timestamp: ms(1100), zone: r);
      expect(confirmed.zone, r);
      expect(confirmed.since, ms(1100));
    });

    test('the highest zone with 50 % wins', () {
      final d = ZoneDebouncer();
      feed(d, g, fromMs: 0, toMs: 3000);
      feed(d, r, fromMs: 3100, toMs: 3400);
      // Red 0.4 + this yellow 0.1 → red 40 %: yellow (50 %) confirmed.
      final atYellow = d.onSample(timestamp: ms(3500), zone: y);
      expect(atYellow.zone, y);
      final d2 = ZoneDebouncer();
      feed(d2, g, fromMs: 0, toMs: 3000);
      feed(d2, r, fromMs: 3100, toMs: 3500);
      expect(d2.zone, r);
    });
  });
}

void releaseTests() {
  group('release (slow)', () {
    for (final (from, to) in [(r, g), (y, g), (r, y)]) {
      test('$from → $to after 2.5 s of steady $to', () {
        final d = ZoneDebouncer();
        feed(d, from, fromMs: 0, toMs: 5000);
        final pending = feed(d, to, fromMs: 5100, toMs: 7500);
        expect(pending.every((x) => x.zone == from), isTrue);
        final confirmed = d.onSample(timestamp: ms(7600), zone: to);
        expect(confirmed.zone, to);
        expect(confirmed.started, isTrue);
        if (to == y) expect(confirmed.since, ms(5100));
      });
    }

    test('down to yellow waits for a yellow sample', () {
      final d = ZoneDebouncer();
      feed(d, r, fromMs: 0, toMs: 5000);
      feed(d, y, fromMs: 5100, toMs: 7000);
      final waiting = feed(d, g, fromMs: 7100, toMs: 7800);
      expect(waiting.every((x) => x.zone == r), isTrue);
      final confirmed = d.onSample(timestamp: ms(7900), zone: y);
      expect(confirmed.zone, y);
      expect(confirmed.since, ms(7900));
    });
  });
}

/// Feeds 3 s of green, then [pattern] for 60 s; returns the decisions of
/// the pattern part.
List<ZoneDecision> afterGreen(List<Zone> pattern, {int stepMs = 100}) {
  final d = ZoneDebouncer();
  feed(d, g, fromMs: 0, toMs: 3000);
  return cycle(d, pattern, fromMs: 3100, toMs: 63000, stepMs: stepMs);
}

int changes(List<ZoneDecision> decisions) {
  var count = 0;
  for (var i = 1; i < decisions.length; i++) {
    if (decisions[i].zone != decisions[i - 1].zone) count++;
  }
  return count;
}

void patternTests() {
  group('patterns', () {
    for (final (name, pattern, stepMs) in [
      ('red 1.2 s / green 0.8 s', [...times(r, 12), ...times(g, 8)], 100),
      ('red 1 s / green 1 s', [...times(r, 10), ...times(g, 10)], 100),
      ('red 0.6 s / green 1.4 s', [...times(r, 6), ...times(g, 14)], 100),
      ('red 40 % at 1.25 s period', [...times(r, 10), ...times(g, 15)], 50),
      ('P1: red 0.8 s / green 0.2 s', [...times(r, 8), ...times(g, 2)], 100),
    ]) {
      test('$name from green → red once, stays red', () {
        final out = afterGreen(pattern, stepMs: stepMs);
        final first = out.indexWhere((x) => x.zone == r);
        expect(first, greaterThanOrEqualTo(0));
        expect(out[first].since, ms(3100));
        expect(out.skip(first).every((x) => x.zone == r), isTrue);
        expect(changes(out), lessThanOrEqualTo(2));
      });
    }

    test('P2: green/yellow alternating from green → yellow, stays', () {
      final out = afterGreen([y, g]);
      expect(out[7].zone, g); // t = 3800
      expect(out[8].zone, y); // t = 3900: fifth yellow interval
      expect(out[8].since, ms(3900));
      expect(out.skip(8).every((x) => x.zone == y), isTrue);
    });

    test('P3: confirmed yellow + 7 green : 1 red → green, never red', () {
      final d = ZoneDebouncer();
      feed(d, y, fromMs: 0, toMs: 2000);
      final out = cycle(d, [...times(g, 7), r], fromMs: 2100, toMs: 60000);
      expect(out.every((x) => x.zone != r), isTrue);
      expect(out[27].zone, y); // t = 4800: 16.7 %
      expect(out[28].zone, g); // t = 4900: 13.3 %
      expect(out.skip(28).every((x) => x.zone == g), isTrue);
    });

    test('yellow/red flicker from green → red', () {
      final out = afterGreen([y, r]);
      expect(out[9].zone, r); // t = 4000: fifth red interval
      expect(out.skip(9).every((x) => x.zone == r), isTrue);
    });

    test('confirmed red + yellow/red flicker stays red', () {
      final d = ZoneDebouncer();
      feed(d, r, fromMs: 0, toMs: 2000);
      final out = cycle(d, [y, r, y, y, r, r, y], fromMs: 2100, toMs: 30000);
      expect(out.every((x) => x.zone == r), isTrue);
    });

    test('confirmed yellow: 1 red : 2 yellow stays, 1 : 1 goes red', () {
      final d = ZoneDebouncer();
      feed(d, y, fromMs: 0, toMs: 2000);
      final mild = cycle(d, [y, y, r], fromMs: 2100, toMs: 30000);
      expect(mild.every((x) => x.zone == y), isTrue);
      final loud = cycle(d, [r, y], fromMs: 30100, toMs: 40000);
      expect(loud.last.zone, r);
    });
  });
}

void stallTests() {
  group('stalls (sample weight capped at 200 ms)', () {
    test('0.6 s stall + one red sample is no instant red', () {
      final d = ZoneDebouncer();
      feed(d, g, fromMs: 0, toMs: 3000);
      expect(d.onSample(timestamp: ms(3600), zone: r).zone, g); // 33 %
      final red = d.onSample(timestamp: ms(3700), zone: r); // 50 %
      expect(red.zone, r);
      expect(red.since, ms(3600));
    });

    test('0.8 s stall + one green sample keeps red', () {
      final d = ZoneDebouncer();
      feed(d, r, fromMs: 0, toMs: 8000);
      expect(d.onSample(timestamp: ms(8800), zone: g).zone, r);
      final after = feed(d, r, fromMs: 8900, toMs: 12000);
      expect(after.every((x) => x.zone == r && !x.started), isTrue);
    });

    test('decisions need half of the window covered', () {
      final d = ZoneDebouncer();
      feed(d, g, fromMs: 0, toMs: 3000);
      // 0.9 s stall: the attack window covers only 0.3 s, then 0.4 s.
      expect(d.onSample(timestamp: ms(3900), zone: r).zone, g);
      expect(d.onSample(timestamp: ms(4000), zone: r).zone, g);
      expect(d.onSample(timestamp: ms(4100), zone: r).zone, g);
      final usable = d.onSample(timestamp: ms(4200), zone: r);
      expect(usable.zone, r);
      expect(usable.since, ms(3900));
    });
  });
}

void gapAndResetTests() {
  group('gaps and reset', () {
    test('a gap of exactly maxGap keeps continuity (no adoption)', () {
      final d = ZoneDebouncer();
      feed(d, g, fromMs: 0, toMs: 3000);
      final kept = d.onSample(timestamp: ms(4000), zone: r);
      expect(kept.zone, g);
      expect(kept.started, isFalse);
    });

    test('a gap over maxGap adopts the raw zone immediately', () {
      final d = ZoneDebouncer();
      feed(d, y, fromMs: 0, toMs: 3000);
      final afterGap = d.onSample(timestamp: ms(4001), zone: g);
      expect(afterGap.zone, g);
      expect(afterGap.since, ms(4001));
      expect(afterGap.started, isTrue);
      expect(afterGap.settled, isFalse);
      expect(d.windowLength, 0);
      final early = feed(d, r, fromMs: 4101, toMs: 4901);
      expect(early.every((x) => x.zone == g), isTrue);
    });

    test('a timestamp going backwards breaks continuity', () {
      final d = ZoneDebouncer();
      feed(d, y, fromMs: 5000, toMs: 6000);
      final back = d.onSample(timestamp: ms(4000), zone: r);
      expect(back.zone, r);
      expect(back.started, isTrue);
    });

    test('equal timestamps add no time', () {
      final d = ZoneDebouncer();
      feed(d, g, fromMs: 0, toMs: 3000);
      for (var i = 0; i < 20; i++) {
        d.onSample(timestamp: ms(3000), zone: r);
      }
      expect(d.zone, g);
    });

    test('reset clears zone and samples', () {
      final d = ZoneDebouncer();
      feed(d, y, fromMs: 0, toMs: 1500);
      d.reset();
      expect(d.zone, isNull);
      expect(d.windowLength, 0);
      final first = d.onSample(timestamp: ms(1600), zone: g);
      expect(first.zone, g);
      expect(first.started, isTrue);
    });
  });
}

void settleTests() {
  group('settling of an adopted zone', () {
    for (final zone in Zone.values) {
      test('$zone settles once the release window is half covered', () {
        final d = ZoneDebouncer();
        final run = feed(d, zone, fromMs: 0, toMs: 1500);
        expect(run[14].settled, isFalse); // 1.4 s covered
        expect(run[15].settled, isTrue); // 1.5 s covered
      });
    }

    test('green with 30 % yellow stays green but unsettled', () {
      final d = ZoneDebouncer();
      final run = cycle(
        d,
        [g, y, g, y, g, g, y, g, g, g],
        fromMs: 0,
        toMs: 10000,
      );
      expect(run.every((x) => x.zone == g && !x.settled), isTrue);
    });

    test('green with 10 % yellow settles', () {
      final d = ZoneDebouncer();
      final run = cycle(d, [...times(g, 9), y], fromMs: 0, toMs: 3000);
      expect(run.last.zone, g);
      expect(run.last.settled, isTrue);
    });
  });
}

void dutyTests() {
  group('duty after a loud period (leave share 15 % over 3 s)', () {
    for (final (name, pattern, holds) in [
      ('clicks 1 in 8 (12.5 %)', [...times(g, 7), r], false),
      ('clicks 1 in 7 (14.3 %)', [...times(g, 6), r], false),
      ('clicks 1 in 6 (16.7 %)', [...times(g, 5), r], true),
      (
        '0.4 s shouts every 3 s (13.3 %)',
        [...times(r, 4), ...times(g, 26)],
        false,
      ),
      (
        '0.5 s shouts every 3 s (16.7 %)',
        [...times(r, 5), ...times(g, 25)],
        true,
      ),
    ]) {
      test('$name ${holds ? 'holds' : 'leaves'} red', () {
        final d = ZoneDebouncer();
        feed(d, r, fromMs: 0, toMs: 3000);
        final out = cycle(d, pattern, fromMs: 3100, toMs: 63000);
        expect(out.last.zone, holds ? r : g);
        expect(out.every((x) => x.zone == r), holds);
      });
    }
  });

  group('sparse continuous samples', () {
    test('windows unusable for more than 3 s count as a gap', () {
      final d = ZoneDebouncer();
      feed(d, r, fromMs: 0, toMs: 5000);
      final sparse = [
        for (var t = 6000; t <= 12000; t += 1000)
          d.onSample(timestamp: ms(t), zone: g),
      ];
      // 6000 usable; unusable from 7000; 11000 is more than 3 s later.
      expect(sparse[0].usable, isTrue);
      expect(sparse[1].usable, isFalse);
      expect(sparse.take(5).every((x) => x.zone == r), isTrue);
      expect(sparse[5].zone, g);
      expect(sparse[5].started, isTrue);
      expect(sparse[5].since, ms(11000));
    });
  });
}
