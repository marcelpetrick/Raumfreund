// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets pending microtasks and zero-delay timers run (outside of
/// `testWidgets`, where `tester.pump` does this).
Future<void> settle([int rounds = 20]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Collects errors reported via [FlutterError.reportError] during the
/// current test instead of failing it. Restored automatically.
List<FlutterErrorDetails> captureFlutterErrors() {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  addTearDown(() => FlutterError.onError = previous);
  return errors;
}
