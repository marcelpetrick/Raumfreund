// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:raumfreund/features/monitor/application/ports.dart';

/// [ScreenAwakePort] recording every call.
final class FakeScreenAwake implements ScreenAwakePort {
  /// Values passed to [setKeepScreenOn], in order.
  final List<bool> calls = [];

  /// When set, [setKeepScreenOn] throws it (after recording the call).
  Exception? exception;

  /// Last requested state (false initially).
  bool get isOn => calls.isNotEmpty && calls.last;

  @override
  Future<void> setKeepScreenOn({required bool enabled}) async {
    calls.add(enabled);
    final error = exception;
    if (error != null) throw error;
  }
}
