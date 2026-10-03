// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

void main() {
  group('validation', () {
    test('accepts the full range and adjacent limits', () {
      expect(Thresholds.isValid(yellowDb: 0, redDb: 130), isTrue);
      expect(Thresholds.isValid(yellowDb: 129, redDb: 130), isTrue);
      expect(Thresholds.isValid(yellowDb: 0, redDb: 1), isTrue);
    });

    test('rejects equal, inverted and out-of-range limits', () {
      expect(Thresholds.isValid(yellowDb: 70, redDb: 70), isFalse);
      expect(Thresholds.isValid(yellowDb: 80, redDb: 60), isFalse);
      expect(Thresholds.isValid(yellowDb: -1, redDb: 60), isFalse);
      expect(Thresholds.isValid(yellowDb: 60, redDb: 131), isFalse);
    });

    test('constructor throws, tryCreate returns null', () {
      expect(() => Thresholds(yellowDb: 90, redDb: 80), throwsArgumentError);
      expect(Thresholds.tryCreate(yellowDb: 90, redDb: 80), isNull);
      expect(
        Thresholds.tryCreate(yellowDb: 50, redDb: 70),
        Thresholds(yellowDb: 50, redDb: 70),
      );
    });

    test('defaults are 60/80', () {
      expect(Thresholds.defaults.yellowDb, 60);
      expect(Thresholds.defaults.redDb, 80);
    });
  });

  group('classify', () {
    final thresholds = Thresholds.defaults;

    test('a value exactly on a limit belongs to the higher zone', () {
      expect(thresholds.classify(59.999), Zone.green);
      expect(thresholds.classify(60), Zone.yellow);
      expect(thresholds.classify(79.999), Zone.yellow);
      expect(thresholds.classify(80), Zone.red);
      expect(thresholds.classify(130), Zone.red);
      expect(thresholds.classify(0), Zone.green);
    });

    test('yellow at 0 means there is no green zone', () {
      expect(Thresholds(yellowDb: 0, redDb: 10).classify(0), Zone.yellow);
    });
  });

  test('value semantics', () {
    final a = Thresholds(yellowDb: 1, redDb: 2);
    final b = Thresholds(yellowDb: 1, redDb: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == Thresholds(yellowDb: 1, redDb: 3), isFalse);
    expect(a.toString(), 'Thresholds(yellow: 1, red: 2)');
  });
}
