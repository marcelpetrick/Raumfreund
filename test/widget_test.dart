// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/main.dart' as app;

void main() {
  testWidgets('main() starts the app and shows its name', (tester) async {
    app.main();
    await tester.pump();
    expect(find.text('Raumfreund'), findsOneWidget);
  });
}
