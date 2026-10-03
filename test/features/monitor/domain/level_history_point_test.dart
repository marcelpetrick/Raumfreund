// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';

void main() {
  test('value semantics', () {
    // Built at runtime: const instances do not reliably count for coverage.
    final level = double.parse('50');
    final a = LevelHistoryPoint(
      timestamp: const Duration(seconds: 1),
      levelDb: level,
    );
    final b = LevelHistoryPoint(
      timestamp: const Duration(seconds: 1),
      levelDb: level,
    );
    final c = LevelHistoryPoint(
      timestamp: const Duration(seconds: 2),
      levelDb: level,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
