// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Thin signal of the ZoneDebouncer: readings too sparse to judge the room.

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/domain/zone_debouncer.dart';

Duration ms(int value) => Duration(milliseconds: value);

/// Feeds [zone] every [stepMs] from [fromMs] to [toMs] (both inclusive) and
/// returns the thin flag per timestamp in ms.
Map<int, bool> feed(
  ZoneDebouncer debouncer, {
  required int fromMs,
  required int toMs,
  int stepMs = 100,
  Zone zone = Zone.red,
}) => {
  for (var t = fromMs; t <= toMs; t += stepMs)
    t: debouncer.onSample(timestamp: ms(t), zone: zone).signalThin,
};

/// Flags at or after [fromMs].
List<bool> from(Map<int, bool> thin, int fromMs) => [
  for (final e in thin.entries)
    if (e.key >= fromMs) e.value,
];

/// Number of changes of the flag along [flags].
int toggles(Iterable<bool> flags) {
  var count = 0;
  bool? previous;
  for (final flag in flags) {
    if (previous != null && flag != previous) count++;
    previous = flag;
  }
  return count;
}

void main() {
  test('entry and clear times', () {
    expect(ZoneDebouncer.thinEnterTime, const Duration(seconds: 2));
    expect(ZoneDebouncer.thinClearTime, const Duration(seconds: 3));
  });
  rateTests();
  stallTests();
  recoveryTests();
  resetTests();
}

void rateTests() {
  group('signal thin by reading rate', () {
    test('10 Hz readings are never thin, also right after the start', () {
      final thin = feed(ZoneDebouncer(), fromMs: 0, toMs: 30000);
      expect(thin.values, everyElement(isFalse));
    });

    test('1 Hz readings become thin after 2 s of poor data', () {
      final thin = feed(ZoneDebouncer(), fromMs: 0, toMs: 20000, stepMs: 1000);
      // 0 s: nothing to judge; 1 s: first poor sample; 3 s: poor for 2 s.
      expect(thin[0], isFalse);
      expect(thin[2000], isFalse);
      expect(thin[3000], isTrue);
      // Stays thin, also across the debouncer's thin-data adoptions.
      expect(from(thin, 3000), everyElement(isTrue));
    });

    test('2 Hz readings (each covering 200 of 500 ms) are thin', () {
      final thin = feed(ZoneDebouncer(), fromMs: 0, toMs: 5000, stepMs: 500);
      expect(thin[2000], isFalse);
      expect(thin[2500], isTrue);
      expect(thin[5000], isTrue);
    });

    test('readings 1.5 s apart (every one a gap) are thin', () {
      final thin = feed(ZoneDebouncer(), fromMs: 0, toMs: 9000, stepMs: 1500);
      expect(thin[3000], isFalse);
      expect(thin[4500], isTrue);
      expect(thin[9000], isTrue);
    });

    test('3.3 Hz readings still cover enough and are not thin', () {
      final thin = feed(ZoneDebouncer(), fromMs: 0, toMs: 30000, stepMs: 300);
      expect(thin.values, everyElement(isFalse));
    });

    test('jittered 300–500 ms readings toggle at most once in 2 min', () {
      final d = ZoneDebouncer();
      // Deterministic linear congruential sequence of intervals.
      var seed = 12345;
      final flags = <bool>[];
      for (var t = 0; t <= 120000;) {
        flags.add(d.onSample(timestamp: ms(t), zone: Zone.red).signalThin);
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        t += 300 + seed % 201;
      }
      expect(toggles(flags), lessThanOrEqualTo(1));
    });

    test('the zone rules are unaffected by the thin signal', () {
      final d = ZoneDebouncer();
      final zones = [
        for (var t = 0; t <= 20000; t += 1000)
          d.onSample(timestamp: ms(t), zone: Zone.red).zone,
      ];
      expect(zones, everyElement(Zone.red));
    });
  });
}

void stallTests() {
  group('signal thin after single stalls', () {
    for (final stallMs in [1500, 2000, 3000, 5000]) {
      test('a $stallMs ms stall at 10 Hz never raises the hint', () {
        final d = ZoneDebouncer();
        final before = feed(d, fromMs: 0, toMs: 5000);
        final after = feed(d, fromMs: 5000 + stallMs, toMs: 20000);
        expect([...before.values, ...after.values], everyElement(isFalse));
      });
    }
  });
}

void recoveryTests() {
  group('signal thin recovery', () {
    test('recovers after 3 s of good (60 %) coverage at 10 Hz', () {
      final d = ZoneDebouncer();
      feed(d, fromMs: 0, toMs: 5000, stepMs: 1000);
      final thin = feed(d, fromMs: 5100, toMs: 15000);
      // 6.4 s: 60 % of the last 3 s are covered again; 3 s later it clears.
      expect(thin[6000], isTrue);
      expect(thin[9300], isTrue);
      expect(thin[9400], isFalse);
      expect(from(thin, 9400), everyElement(isFalse));
    });

    test('a short good stretch does not hide the hint (no flicker)', () {
      final d = ZoneDebouncer();
      feed(d, fromMs: 0, toMs: 5000, stepMs: 1000);
      // 1.2 s of 10 Hz: good from 6.1 s to 6.3 s only, then a 2 s stall
      // makes the next reading poor again before the clear time is reached.
      final burst = feed(d, fromMs: 5100, toMs: 6300);
      final sparse = feed(d, fromMs: 8300, toMs: 12300, stepMs: 1000);
      expect(burst.values, everyElement(isTrue));
      expect(sparse.values, everyElement(isTrue));
    });
  });
}

void resetTests() {
  group('signal thin reset', () {
    test('reset clears the thin signal and starts measuring afresh', () {
      final d = ZoneDebouncer();
      expect(feed(d, fromMs: 0, toMs: 5000, stepMs: 1000)[5000], isTrue);
      d.reset();
      final thin = feed(d, fromMs: 5100, toMs: 10000);
      expect(thin.values, everyElement(isFalse));
    });

    test('a timestamp going backwards restarts the coverage, keeps state', () {
      final d = ZoneDebouncer();
      expect(feed(d, fromMs: 0, toMs: 5000, stepMs: 1000)[5000], isTrue);
      final thin = feed(d, fromMs: 1000, toMs: 5000);
      // Good from the restart on; clear after 3 s of good readings.
      expect(thin[1000], isTrue);
      expect(thin[3900], isTrue);
      expect(thin[4000], isFalse);
    });
  });
}
