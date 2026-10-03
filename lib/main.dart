// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

/// Entry point of the Raumfreund app.
void main() => runApp(const RaumfreundApp());

/// Root widget. Replaced by the composed application in a later milestone.
class RaumfreundApp extends StatelessWidget {
  /// Creates the root widget.
  const RaumfreundApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Raumfreund',
    home: Scaffold(body: Center(child: Text('Raumfreund'))),
  );
}
