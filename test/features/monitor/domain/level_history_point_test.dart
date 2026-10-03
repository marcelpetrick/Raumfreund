// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';

void main() {
  test('value semantics', () {
    const a = LevelHistoryPoint(timestamp: Duration(seconds: 1), levelDb: 50);
    const b = LevelHistoryPoint(timestamp: Duration(seconds: 1), levelDb: 50);
    const c = LevelHistoryPoint(timestamp: Duration(seconds: 2), levelDb: 50);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
