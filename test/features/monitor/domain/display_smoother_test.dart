// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/display_smoother.dart';
import 'package:raumfreund/features/monitor/domain/level_history.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  late DisplaySmoother smoother;

  setUp(() => smoother = DisplaySmoother());

  test('takes the first sample directly', () {
    expect(smoother.value, isNull);
    expect(smoother.add(timestamp: ms(0), levelDb: 50), 50);
    expect(smoother.value, 50);
    expect(smoother.attack, ms(100));
    expect(smoother.release, ms(1000));
  });

  test('rises quickly: ~63 % of a step after one 100 ms reading', () {
    smoother.add(timestamp: ms(0), levelDb: 0);
    final value = smoother.add(timestamp: ms(100), levelDb: 100)!;
    expect(value, closeTo(100 * (1 - math.exp(-1)), 1e-9));
    for (var t = 200; t <= 300; t += 100) {
      smoother.add(timestamp: ms(t), levelDb: 100);
    }
    expect(smoother.value, greaterThan(95));
  });

  test('falls slower than it rises (~63 % of a drop after 1 s)', () {
    smoother.add(timestamp: ms(0), levelDb: 100);
    for (var t = 100; t <= 1000; t += 100) {
      smoother.add(timestamp: ms(t), levelDb: 0);
    }
    expect(smoother.value, closeTo(100 * math.exp(-1), 1e-9));
  });

  test('gauge release is faster than the timeline release', () {
    expect(
      DisplaySmoother.defaultRelease,
      lessThan(LevelHistory.envelopeRelease),
    );
  });

  test('custom time constants are honoured', () {
    final custom = DisplaySmoother(attack: Duration.zero, release: ms(500));
    custom.add(timestamp: ms(0), levelDb: 10);
    expect(custom.add(timestamp: ms(10), levelDb: 80), 80);
  });

  test('ignores non-finite samples and non-advancing time', () {
    smoother.add(timestamp: ms(0), levelDb: 40);
    expect(smoother.add(timestamp: ms(100), levelDb: double.nan), 40);
    expect(smoother.add(timestamp: ms(0), levelDb: 90), 40);
  });

  test('reset forgets the state', () {
    smoother
      ..add(timestamp: ms(0), levelDb: 40)
      ..reset();
    expect(smoother.value, isNull);
    expect(smoother.add(timestamp: ms(5000), levelDb: 80), 80);
  });
}
