// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Demo entry point for screen recordings (marketing video, screenshots).
//
// It composes the real app with scripted noise levels instead of the
// microphone, so a recording shows every state on cue and does not depend on
// the emulator's audio backend. Never part of a release: build it explicitly
// with `tool/flutter.sh build apk --debug -t tool/demo/demo_main.dart
// --dart-define=GIT_COMMIT=$(git rev-parse --short=12 HEAD)`.
// No microphone, no sound, no network; the wallet lives in RAM only.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:raumfreund/app/native_licenses.dart';
import 'package:raumfreund/app/raumfreund_app.dart';
import 'package:raumfreund/core/clock.dart';
import 'package:raumfreund/core/scheduler.dart';
import 'package:raumfreund/features/monitor/application/monitor_controller.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/monitor/domain/calibration.dart';
import 'package:raumfreund/features/monitor/domain/level_history.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/shop/domain/shop_repository.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';

/// Length of the pre-filled lesson shown by the timeline at app start.
const Duration _lesson = Duration(minutes: 10);

/// Stars already in the wallet, so the shop has something to sell on cue.
const int _seedStars = 10;

void main() {
  registerNativeLicenses();
  final clock = _OffsetClock(_lesson);
  runApp(
    RaumfreundApp(
      shopRepository: _MemoryShopRepository(StarWallet(balance: _seedStars)),
      monitorFactory: (onStarEarned) {
        final source = _ScriptedLevelSource(clock);
        return MonitorController(
          permission: const _GrantedPermission(),
          levelSource: source,
          alarmOutput: const _SilentAlarm(),
          screenAwake: const _NoScreenAwake(),
          clock: clock,
          scheduler: const DartTimerScheduler(),
          settings: AppSettings.defaults,
          history: _lessonHistory(),
          onStarEarned: onStarEarned,
        );
      },
    ),
  );
}

/// Clock that starts at [offset], so a pre-filled lesson fits before "now".
final class _OffsetClock implements MonotonicClock {
  _OffsetClock(this.offset);

  final Duration offset;
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  Duration get now => offset + _stopwatch.elapsed;
}

/// Ten minutes of a plausible lesson: quiet work, a lively group phase and
/// one loud moment, so the timeline shows all three zones.
LevelHistory _lessonHistory() {
  final history = LevelHistory();
  for (var second = 0; second < _lesson.inSeconds; second++) {
    final minute = second / 60;
    final busy = math.exp(-math.pow(minute - 4.5, 2) / 1.2) * 22;
    final shout = math.exp(-math.pow(minute - 7.2, 2) / 0.05) * 38;
    final level = 44 + busy + shout + _wobble(second.toDouble());
    history.add(timestamp: Duration(seconds: second), levelDb: level);
  }
  return history;
}

/// Small deterministic variation, so levels look alive but replay exactly.
double _wobble(double t) =>
    3 * math.sin(t * 1.7) + 2 * math.sin(t * 0.37 + 1) + math.sin(t * 5.3);

/// Level in dB for second [t] of measurement session [run].
///
/// Run 1 shows a quiet start (stars), noise rising through yellow to red
/// until the alarm sends Mia away, and calm again so she returns. Later runs
/// stay quiet, to show Mia with her new accessories.
double _scriptedLevel(int run, double t) {
  final calm = 46 + _wobble(t * 3);
  if (run > 1) return calm;
  if (t < 12) return calm;
  if (t < 15) return 68 + _wobble(t * 3);
  if (t < 27) return 86 + _wobble(t * 4);
  return calm;
}

/// Emits one scripted reading every 100 ms while a session runs.
final class _ScriptedLevelSource implements LevelSourcePort {
  _ScriptedLevelSource(this._clock);

  final MonotonicClock _clock;
  final StreamController<LevelEvent> _events = StreamController.broadcast();
  Timer? _timer;
  int _runs = 0;

  @override
  Stream<LevelEvent> get events => _events.stream;

  @override
  Future<void> start(int sessionId) async {
    _timer?.cancel();
    final run = ++_runs;
    final startedAt = _clock.now;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final t = (_clock.now - startedAt).inMilliseconds / 1000;
      final db = _scriptedLevel(run, t);
      _events.add(LevelReading(sessionId, db - Calibration.baseOffsetDb));
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}

final class _GrantedPermission implements MicrophonePermissionPort {
  const _GrantedPermission();

  @override
  Future<MicrophonePermissionStatus> status() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<MicrophonePermissionStatus> request() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<void> openAppSettings() async {}
}

/// The alarm "plays" for as long as the native tone would, silently.
final class _SilentAlarm implements AlarmOutputPort {
  const _SilentAlarm();

  @override
  Future<void> play({required bool sound, required bool vibrate}) =>
      Future<void>.delayed(const Duration(milliseconds: 500));
}

final class _NoScreenAwake implements ScreenAwakePort {
  const _NoScreenAwake();

  @override
  Future<void> setKeepScreenOn({required bool enabled}) async {}
}

/// Wallet in RAM, seeded for the recording.
final class _MemoryShopRepository implements ShopRepository {
  _MemoryShopRepository(this._wallet);

  StarWallet _wallet;

  @override
  Future<StarWallet> load() async => _wallet;

  @override
  Future<void> save(StarWallet wallet) async => _wallet = wallet;
}
