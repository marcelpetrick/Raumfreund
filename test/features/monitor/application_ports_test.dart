// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';

void main() {
  test('level events carry their session', () {
    // Built at runtime: const instances do not reliably count for coverage.
    final session = int.parse('3');
    final reading = LevelReading(session, -42.5);
    final error = LevelError(session + 1, LevelFailure.microphoneBusy);
    expect(reading.sessionId, 3);
    expect(reading.dbfs, -42.5);
    expect(error.sessionId, 4);
    expect(error.failure, LevelFailure.microphoneBusy);
  });

  test('exception describes the failure', () {
    expect(
      LevelSourceException(LevelFailure.values.byName('unavailable'))
          .toString(),
      'LevelSourceException(unavailable)',
    );
  });
}
