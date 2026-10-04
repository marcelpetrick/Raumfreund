// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto and the Material icon font from the pinned Flutter SDK so
/// goldens show real glyphs instead of the test font's boxes.
///
/// The SDK is located through FLUTTER_ROOT (set by `flutter test`). Missing
/// fonts fail the test loudly instead of silently producing other pixels.
Future<void> loadGoldenFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) fail('FLUTTER_ROOT is not set; run via tool/flutter.sh');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  await _load('Roboto', [
    '$dir/Roboto-Regular.ttf',
    '$dir/Roboto-Medium.ttf',
    '$dir/Roboto-Bold.ttf',
    '$dir/Roboto-Black.ttf',
  ]);
  await _load('MaterialIcons', ['$dir/MaterialIcons-Regular.otf']);
}

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final path in files) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
