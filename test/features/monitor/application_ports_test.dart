// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';

void main() {
  test('level events carry their session', () {
    const reading = LevelReading(3, -42.5);
    const error = LevelError(4, LevelFailure.microphoneBusy);
    expect(reading.sessionId, 3);
    expect(reading.dbfs, -42.5);
    expect(error.sessionId, 4);
    expect(error.failure, LevelFailure.microphoneBusy);
  });

  test('exception describes the failure', () {
    expect(
      const LevelSourceException(LevelFailure.unavailable).toString(),
      'LevelSourceException(unavailable)',
    );
  });
}
