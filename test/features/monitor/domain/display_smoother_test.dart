// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/display_smoother.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  late DisplaySmoother smoother;

  setUp(() => smoother = DisplaySmoother());

  test('takes the first sample directly', () {
    expect(smoother.value, isNull);
    expect(smoother.add(timestamp: ms(0), levelDb: 50), 50);
    expect(smoother.value, 50);
    expect(smoother.timeConstant, ms(300));
  });

  test('reaches ~63 % of a step after one time constant', () {
    smoother.add(timestamp: ms(0), levelDb: 0);
    final value = smoother.add(timestamp: ms(300), levelDb: 100)!;
    expect(value, closeTo(100 * (1 - math.exp(-1)), 1e-9));
  });

  test('is independent of the sample rate', () {
    final coarse = DisplaySmoother()..add(timestamp: ms(0), levelDb: 0);
    final fine = DisplaySmoother()..add(timestamp: ms(0), levelDb: 0);
    coarse.add(timestamp: ms(400), levelDb: 100);
    for (var t = 50; t <= 400; t += 50) {
      fine.add(timestamp: ms(t), levelDb: 100);
    }
    expect(fine.value, closeTo(coarse.value!, 1e-9));
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
