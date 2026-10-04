// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

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

/// Feeds [level] every 100 ms for `fromMs <= t < toMs`.
void feed(LevelHistory history, int fromMs, int toMs, double level) {
  for (var t = fromMs; t < toMs; t += 100) {
    history.add(timestamp: ms(t), levelDb: level);
  }
}

void main() {
  bucketTests();
  windowTests();
}

void bucketTests() {
  late LevelHistory history;

  setUp(() => history = LevelHistory());

  test('starts empty with a 10 minute window of 10 s buckets', () {
    expect(history.isEmpty, isTrue);
    expect(history.points, isEmpty);
    expect(history.segments(), isEmpty);
    expect(history.summarize(Thresholds.defaults), isNull);
    expect(history.window, const Duration(minutes: 10));
    expect(LevelHistory.bucket, const Duration(seconds: 10));
  });

  test('a constant level gives one point per 10 s bucket', () {
    feed(history, 0, 30000, 50);
    expect(history.points, [point(0, 50), point(10, 50), point(20, 50)]);
    expect(history.isEmpty, isFalse);
  });

  test('bucket boundary: exactly 10 s opens the next bucket', () {
    feed(history, 0, 10000, 50);
    expect(history.points, [point(0, 50)]);
    history.add(timestamp: ms(10000), levelDb: 50);
    expect(history.points, [point(0, 50), point(10, 50)]);
  });

  test('peaks rise at once and cool down over several buckets', () {
    feed(history, 0, 10000, 40);
    history.add(timestamp: ms(10000), levelDb: 90);
    // Attack is instant: the live point of the new bucket shows the peak.
    expect(history.points.last, point(10, 90));
    feed(history, 10100, 40000, 40);
    final levels = history.points.map((p) => p.levelDb).toList();
    expect(levels[0], 40);
    expect(levels[1], greaterThan(55)); // the peak lifts its bucket
    expect(levels[2], greaterThan(40.5)); // cooling still visible
    expect(levels[2], lessThan(levels[1]));
    expect(levels[3], lessThan(levels[2]));
  });

  test('a committed bucket is the mean of the envelope', () {
    history.add(timestamp: ms(0), levelDb: 90);
    feed(history, 100, 10000, 40);
    history.add(timestamp: ms(10000), levelDb: 40);
    var sum = 90.0;
    for (var i = 1; i < 100; i++) {
      sum += 40 + 50 * math.exp(-i * 0.1 / 4);
    }
    expect(history.points.first.levelDb, closeTo(sum / 100, 1e-9));
  });

  test('live point is refreshed at most once per second', () {
    history.add(timestamp: ms(0), levelDb: 40);
    final first = history.points;
    for (var t = 100; t < 1000; t += 100) {
      history.add(timestamp: ms(t), levelDb: 80);
      expect(identical(history.points, first), isTrue, reason: 't=$t');
    }
    history.add(timestamp: ms(1000), levelDb: 80);
    final second = history.points;
    expect(identical(second, first), isFalse);
    expect(second.single.levelDb, closeTo((40 + 80 * 10) / 11, 1e-9));
    history.add(timestamp: ms(1900), levelDb: 80);
    expect(identical(history.points, second), isTrue);
  });
}

void windowTests() {
  late LevelHistory history;

  setUp(() => history = LevelHistory());

  test('points are unmodifiable', () {
    history.add(timestamp: ms(0), levelDb: 40);
    expect(() => history.points.add(point(9, 1)), throwsUnsupportedError);
  });

  test('ignores older samples and non-finite levels', () {
    history
      ..add(timestamp: ms(5000), levelDb: 40)
      ..add(timestamp: ms(4000), levelDb: 90)
      ..add(timestamp: ms(5500), levelDb: double.nan)
      ..add(timestamp: ms(5600), levelDb: double.infinity)
      ..add(timestamp: ms(10000), levelDb: 40);
    expect(history.points, [point(0, 40), point(10, 40)]);
  });

  test('window keeps at most 60 buckets of a long run', () {
    for (var s = 0; s < 3600; s++) {
      history.add(timestamp: Duration(seconds: s), levelDb: 50);
    }
    expect(history.points, hasLength(60));
    expect(history.points.first.timestamp, const Duration(seconds: 3000));
    expect(history.points.last.timestamp, const Duration(seconds: 3590));
  });

  test('a custom window evicts relative to the latest bucket', () {
    final short = LevelHistory(window: const Duration(seconds: 30));
    for (var s = 0; s <= 50; s += 10) {
      short.add(timestamp: Duration(seconds: s), levelDb: 50);
    }
    expect(short.points.map((p) => p.timestamp.inSeconds), [30, 40, 50]);
  });

  test('a gap restarts the envelope and splits the segments', () {
    history.add(timestamp: ms(0), levelDb: 90);
    // Resumed after a stop: the old peak must not leak into the new bucket.
    history.add(timestamp: ms(25000), levelDb: 40);
    expect(history.points, [point(0, 90), point(20, 40)]);
    feed(history, 25100, 40000, 40);
    final segments = history.segments();
    expect(segments.map((s) => s.length), [1, 2]);
    expect(() => segments.first.add(point(1, 1)), throwsUnsupportedError);
  });

  test('clear removes everything and forgets the envelope', () {
    history
      ..add(timestamp: ms(0), levelDb: 90)
      ..clear();
    expect(history.points, isEmpty);
    expect(history.isEmpty, isTrue);
    history.add(timestamp: ms(100), levelDb: 40);
    expect(history.points, [point(0, 40)]);
  });

  test('summary reports max, average and zone shares', () {
    feed(history, 0, 20000, 50);
    feed(history, 20000, 30000, 70);
    history.add(timestamp: ms(30000), levelDb: 90);
    final summary = history.summarize(Thresholds.defaults)!;
    expect(summary.maxDb, 90);
    expect(summary.averageDb, 65);
    expect(summary.zoneShare, {
      Zone.green: 0.5,
      Zone.yellow: 0.25,
      Zone.red: 0.25,
    });
    expect(summary.coveredDuration, const Duration(seconds: 40));
  });
}
