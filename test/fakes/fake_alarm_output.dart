// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/monitor/application/ports.dart';

/// One recorded [AlarmOutputPort.play] call.
final class AlarmPlayCall {
  /// Creates a record.
  AlarmPlayCall({required this.sound, required this.vibrate});

  /// Requested sound flag.
  final bool sound;

  /// Requested vibration flag.
  final bool vibrate;

  /// Completes the call (the tone has ended).
  final Completer<void> completer = Completer<void>();
}

/// [AlarmOutputPort] whose plays stay pending until the test completes them.
final class FakeAlarmOutput implements AlarmOutputPort {
  /// All play calls in order.
  final List<AlarmPlayCall> calls = [];

  /// Whether a play call is not yet completed.
  bool get isPlaying => calls.any((c) => !c.completer.isCompleted);

  @override
  Future<void> play({required bool sound, required bool vibrate}) {
    final call = AlarmPlayCall(sound: sound, vibrate: vibrate);
    calls.add(call);
    return call.completer.future;
  }

  /// Ends the latest play call successfully.
  void finish() => calls.last.completer.complete();

  /// Ends the latest play call with [error].
  void fail([Exception error = const FormatException('no audio')]) =>
      calls.last.completer.completeError(error);
}
