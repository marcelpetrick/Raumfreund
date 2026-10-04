// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/peak_envelope.dart';

Duration ms(int value) => Duration(milliseconds: value);

/// Expected value after an exponential release from [from] to [to].
double released(double from, double to, double seconds, double tau) =>
    to + (from - to) * math.exp(-seconds / tau);

void main() {
  late PeakEnvelope envelope;

  setUp(
    () => envelope = PeakEnvelope(
      attack: Duration.zero,
      release: const Duration(seconds: 4),
    ),
  );

  test('takes the first sample directly', () {
    expect(envelope.value, isNull);
    expect(envelope.add(timestamp: ms(0), levelDb: 40), 40);
    expect(envelope.value, 40);
  });

  test('zero attack follows a rise immediately', () {
    envelope.add(timestamp: ms(0), levelDb: 40);
    expect(envelope.add(timestamp: ms(100), levelDb: 90), 90);
  });

  test('releases exponentially at 1, 4 and 8 s', () {
    envelope.add(timestamp: ms(0), levelDb: 90);
    final values = <int, double>{};
    for (var t = 100; t <= 8000; t += 100) {
      values[t] = envelope.add(timestamp: ms(t), levelDb: 40)!;
    }
    expect(values[1000], closeTo(released(90, 40, 1, 4), 1e-9));
    expect(values[4000], closeTo(released(90, 40, 4, 4), 1e-9));
    expect(values[4000], closeTo(58.39, 0.01));
    expect(values[8000], closeTo(released(90, 40, 8, 4), 1e-9));
  });

  test('release is independent of the sample rate', () {
    final coarse = PeakEnvelope(attack: Duration.zero, release: ms(4000))
      ..add(timestamp: ms(0), levelDb: 90)
      ..add(timestamp: ms(2000), levelDb: 40);
    envelope.add(timestamp: ms(0), levelDb: 90);
    for (var t = 50; t <= 2000; t += 50) {
      envelope.add(timestamp: ms(t), levelDb: 40);
    }
    expect(envelope.value, closeTo(coarse.value!, 1e-9));
  });

  test('a non-zero attack smooths rises with its own time constant', () {
    final slow = PeakEnvelope(attack: ms(100), release: ms(1000))
      ..add(timestamp: ms(0), levelDb: 0);
    expect(
      slow.add(timestamp: ms(100), levelDb: 100),
      closeTo(100 * (1 - math.exp(-1)), 1e-9),
    );
    expect(slow.attack, ms(100));
    expect(slow.release, ms(1000));
  });

  test('ignores non-finite samples and non-advancing time', () {
    envelope.add(timestamp: ms(0), levelDb: 40);
    expect(envelope.add(timestamp: ms(100), levelDb: double.nan), 40);
    expect(envelope.add(timestamp: ms(100), levelDb: double.infinity), 40);
    expect(envelope.add(timestamp: ms(0), levelDb: 90), 40);
  });

  test('reset forgets the state', () {
    envelope
      ..add(timestamp: ms(0), levelDb: 90)
      ..reset();
    expect(envelope.value, isNull);
    expect(envelope.add(timestamp: ms(5000), levelDb: 30), 30);
  });
}
