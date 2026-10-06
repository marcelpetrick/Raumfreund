// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
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
  int stars = 3,
  int? wallet,
  bool quickStars = false,
}) => MonitorViewData(
  phase: phase,
  thresholds: Thresholds.defaults,
  zone: zone,
  alarmSecondsRemaining: countdown,
  alarmFired: fired,
  alarmPlaying: playing,
  stars: stars,
  walletStars: wallet,
  starProgress: .4,
  starJustEarned: starEarned,
  quickStarMode: quickStars,
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

/// Tests for the Sternenladen total in the star line.
void _totalTests() {
  testWidgets('shows the Sternenladen total next to the session stars', (
    tester,
  ) async {
    await _panelHeight(tester, _data(stars: 2, wallet: 7), 1);
    expect(find.text('2 Sterne heute · 7 im Sternenladen'), findsOneWidget);

    await _panelHeight(tester, _data(stars: 0, wallet: 7), 1);
    expect(
      find.text('Noch keine Sterne heute · 7 im Sternenladen'),
      findsOneWidget,
    );

    await _panelHeight(tester, _data(stars: 1, wallet: 7), 1);
    expect(find.text('1 Stern heute · 7 im Sternenladen'), findsOneWidget);
  });

  testWidgets('says when the five-second star test mode is on', (tester) async {
    await _panelHeight(tester, _data(), 1);
    expect(find.text(l10nDe.starsHint), findsOneWidget);

    await _panelHeight(tester, _data(quickStars: true), 1);
    expect(find.text(l10nDe.starsHintQuickTest), findsOneWidget);
    expect(find.text(l10nDe.starsHint), findsNothing);
  });

  testWidgets('hides the total while the wallet is unknown', (tester) async {
    await _panelHeight(tester, _data(stars: 2), 1);

    expect(find.text('2 Sterne'), findsOneWidget);
    expect(find.textContaining('Sternenladen'), findsNothing);
  });

  testWidgets('the star semantics label includes the total', (tester) async {
    final handle = tester.ensureSemantics();
    await _panelHeight(tester, _data(stars: 2, wallet: 7), 1);

    expect(
      find.bySemanticsLabel(RegExp('2 Sterne heute · 7 im Sternenladen')),
      findsOneWidget,
    );
    handle.dispose();
  });
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
        // Longest configurable alarm delay (AppSettings, 3..60 s).
        _data(zone: Zone.yellow, countdown: 60),
        _data(zone: Zone.red, countdown: 3),
        _data(zone: Zone.red, countdown: 0),
        _data(zone: Zone.red, fired: true),
        _data(zone: Zone.red, fired: true, playing: true, starEarned: true),
        _data(wallet: 7),
        _data(stars: 0, wallet: 0),
        _data(stars: 1, wallet: 1),
        _data(stars: 0, wallet: 999),
        _data(stars: 120, wallet: 999),
        _data(wallet: 999, starEarned: true),
      ];
      final heights = <double>[];
      for (final data in variants) {
        heights.add(await _panelHeight(tester, data, scale));
      }
      expect(heights.toSet(), hasLength(1), reason: '$heights');
    });
  }

  _totalTests();

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

  testWidgets('measuring copies follow the bold text setting', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(boldText: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _panelHeight(tester, _data(zone: Zone.red, fired: true), 1);

    final hidden = find.descendant(
      of: find.byType(StableText).at(1),
      matching: find.byType(RichText),
    );
    final styles = [
      for (final element in hidden.evaluate())
        (element.widget as RichText).text.style,
    ];
    expect(styles, isNotEmpty);
    expect(
      styles.every((style) => style?.fontWeight == FontWeight.bold),
      isTrue,
    );
  });

  testWidgets('countdown at zero says the alarm is imminent', (tester) async {
    await _panelHeight(tester, _data(zone: Zone.red, countdown: 0), 1);

    expect(find.text(l10nDe.alarmImminent), findsOneWidget);
    expect(find.text(l10nDe.alarmCountdown(0)), findsNothing);
  });

  testWidgets('screen readers hear the countdown in full words', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _panelHeight(tester, _data(zone: Zone.yellow, countdown: 7), 1);

    expect(
      find.bySemanticsLabel(l10nDe.alarmCountdownSemantics(7)),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(l10nDe.alarmCountdown(7)), findsNothing);
    handle.dispose();
  });
}
