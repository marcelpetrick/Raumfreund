// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/presentation/level_timeline.dart';

import '../../../shared/widgets/test_app.dart';

LevelHistoryPoint _point(int seconds, [double level = 42]) => LevelHistoryPoint(
  timestamp: Duration(seconds: seconds),
  levelDb: level,
);

void main() {
  segmentTests();
  pathTests();
  widgetTests();
}

void segmentTests() {
  test('timeline breaks the trace across a missing 10 s bucket', () {
    final segments = splitTimelinePoints([
      _point(0),
      _point(10),
      _point(30),
      _point(40),
    ], oldest: Duration.zero);

    expect(segments, [
      [_point(0), _point(10)],
      [_point(30), _point(40)],
    ]);
  });

  test('timeline keeps neighbouring buckets connected, clips old ones', () {
    final segments = splitTimelinePoints([
      _point(0),
      _point(10),
      _point(20),
    ], oldest: const Duration(seconds: 10));

    expect(segments, [
      [_point(10), _point(20)],
    ]);
  });

  test('timeline has no segments without visible points', () {
    final segments = splitTimelinePoints([
      _point(0),
    ], oldest: const Duration(seconds: 1));

    expect(segments, isEmpty);
  });
}

void pathTests() {
  test('smooth path stays within the bounds of its points', () {
    final path = Path();
    const offsets = [Offset(0, 50), Offset(10, 0), Offset(20, 100)];
    addSmoothTimelinePath(path, offsets);
    final bounds = path.getBounds();
    expect(bounds.left, 0);
    expect(bounds.right, 20);
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(100));
    final metrics = path.computeMetrics().toList();
    expect(metrics, hasLength(1));
  });

  test('smooth path passes through an interior peak', () {
    final path = Path();
    const offsets = [Offset(0, 100), Offset(10, 10), Offset(20, 100)];
    addSmoothTimelinePath(path, offsets);
    // Screen y grows downwards: the peak (y = 10) is the top of the path.
    expect(path.getBounds().top, closeTo(10, 1e-9));
    final metric = path.computeMetrics().single;
    final mid = metric.getTangentForOffset(metric.length / 2)!.position;
    expect(mid.dx, closeTo(10, 0.5));
    expect(mid.dy, closeTo(10, 0.5));
  });

  test('monotone tangents: zero at extrema, scaled on steep steps', () {
    expect(monotoneTimelineTangents(const []), isEmpty);
    expect(monotoneTimelineTangents(const [Offset(0, 1)]), [0]);
    expect(
      monotoneTimelineTangents(const [
        Offset(0, 100),
        Offset(10, 10),
        Offset(20, 100),
      ]),
      [-9, 0, 9],
    );
    // A flat run followed by a jump keeps the flat part flat.
    final step = monotoneTimelineTangents(const [
      Offset(0, 50),
      Offset(10, 50),
      Offset(20, 0),
    ]);
    expect(step.take(2), [0, 0]);
    // Steep, steady rise: alpha² + beta² is limited to 9.
    final steep = monotoneTimelineTangents(const [
      Offset.zero,
      Offset(1, 1),
      Offset(2, 100),
    ]);
    const secant = 99.0;
    final alpha = steep[1] / secant;
    final beta = steep[2] / secant;
    expect(alpha * alpha + beta * beta, lessThanOrEqualTo(9 + 1e-9));
    // Collapsed x (clamped at the edge) is treated as flat.
    expect(monotoneTimelineTangents(const [Offset.zero, Offset(0, 10)]), [
      0,
      0,
    ]);
  });

  test('monotone curve never leaves the range of monotone data', () {
    final path = Path();
    const offsets = [
      Offset(0, 100),
      Offset(10, 90),
      Offset(20, 10),
      Offset(30, 5),
    ];
    addSmoothTimelinePath(path, offsets);
    final bounds = path.getBounds();
    expect(bounds.top, greaterThanOrEqualTo(5 - 1e-9));
    expect(bounds.bottom, lessThanOrEqualTo(100 + 1e-9));
  });

  test('smooth path of one point only moves, of none adds nothing', () {
    final single = Path();
    addSmoothTimelinePath(single, const [Offset(5, 5)]);
    expect(single.computeMetrics(), isEmpty);
    final empty = Path();
    addSmoothTimelinePath(empty, const []);
    expect(empty.getBounds(), Rect.zero);
  });
}

void widgetTests() {
  testWidgets('shows the 10 minute title and axis labels', (tester) async {
    await pumpTestApp(
      tester,
      LevelTimeline(
        points: [_point(0, 40), _point(300, 80), _point(320, 50)],
        thresholds: Thresholds.defaults,
      ),
    );
    expect(find.text('Verlauf der letzten 10 Minuten'), findsOneWidget);
    expect(find.text('−10 min'), findsOneWidget);
    expect(find.text('−5 min'), findsOneWidget);
    expect(find.text('jetzt'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LevelTimeline)),
      matchesSemantics(
        label: 'Verlauf der letzten 10 Minuten',
        value:
            'Diagrammpunkte aus 10-Sekunden-Mittelwerten: höchster 80 dB, '
            'Durchschnitt 57 dB, 67 % der Punkte im grünen Bereich',
        isReadOnly: true,
      ),
    );
  });

  testWidgets('empty timeline paints and announces no values', (tester) async {
    await pumpTestApp(
      tester,
      LevelTimeline(points: const [], thresholds: Thresholds.defaults),
    );
    expect(
      tester.getSemantics(find.byType(LevelTimeline)),
      matchesSemantics(
        label: 'Verlauf der letzten 10 Minuten',
        value: 'Noch keine Messwerte',
        isReadOnly: true,
      ),
    );
  });

  test('painter repaints only when points or thresholds change', () {
    final points = [_point(0)];
    final painter = LevelTimelinePainter(
      points: points,
      thresholds: Thresholds.defaults,
    );
    expect(
      painter.shouldRepaint(
        LevelTimelinePainter(points: points, thresholds: Thresholds.defaults),
      ),
      isFalse,
    );
    expect(
      painter.shouldRepaint(
        LevelTimelinePainter(
          points: [_point(0)],
          thresholds: Thresholds.defaults,
        ),
      ),
      isTrue,
    );
  });
}
