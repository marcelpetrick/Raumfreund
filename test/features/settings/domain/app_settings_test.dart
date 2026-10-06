// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/alarm_state_machine.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';

void main() {
  test('defaults', () {
    final d = AppSettings.defaults;
    expect(d.thresholds, Thresholds.defaults);
    expect(d.calibrationCorrectionDb, 0);
    expect(d.alarmSoundEnabled, isTrue);
    expect(d.vibrationEnabled, isTrue);
    expect(d.alarmDelaySeconds, 10);
    expect(d.quickStarModeEnabled, isFalse);
    expect(d.alarmDelay, AlarmStateMachine.defaultAlarmDelay);
  });

  test('alarm delay range 3..60 is enforced', () {
    AppSettings make(int s) =>
        AppSettings.defaults.copyWith(alarmDelaySeconds: s);
    expect(make(3).alarmDelaySeconds, 3);
    expect(make(60).alarmDelay, const Duration(seconds: 60));
    expect(() => make(2), throwsArgumentError);
    expect(() => make(61), throwsArgumentError);
    expect(() => make(-10), throwsArgumentError);
  });

  test('the shortest delay is valid for the alarm state machine', () {
    final shortest = AppSettings.defaults.copyWith(
      alarmDelaySeconds: AppSettings.minAlarmDelaySeconds,
    );
    expect(
      shortest.alarmDelay,
      greaterThan(AlarmStateMachine(thresholds: Thresholds.defaults).holdTime),
    );
    expect(
      AlarmStateMachine(
        thresholds: Thresholds.defaults,
        alarmDelay: shortest.alarmDelay,
      ).alarmDelay,
      const Duration(seconds: 3),
    );
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
    final slower = AppSettings.defaults.copyWith(alarmDelaySeconds: 20);
    expect(slower == AppSettings.defaults, isFalse);
    expect(slower.hashCode, isNot(AppSettings.defaults.hashCode));
    final quick = AppSettings.defaults.copyWith(quickStarModeEnabled: true);
    expect(quick.quickStarModeEnabled, isTrue);
    expect(quick, isNot(AppSettings.defaults));
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
