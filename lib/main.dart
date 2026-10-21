// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import 'app/native_licenses.dart';
import 'app/raumfreund_app.dart';
import 'features/settings/application/language_controller.dart';
import 'features/settings/infrastructure/shared_preferences_language_repository.dart';

/// Entry point of the Raumfreund app.
///
/// Loads the stored UI language before the first frame, so the app never
/// flashes German before switching to the chosen language. Loading falls
/// back to German instead of failing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerNativeLicenses();
  final language = LanguageController(SharedPreferencesLanguageRepository());
  await language.load();
  runApp(RaumfreundApp(languageController: language));
}
