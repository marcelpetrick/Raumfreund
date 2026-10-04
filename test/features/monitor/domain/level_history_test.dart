// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

Duration ms(int value) => Duration(milliseconds: value);

LevelHistoryPoint point(int seconds, double level) => LevelHistoryPoint(
  timestamp: Duration(seconds: seconds),
  levelDb: level,
);

void main() {
  late LevelHistory history;

  setUp(() => history = LevelHistory());

  test('starts empty', () {
    expect(history.isEmpty, isTrue);
    expect(history.points, isEmpty);
    expect(history.segments(), isEmpty);
    expect(history.summarize(Thresholds.defaults), isNull);
    expect(history.window, const Duration(minutes: 30));
  });

  test('keeps the maximum of each 1 s bucket at the bucket start', () {
    history
      ..add(timestamp: ms(1000), levelDb: 40)
      ..add(timestamp: ms(1300), levelDb: 72)
      ..add(timestamp: ms(1900), levelDb: 50)
      ..add(timestamp: ms(2100), levelDb: 45);
    expect(history.points, [point(1, 72), point(2, 45)]);
    expect(history.isEmpty, isFalse);
  });

  test('ignores older buckets and non-finite levels', () {
    history
      ..add(timestamp: ms(5000), levelDb: 40)
      ..add(timestamp: ms(4000), levelDb: 90)
      ..add(timestamp: ms(5500), levelDb: double.nan);
    expect(history.points, [point(5, 40)]);
  });

  test('points are unmodifiable and refreshed after changes', () {
    history.add(timestamp: ms(0), levelDb: 40);
    final first = history.points;
    expect(identical(first, history.points), isTrue);
    expect(() => first.add(point(9, 1)), throwsUnsupportedError);
    history.add(timestamp: ms(1000), levelDb: 41);
    expect(history.points, hasLength(2));
  });

  test('evicts points older than the window relative to the latest', () {
    final short = LevelHistory(window: const Duration(seconds: 3));
    for (var s = 0; s <= 5; s++) {
      short.add(
        timestamp: Duration(seconds: s),
        levelDb: s.toDouble(),
      );
    }
    expect(short.points.map((p) => p.timestamp.inSeconds), [2, 3, 4, 5]);
  });

  test('30 minute window keeps 1801 buckets of a long run', () {
    for (var s = 0; s < 3600; s++) {
      history.add(timestamp: Duration(seconds: s), levelDb: 50);
    }
    expect(history.points, hasLength(1801));
    expect(history.points.first.timestamp, const Duration(seconds: 1799));
  });

  test('segments split at missing buckets', () {
    for (final s in [0, 1, 2, 5, 6, 10]) {
      history.add(timestamp: Duration(seconds: s), levelDb: 50);
    }
    final segments = history.segments();
    expect(segments.map((s) => s.length), [3, 2, 1]);
    expect(() => segments.first.add(point(1, 1)), throwsUnsupportedError);
  });

  test('clear removes everything', () {
    history
      ..add(timestamp: ms(0), levelDb: 40)
      ..clear();
    expect(history.points, isEmpty);
  });

  test('summary reports max, average and zone shares', () {
    history
      ..add(timestamp: ms(0), levelDb: 50)
      ..add(timestamp: ms(1000), levelDb: 50)
      ..add(timestamp: ms(2000), levelDb: 70)
      ..add(timestamp: ms(3000), levelDb: 90);
    final summary = history.summarize(Thresholds.defaults)!;
    expect(summary.maxDb, 90);
    expect(summary.averageDb, 65);
    expect(summary.zoneShare, {
      Zone.green: 0.5,
      Zone.yellow: 0.25,
      Zone.red: 0.25,
    });
    expect(summary.coveredDuration, const Duration(seconds: 4));
  });
}
