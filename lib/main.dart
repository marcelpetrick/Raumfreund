// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import 'app/native_licenses.dart';
import 'app/raumfreund_app.dart';

/// Entry point of the Raumfreund app.
void main() {
  registerNativeLicenses();
  runApp(const RaumfreundApp());
}
