// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/about/domain/app_info.dart';

void main() {
  test('holds its values', () {
    const info = AppInfo(
      versionName: '1.2.3',
      buildNumber: 7,
      gitCommit: 'abc',
    );
    expect(info.versionName, '1.2.3');
    expect(info.buildNumber, 7);
    expect(info.gitCommit, 'abc');
  });
}
