// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/application/ports.dart';
import 'package:raumfreund/features/monitor/infrastructure/platform_monitor_ports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('raumfreund.test/control');
  final calls = <MethodCall>[];
  Object? result;
  PlatformException? failure;

  setUp(() {
    calls.clear();
    result = null;
    failure = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (failure case final error?) throw error;
          return result;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('uses the stable Android channel names', () {
    expect(
      PlatformMonitorPorts.controlChannelName,
      'it.marcelpetrick.raumfreund/control',
    );
    expect(
      PlatformMonitorPorts.levelsChannelName,
      'it.marcelpetrick.raumfreund/levels',
    );
  });

  test('maps permission responses and rejects malformed values', () async {
    final ports = PlatformMonitorPorts(control: channel);
    for (final entry in <String, MicrophonePermissionStatus>{
      'granted': MicrophonePermissionStatus.granted,
      'denied': MicrophonePermissionStatus.denied,
      'permanentlyDenied': MicrophonePermissionStatus.permanentlyDenied,
    }.entries) {
      result = entry.key;
      expect(await ports.status(), entry.value);
      expect(await ports.request(), entry.value);
    }
    result = 'surprise';
    await expectLater(ports.status(), throwsFormatException);
  });

  test('forwards all control commands and their arguments', () async {
    final ports = PlatformMonitorPorts(control: channel);
    await ports.openAppSettings();
    await ports.start(17);
    await ports.stop();
    await ports.play(sound: true, vibrate: false);
    await ports.setKeepScreenOn(enabled: true);
    expect(calls.map((call) => call.method), [
      'openAppSettings',
      'startLevels',
      'stopLevels',
      'playAlarm',
      'setKeepScreenOn',
    ]);
    expect(calls[1].arguments, {'sessionId': 17});
    expect(calls[3].arguments, {'sound': true, 'vibrate': false});
    expect(calls[4].arguments, {'enabled': true});
  });

  test('maps native start failures to domain failures', () async {
    final ports = PlatformMonitorPorts(control: channel);
    for (final entry in <String, LevelFailure>{
      'permissionMissing': LevelFailure.permissionMissing,
      'microphoneBusy': LevelFailure.microphoneBusy,
      'recordingAborted': LevelFailure.recordingAborted,
      'anythingElse': LevelFailure.unavailable,
    }.entries) {
      failure = PlatformException(code: entry.key);
      await expectLater(
        ports.start(1),
        throwsA(
          isA<LevelSourceException>().having(
            (error) => error.failure,
            'failure',
            entry.value,
          ),
        ),
      );
    }
  });

  _eventTests(channel);
}

void _eventTests(MethodChannel channel) {
  test('decodes readings and error events on one cached stream', () async {
    final raw = Stream<Object?>.fromIterable([
      {'sessionId': 1, 'dbfs': -22},
      {'sessionId': 2, 'error': 'microphoneBusy'},
    ]);
    final ports = PlatformMonitorPorts(control: channel, rawEvents: raw);
    expect(identical(ports.events, ports.events), isTrue);
    final events = await ports.events.toList();
    expect(events[0], isA<LevelReading>());
    expect((events[0] as LevelReading).dbfs, -22);
    expect(events[1], isA<LevelError>());
    expect((events[1] as LevelError).failure, LevelFailure.microphoneBusy);
  });

  test('rejects every malformed event shape', () async {
    final invalid = <Object?>[
      'not a map',
      {'sessionId': 0, 'dbfs': -1},
      {'sessionId': '1', 'dbfs': -1},
      {'sessionId': 1, 'dbfs': 'loud'},
      {'sessionId': 1, 'dbfs': double.nan},
      {'sessionId': 1, 'dbfs': 0.1},
    ];
    for (final value in invalid) {
      final ports = PlatformMonitorPorts(
        control: channel,
        rawEvents: Stream<Object?>.value(value),
      );
      await expectLater(ports.events.toList(), throwsFormatException);
    }
  });
}
