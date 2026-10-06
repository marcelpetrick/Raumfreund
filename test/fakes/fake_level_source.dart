// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/monitor/application/ports.dart';

/// Controllable [LevelSourcePort].
///
/// By default [start] completes immediately. Set [holdStart] to keep the
/// next start pending until [completeStart] / [failStart] is called, or set
/// [startFailure] to make the next start throw a [LevelSourceException].
/// Events are delivered synchronously to listeners.
final class FakeLevelSource implements LevelSourcePort {
  final StreamController<LevelEvent> _events =
      StreamController<LevelEvent>.broadcast(sync: true);

  /// Session ids passed to [start], in call order.
  final List<int> startCalls = [];

  /// Number of [stop] calls.
  int stopCalls = 0;

  /// When true, the next [start] stays pending (see [completeStart]).
  bool holdStart = false;

  /// When set, the next [start] throws a [LevelSourceException] with it.
  LevelFailure? startFailure;

  /// When set, the next [start] throws this (non-port) exception.
  Exception? startException;

  /// When set, [stop] throws this exception.
  Exception? stopException;

  /// When set, [stop] waits for this gate before completing.
  Completer<void>? stopGate;

  /// Session currently recording (after a successful start, until stop).
  int? recordingSession;

  Completer<void>? _pendingStart;

  /// Whether someone listens to [events].
  bool get hasListener => _events.hasListener;

  /// Whether a held start is pending.
  bool get isStartPending => _pendingStart != null;

  @override
  Stream<LevelEvent> get events => _events.stream;

  @override
  Future<void> start(int sessionId) async {
    startCalls.add(sessionId);
    final failure = startFailure;
    startFailure = null;
    if (failure != null) throw LevelSourceException(failure);
    final exception = startException;
    startException = null;
    if (exception != null) throw exception;
    if (holdStart) {
      holdStart = false;
      final pending = _pendingStart = Completer<void>();
      await pending.future;
    }
    recordingSession = sessionId;
  }

  /// Completes a held [start].
  void completeStart() {
    final pending = _pendingStart!;
    _pendingStart = null;
    pending.complete();
  }

  /// Fails a held [start] with [failure].
  void failStart(LevelFailure failure) {
    final pending = _pendingStart!;
    _pendingStart = null;
    pending.completeError(LevelSourceException(failure));
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    recordingSession = null;
    final gate = stopGate;
    if (gate != null) await gate.future;
    final exception = stopException;
    if (exception != null) throw exception;
  }

  /// Emits a reading for [sessionId].
  void emitReading(int sessionId, double dbfs) =>
      _events.add(LevelReading(sessionId, dbfs));

  /// Emits a failure for [sessionId].
  void emitError(int sessionId, LevelFailure failure) =>
      _events.add(LevelError(sessionId, failure));

  /// Emits an unexpected transport/decoder error on the stream.
  void emitStreamError(Object error) =>
      _events.addError(error, StackTrace.current);

  /// Closes the event stream.
  Future<void> close() => _events.close();
}
