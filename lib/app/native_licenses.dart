// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset with the Apache License 2.0 text of the Android libraries.
const String apacheLicenseAsset = 'assets/licenses/apache-2.0.txt';

/// Asset with the CC-BY-4.0 text the Flutter SDK ships for Material Icons.
const String materialIconsLicenseAsset =
    'assets/licenses/material-icons-cc-by-4.0.txt';

/// Apache-2.0 libraries that ship in the APK through Gradle.
///
/// Flutter's generated NOTICES only cover the engine and Dart packages, so
/// these would otherwise be missing from the licence page although Apache-2.0
/// section 4(a) requires that recipients receive the licence. The list
/// follows `docs/third-party-licenses.md` and must change with it.
const List<String> androidLibraryPackages = [
  'AndroidX',
  'Kotlin Standard Library',
  'kotlinx.coroutines',
  'Okio',
  'JetBrains Java Annotations',
  'Guava ListenableFuture',
  'ReLinker',
  'JSpecify',
];

/// Licence entries for bundled native code and fonts that Flutter's
/// NOTICES do not contain. Texts load lazily, only when the licence page
/// collects them.
Stream<LicenseEntry> nativeLicenses({AssetBundle? bundle}) async* {
  final assets = bundle ?? rootBundle;
  yield LicenseEntryWithLineBreaks(
    androidLibraryPackages,
    await assets.loadString(apacheLicenseAsset),
  );
  yield LicenseEntryWithLineBreaks(const [
    'Material Icons',
  ], await assets.loadString(materialIconsLicenseAsset));
}

/// Adds [nativeLicenses] to Flutter's licence registry; call once at start.
void registerNativeLicenses() => LicenseRegistry.addLicense(nativeLicenses);
