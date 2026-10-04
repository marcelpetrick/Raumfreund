// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_page.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';

import '../../../shared/widgets/test_app.dart';

Future<void> _pumpPage(WidgetTester tester, MonitorViewData data) async {
  await pumpTestApp(
    tester,
    MonitorPage(
      data: data,
      onToggleMeasurement: () {},
      onRetry: () {},
      onOpenAndroidSettings: () {},
      onOpenSettings: () async {},
      onOpenAbout: () async {},
    ),
    scaffold: false,
    disableAnimations: true,
  );
}

MonitorViewData _data({
  MonitorPhase phase = MonitorPhase.measuring,
  Zone? zone = Zone.green,
  MonitorErrorKind? error,
  bool alarmFired = false,
  bool alarmPlaying = false,
  bool alarmOutputFailed = false,
  int? countdown,
}) => MonitorViewData(
  phase: phase,
  thresholds: Thresholds.defaults,
  levelDb: zone == null ? null : 64.4,
  zone: zone,
  history: const [
    LevelHistoryPoint(timestamp: Duration.zero, levelDb: 20),
    LevelHistoryPoint(timestamp: Duration(minutes: 15), levelDb: 70),
    LevelHistoryPoint(timestamp: Duration(minutes: 31), levelDb: 90),
  ],
  alarmSecondsRemaining: countdown,
  alarmFired: alarmFired,
  alarmPlaying: alarmPlaying,
  alarmOutputFailed: alarmOutputFailed,
  kittyWalkedAway: zone == Zone.red && alarmFired,
  stars: 2,
  starProgress: .5,
  starJustEarned: alarmPlaying,
  error: error,
);

void main() {
  testWidgets('idle page exposes Settings and About actions', (tester) async {
    var toggles = 0;
    var settings = 0;
    var about = 0;
    await pumpTestApp(
      tester,
      MonitorPage(
        data: MonitorViewData.idle(),
        onToggleMeasurement: () => toggles++,
        onOpenSettings: () async => settings++,
        onOpenAbout: () async => about++,
      ),
      scaffold: false,
      disableAnimations: true,
    );
    expect(find.text(l10nDe.statusIdle), findsOneWidget);
    expect(find.text(l10nDe.gaugeNoValue), findsOneWidget);
    await tester.tap(find.text(l10nDe.measureStart));
    await tester.tap(find.byTooltip(l10nDe.actionSettings));
    await tester.tap(find.byTooltip(l10nDe.actionAbout));
    await tester.pump();
    expect((toggles, settings, about), (1, 1, 1));
  });

  testWidgets('renders measuring zones, timeline and alarm states', (
    tester,
  ) async {
    for (final zone in Zone.values) {
      await _pumpPage(tester, _data(zone: zone, countdown: 7));
      expect(find.text(l10nDe.alarmCountdown(7)), findsOneWidget);
      expect(find.text(l10nDe.measureStop), findsOneWidget);
    }
    await _pumpPage(tester, _data(zone: Zone.red, alarmFired: true));
    expect(find.text(l10nDe.alarmFired), findsOneWidget);
    await _pumpPage(tester, _data(alarmPlaying: true));
    expect(find.text(l10nDe.alarmPlaying), findsOneWidget);
    expect(find.text(l10nDe.starsJustEarned), findsOneWidget);
    await _pumpPage(tester, _data(alarmOutputFailed: true));
    expect(find.text(l10nDe.alarmOutputFailed), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });

  testWidgets('renders transitions and each recoverable error', (tester) async {
    for (final phase in [MonitorPhase.starting, MonitorPhase.stopping]) {
      await _pumpPage(tester, _data(phase: phase, zone: null));
      expect(find.text(l10nDe.measureBusy), findsOneWidget);
    }
    for (final error in MonitorErrorKind.values) {
      await _pumpPage(
        tester,
        _data(phase: MonitorPhase.error, zone: null, error: error),
      );
      final action = error == MonitorErrorKind.permanentlyDenied
          ? l10nDe.errorOpenSettings
          : l10nDe.errorRetry;
      expect(find.text(action), findsOneWidget);
      await tester.tap(find.text(action));
    }
    await _pumpPage(tester, _data(phase: MonitorPhase.error, zone: null));
    expect(find.text(l10nDe.errorUnavailableBody), findsOneWidget);
  });

  testWidgets('uses the two-column tablet layout', (tester) async {
    setScreenSize(tester, const Size(1000, 900));
    await _pumpPage(tester, _data(zone: Zone.yellow));
    expect(find.byType(Row), findsWidgets);
    expect(find.text(l10nDe.statusYellow), findsOneWidget);
  });
}
