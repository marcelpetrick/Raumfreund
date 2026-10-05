// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_status_panel.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';

import '../../../shared/widgets/test_app.dart';

Future<double> _pump(WidgetTester tester, MonitorViewData data) async {
  await tester.pumpWidget(
    testApp(
      MonitorStatusPanel(
        data: data,
        onToggleMeasurement: () {},
        onRetry: () {},
        onOpenAndroidSettings: () {},
      ),
      disableAnimations: true,
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(MonitorStatusPanel)).height;
}

MonitorViewData _data({
  MonitorPhase phase = MonitorPhase.measuring,
  bool signalThin = true,
}) => MonitorViewData(
  phase: phase,
  thresholds: Thresholds.defaults,
  zone: phase == MonitorPhase.measuring ? Zone.red : null,
  signalThin: signalThin,
);

void main() {
  testWidgets('sparse readings show a hint announced as a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _data());

    expect(find.text(l10nDe.signalThin), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    final live = find.ancestor(
      of: find.text(l10nDe.signalThin),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && (widget.properties.liveRegion ?? false),
      ),
    );
    expect(live, findsOneWidget);
    handle.dispose();
  });

  testWidgets('no hint with good readings or without a measurement', (
    tester,
  ) async {
    await _pump(tester, _data(signalThin: false));
    expect(find.text(l10nDe.signalThin), findsNothing);
    await _pump(tester, _data(phase: MonitorPhase.idle));
    expect(find.text(l10nDe.signalThin), findsNothing);
  });

  testWidgets('the hint is a rare state that may grow the panel', (
    tester,
  ) async {
    final normal = await _pump(tester, _data(signalThin: false));
    final hinted = await _pump(tester, _data());
    expect(hinted, greaterThan(normal));
  });
}
