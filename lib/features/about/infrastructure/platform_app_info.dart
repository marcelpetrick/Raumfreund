// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/services.dart';

import '../domain/app_info.dart';

/// Loads Android package information through the shared control channel.
final class PlatformAppInfoPort implements AppInfoPort {
  /// Creates the adapter with an injectable channel for tests.
  PlatformAppInfoPort({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_controlChannelName);

  static const String _controlChannelName =
      'it.marcelpetrick.raumfreund/control';
  static const String _gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'unknown',
  );

  final MethodChannel _channel;

  @override
  Future<AppInfo> load() async {
    final value = await _channel.invokeMethod<Object?>('appInfo');
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('App info is not a map');
    }
    final version = value['versionName'];
    final build = value['versionCode'];
    if (version is! String || version.isEmpty || build is! int) {
      throw const FormatException('Invalid app info');
    }
    return AppInfo(
      versionName: version,
      buildNumber: build,
      gitCommit: _gitCommit,
    );
  }
}
