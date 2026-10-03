// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/core/clock.dart';

void main() {
  test('StopwatchClock is monotonic', () {
    final clock = StopwatchClock();
    final first = clock.now;
    expect(clock.now >= first, isTrue);
  });
}
