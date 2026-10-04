// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:raumfreund/features/monitor/application/ports.dart';

/// Controllable [MicrophonePermissionPort].
///
/// [currentStatus] is returned by [status]; [request] returns
/// [requestResult] (and stores it in [currentStatus]) unless [holdRequest]
/// is set, in which case it waits for [completeRequest].
final class FakePermission implements MicrophonePermissionPort {
  /// Creates a fake with the given initial status and request result.
  FakePermission({
    this.currentStatus = MicrophonePermissionStatus.granted,
    this.requestResult = MicrophonePermissionStatus.granted,
  });

  /// Result of [status].
  MicrophonePermissionStatus currentStatus;

  /// Result of [request] when not held.
  MicrophonePermissionStatus requestResult;

  /// When true, the next [request] waits for [completeRequest].
  bool holdRequest = false;

  /// When set, [status] throws it.
  Exception? statusException;

  /// When set, [openAppSettings] throws it.
  Exception? openSettingsException;

  /// Number of [status] calls.
  int statusCalls = 0;

  /// Number of [request] calls.
  int requestCalls = 0;

  /// Number of [openAppSettings] calls.
  int openSettingsCalls = 0;

  Completer<MicrophonePermissionStatus>? _pending;

  /// Whether a held request waits for [completeRequest].
  bool get isRequestPending => _pending != null;

  @override
  Future<MicrophonePermissionStatus> status() async {
    statusCalls++;
    final exception = statusException;
    if (exception != null) throw exception;
    return currentStatus;
  }

  @override
  Future<MicrophonePermissionStatus> request() async {
    requestCalls++;
    if (!holdRequest) return currentStatus = requestResult;
    holdRequest = false;
    final pending = _pending = Completer<MicrophonePermissionStatus>();
    return currentStatus = await pending.future;
  }

  /// Answers a held request with [result].
  void completeRequest(MicrophonePermissionStatus result) {
    final pending = _pending!;
    _pending = null;
    pending.complete(result);
  }

  @override
  Future<void> openAppSettings() async {
    openSettingsCalls++;
    final exception = openSettingsException;
    if (exception != null) throw exception;
  }
}
