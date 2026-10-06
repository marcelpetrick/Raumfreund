// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/core/scheduler.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_scheduler.dart';

void main() {
  group('DartTimerScheduler', () {
    test('runs a callback after the delay', () async {
      final fired = Completer<void>();
      const DartTimerScheduler().schedule(
        const Duration(milliseconds: 1),
        fired.complete,
      );
      await fired.future.timeout(const Duration(seconds: 5));
      expect(fired.isCompleted, isTrue);
    });

    test('a cancelled callback never runs; cancel is idempotent', () async {
      var runs = 0;
      const DartTimerScheduler().schedule(
          const Duration(milliseconds: 1),
          () => runs++,
        )
        ..cancel()
        ..cancel();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(runs, 0);
    });
  });

  group('FakeScheduler', () {
    test('runs due callbacks in due order, only when time passes', () {
      final scheduler = FakeScheduler(FakeClock());
      final order = <int>[];
      scheduler
        ..schedule(const Duration(seconds: 2), () => order.add(2))
        ..schedule(const Duration(seconds: 1), () {
          order.add(1);
          scheduler.schedule(Duration.zero, () => order.add(11));
        });
      scheduler
          .schedule(const Duration(seconds: 1), () => order.add(-1))
          .cancel();
      expect(scheduler.nextDue, const Duration(seconds: 1));
      scheduler.elapseMs(999);
      expect(order, isEmpty);
      scheduler.elapse(const Duration(seconds: 2));
      // A callback scheduled while running is due relative to the new time.
      expect(order, [1, 2, 11]);
      expect(scheduler.pendingCount, 0);
      expect(scheduler.nextDue, isNull);
    });
  });
}
