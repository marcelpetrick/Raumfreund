// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

void main() {
  late MonitorHarness h;
  var earned = 0;

  setUp(() async {
    earned = 0;
    h = MonitorHarness(onStarEarned: () => earned++);
    await h.controller.start();
  });

  tearDown(() => h.controller.dispose());

  group('star sink', () {
    test('is called once per earned star', () {
      h.readings(greenDbfs, 601);
      expect(earned, 1);
      h.readings(greenDbfs, 600);
      expect(earned, 2);
      expect(h.state.stars, 2);
    });

    test('is not called before the minute is complete', () {
      h.readings(greenDbfs, 600);
      expect(earned, 0);
    });

    test('stop discards the running minute without a star', () async {
      h.readings(greenDbfs, 599);
      await h.controller.stop();
      await h.controller.start();
      h.readings(greenDbfs, 10);
      expect(earned, 0);
    });

    test('the own alarm tone suppresses samples and stars', () async {
      h.readings(redDbfs, 101);
      expect(h.alarm.calls, hasLength(1));
      h.readings(greenDbfs, 700);
      expect(earned, 0);
      h.alarm.finish();
      await settle();
    });

    test('the default sink does nothing', () async {
      final plain = MonitorHarness();
      addTearDown(plain.controller.dispose);
      await plain.controller.start();
      plain.readings(greenDbfs, 601);
      expect(plain.state.stars, 1);
    });
  });
}
