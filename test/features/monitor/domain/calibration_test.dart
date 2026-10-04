// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/calibration.dart';

void main() {
  group('Calibration.estimate', () {
    test('adds the base offset without correction', () {
      expect(const Calibration().estimate(-40), 50);
      expect(const Calibration().estimate(0), Calibration.baseOffsetDb);
    });

    test('adds the user correction', () {
      // Runtime (non-const) construction so the constructor is covered
      // deterministically on every machine.
      final correction = int.parse('7');
      final calibration = Calibration(correctionDb: correction);
      expect(calibration.correctionDb, 7);
      expect(calibration.estimate(-40), 57);
      expect(const Calibration(correctionDb: -30).estimate(-40), 20);
    });

    test('clamps to the 0–130 dB scale', () {
      expect(const Calibration().estimate(-200), Calibration.minDb);
      expect(const Calibration(correctionDb: 30).estimate(20), 130);
      expect(const Calibration().estimate(-90), 0);
      expect(const Calibration(correctionDb: 30).estimate(10), 130);
    });

    test('rejects NaN and infinity as invalid samples', () {
      const calibration = Calibration();
      expect(calibration.estimate(double.nan), isNull);
      expect(calibration.estimate(double.infinity), isNull);
      expect(calibration.estimate(double.negativeInfinity), isNull);
    });
  });
}
