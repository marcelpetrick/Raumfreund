// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

void main() {
  test('defaults', () {
    final d = AppSettings.defaults;
    expect(d.thresholds, Thresholds.defaults);
    expect(d.calibrationCorrectionDb, 0);
    expect(d.alarmSoundEnabled, isTrue);
    expect(d.vibrationEnabled, isTrue);
  });

  test('calibration range is enforced', () {
    AppSettings make(int c) =>
        AppSettings.defaults.copyWith(calibrationCorrectionDb: c);
    expect(make(-30).calibrationCorrectionDb, -30);
    expect(make(30).calibrationCorrectionDb, 30);
    expect(() => make(-31), throwsArgumentError);
    expect(() => make(31), throwsArgumentError);
  });

  test('copyWith and value semantics', () {
    final changed = AppSettings.defaults.copyWith(
      thresholds: Thresholds(yellowDb: 50, redDb: 70),
      alarmSoundEnabled: false,
      vibrationEnabled: false,
    );
    expect(changed == AppSettings.defaults, isFalse);
    expect(
      changed,
      AppSettings.defaults.copyWith(
        thresholds: Thresholds(yellowDb: 50, redDb: 70),
        alarmSoundEnabled: false,
        vibrationEnabled: false,
      ),
    );
    expect(changed.hashCode, isNot(AppSettings.defaults.hashCode));
    expect(AppSettings.defaults.copyWith(), AppSettings.defaults);
  });
}
