// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_status_panel.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';
import 'package:raumfreund/features/monitor/presentation/stable_text.dart';

import '../../../shared/widgets/test_app.dart';

MonitorViewData _data({
  MonitorPhase phase = MonitorPhase.measuring,
  Zone? zone = Zone.green,
  int? countdown,
  bool fired = false,
  bool playing = false,
  bool starEarned = false,
}) => MonitorViewData(
  phase: phase,
  thresholds: Thresholds.defaults,
  zone: zone,
  alarmSecondsRemaining: countdown,
  alarmFired: fired,
  alarmPlaying: playing,
  stars: 3,
  starProgress: .4,
  starJustEarned: starEarned,
);

Future<double> _panelHeight(
  WidgetTester tester,
  MonitorViewData data,
  double scale,
) async {
  setScreenSize(tester, const Size(320, 900));
  await tester.pumpWidget(
    testApp(
      MonitorStatusPanel(
        data: data,
        onToggleMeasurement: () {},
        onRetry: () {},
        onOpenAndroidSettings: () {},
      ),
      disableAnimations: true,
      textScale: scale,
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(MonitorStatusPanel)).height;
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('panel height is stable across zones at scale $scale', (
      tester,
    ) async {
      final variants = [
        _data(),
        _data(phase: MonitorPhase.idle, zone: null),
        _data(zone: Zone.yellow, countdown: 7),
        _data(zone: Zone.yellow, countdown: 10),
        _data(zone: Zone.red, fired: true),
        _data(zone: Zone.red, fired: true, playing: true, starEarned: true),
      ];
      final heights = <double>[];
      for (final data in variants) {
        heights.add(await _panelHeight(tester, data, scale));
      }
      expect(heights.toSet(), hasLength(1), reason: '$heights');
    });
  }

  testWidgets('only the visible variant is exposed to semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _panelHeight(tester, _data(zone: Zone.red, fired: true), 1);

    expect(find.bySemanticsLabel(l10nDe.alarmFired), findsOneWidget);
    expect(find.bySemanticsLabel(l10nDe.alarmPlaying), findsNothing);
    expect(find.bySemanticsLabel(l10nDe.statusRed), findsOneWidget);
    expect(find.bySemanticsLabel(l10nDe.statusGreen), findsNothing);
    handle.dispose();
  });

  testWidgets('empty alarm slot reserves a line without text', (tester) async {
    await _panelHeight(tester, _data(), 1);

    final slot = find.byType(StableText).at(1);
    expect(tester.getSize(slot).height, greaterThan(0));
  });
}
