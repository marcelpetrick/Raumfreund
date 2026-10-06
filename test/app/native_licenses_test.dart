// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/native_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles the Apache-2.0 and Material Icons licence texts', () async {
    final entries = await nativeLicenses().toList();
    expect(entries, hasLength(2));
    expect(entries.first.packages, androidLibraryPackages);
    final apache = entries.first.paragraphs.map((p) => p.text).join('\n');
    expect(apache, contains('Apache License'));
    expect(entries.last.packages, ['Material Icons']);
    final icons = entries.last.paragraphs.map((p) => p.text).join('\n');
    expect(icons, contains('Attribution 4.0 International'));
  });

  test('registration makes the entries visible to the licence page', () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);
    registerNativeLicenses();
    final packages = await LicenseRegistry.licenses
        .expand((entry) => entry.packages)
        .toSet();
    expect(packages, containsAll(['AndroidX', 'Okio', 'Material Icons']));
  });
}
