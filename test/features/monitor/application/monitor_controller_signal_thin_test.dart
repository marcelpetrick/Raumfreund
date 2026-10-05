// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// MonitorState.signalThin: sparse readings are made visible.

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/monitor_state.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';

import '../../../fakes/monitor_harness.dart';
import '../../../fakes/settle.dart';

void main() {
  group('signal thin', () {
    late MonitorHarness h;
    setUp(() async {
      h = MonitorHarness();
      await h.controller.start();
    });

    void sparse(int count) {
      for (var i = 0; i < count; i++) {
        h.reading(redDbfs, stepMs: 1000);
      }
    }

    test('is false initially and at the normal reading rate', () {
      expect(MonitorState.initial(Thresholds.defaults).signalThin, isFalse);
      h.readings(redDbfs, 50);
      expect(h.state.signalThin, isFalse);
    });

    test('1 Hz readings set it, 10 Hz readings clear it again', () {
      // Poor from the second reading on, thin 2 s later (fourth reading).
      sparse(3);
      expect(h.state.signalThin, isFalse);
      sparse(1);
      expect(h.state.signalThin, isTrue);
      expect(h.state.alarmFiredInPhase, isFalse);
      // Good (60 % covered) again after 1.4 s at 10 Hz, clear 3 s later.
      h.readings(redDbfs, 43);
      expect(h.state.signalThin, isTrue);
      h.readings(redDbfs, 1);
      expect(h.state.signalThin, isFalse);
    });

    test('stop clears it', () async {
      sparse(5);
      expect(h.state.signalThin, isTrue);
      await h.controller.stop();
      expect(h.state.signalThin, isFalse);
    });

    test('an error clears it', () async {
      sparse(5);
      h.source.emitError(h.controller.lastSessionId, LevelFailure.unavailable);
      await settle();
      expect(h.state.status, MonitorStatus.error);
      expect(h.state.signalThin, isFalse);
    });

    test('a restart begins without it', () async {
      sparse(5);
      await h.controller.stop();
      await h.controller.start();
      h.reading(redDbfs);
      expect(h.state.signalThin, isFalse);
    });
  });
}
