// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/services.dart';

import '../application/ports.dart';

/// Android method/event-channel implementation of the monitor platform ports.
final class PlatformMonitorPorts
    implements
        MicrophonePermissionPort,
        LevelSourcePort,
        AlarmOutputPort,
        ScreenAwakePort {
  /// Creates the adapter. Injectable channels keep protocol tests native-free.
  PlatformMonitorPorts({
    MethodChannel? control,
    EventChannel? levels,
    this.rawEvents,
  }) : _control = control ?? const MethodChannel(controlChannelName),
       _levels = levels ?? const EventChannel(levelsChannelName);

  /// Control channel name shared with Kotlin.
  static const String controlChannelName =
      'it.marcelpetrick.raumfreund/control';

  /// Level event channel name shared with Kotlin.
  static const String levelsChannelName = 'it.marcelpetrick.raumfreund/levels';

  final MethodChannel _control;
  final EventChannel _levels;

  /// Optional raw event source used by protocol tests.
  final Stream<Object?>? rawEvents;
  Stream<LevelEvent>? _events;

  @override
  Stream<LevelEvent> get events => _events ??=
      (rawEvents ?? _levels.receiveBroadcastStream()).map(_decodeEvent);

  @override
  Future<MicrophonePermissionStatus> status() async =>
      _permission(await _control.invokeMethod<Object?>('permissionStatus'));

  @override
  Future<MicrophonePermissionStatus> request() async =>
      _permission(await _control.invokeMethod<Object?>('requestPermission'));

  @override
  Future<void> openAppSettings() =>
      _control.invokeMethod<void>('openAppSettings');

  @override
  Future<void> start(int sessionId) async {
    try {
      await _control.invokeMethod<void>('startLevels', {
        'sessionId': sessionId,
      });
    } on PlatformException catch (error) {
      throw LevelSourceException(_failure(error.code));
    }
  }

  @override
  Future<void> stop() => _control.invokeMethod<void>('stopLevels');

  @override
  Future<void> play({required bool sound, required bool vibrate}) => _control
      .invokeMethod<void>('playAlarm', {'sound': sound, 'vibrate': vibrate});

  @override
  Future<void> setKeepScreenOn({required bool enabled}) =>
      _control.invokeMethod<void>('setKeepScreenOn', {'enabled': enabled});

  static MicrophonePermissionStatus _permission(Object? value) =>
      switch (value) {
        'granted' => MicrophonePermissionStatus.granted,
        'denied' => MicrophonePermissionStatus.denied,
        'permanentlyDenied' => MicrophonePermissionStatus.permanentlyDenied,
        _ => throw const FormatException(
          'Invalid microphone permission status',
        ),
      };

  static LevelEvent _decodeEvent(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Level event is not a map');
    }
    final sessionId = value['sessionId'];
    if (sessionId is! int || sessionId <= 0) {
      throw const FormatException('Invalid level event sessionId');
    }
    final error = value['error'];
    if (error is String) return LevelError(sessionId, _failure(error));
    final dbfs = value['dbfs'];
    if (dbfs is! num || !dbfs.toDouble().isFinite || dbfs > 0) {
      throw const FormatException('Invalid dBFS level');
    }
    return LevelReading(sessionId, dbfs.toDouble());
  }

  static LevelFailure _failure(String code) => switch (code) {
    'permissionMissing' => LevelFailure.permissionMissing,
    'microphoneBusy' => LevelFailure.microphoneBusy,
    'recordingAborted' => LevelFailure.recordingAborted,
    _ => LevelFailure.unavailable,
  };
}
