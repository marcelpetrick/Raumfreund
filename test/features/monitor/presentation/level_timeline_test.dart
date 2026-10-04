// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/presentation/level_timeline.dart';

LevelHistoryPoint _point(int milliseconds) => LevelHistoryPoint(
  timestamp: Duration(milliseconds: milliseconds),
  levelDb: 42,
);

void main() {
  test('timeline breaks the trace across a missing history bucket', () {
    final segments = splitTimelinePoints([
      _point(0),
      _point(1000),
      _point(3000),
      _point(4000),
    ], oldest: Duration.zero);

    expect(segments, [
      [_point(0), _point(1000)],
      [_point(3000), _point(4000)],
    ]);
  });

  test(
    'timeline keeps the domain boundary continuous and clips old points',
    () {
      final segments = splitTimelinePoints([
        _point(0),
        _point(1000),
        _point(2500),
      ], oldest: const Duration(seconds: 1));

      expect(segments, [
        [_point(1000), _point(2500)],
      ]);
    },
  );

  test('timeline has no segments without visible points', () {
    final segments = splitTimelinePoints([
      _point(0),
    ], oldest: const Duration(seconds: 1));

    expect(segments, isEmpty);
  });
}
