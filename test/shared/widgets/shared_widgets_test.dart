// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/shared/widgets/glow_panel.dart';
import 'package:raumfreund/shared/widgets/night_sky_background.dart';

import 'test_app.dart';

void main() {
  testWidgets('NightSkyBackground paints stars behind its child', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      NightSkyBackground(child: Text(rt('Himmel'))),
      scaffold: false,
    );
    expect(find.text('Himmel'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SkyStarsPainter,
      ),
      findsOneWidget,
    );
  });

  test('SkyStarsPainter repaints only when its parameters change', () {
    final count = rt(42);
    final painter = SkyStarsPainter(count: count);
    expect(painter.shouldRepaint(SkyStarsPainter(count: count)), isFalse);
    expect(painter.shouldRepaint(SkyStarsPainter(count: count - 1)), isTrue);
  });

  testWidgets('GlowPanel shows its child with and without glow', (
    tester,
  ) async {
    final none = rt(0.0);
    await pumpTestApp(
      tester,
      Column(
        children: [
          GlowPanel(child: Text(rt('A'))),
          GlowPanel(glowStrength: none, child: Text(rt('B'))),
        ],
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
