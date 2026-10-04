// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/about/infrastructure/platform_app_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('raumfreund.test/app-info');
  Object? result;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'appInfo');
          return result;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads package version and build', () async {
    result = {'versionName': '1.2.3', 'versionCode': 42};
    final info = await PlatformAppInfoPort(channel: channel).load();
    expect(info.versionName, '1.2.3');
    expect(info.buildNumber, 42);
    expect(info.gitCommit, 'unknown');
  });

  test('rejects malformed app information', () async {
    for (final value in <Object?>[
      null,
      <Object?, Object?>{},
      {'versionName': '', 'versionCode': 1},
      {'versionName': '1.0.0', 'versionCode': '1'},
    ]) {
      result = value;
      await expectLater(
        PlatformAppInfoPort(channel: channel).load(),
        throwsFormatException,
      );
    }
  });
}
