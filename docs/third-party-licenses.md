<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Third-party licenses

This is the inventory of third-party software in Raumfreund `0.6.0+45` (dependencies unchanged since `0.5.4+43`)
(Flutter `3.47.6`, Dart `3.13.5`). Raumfreund itself is GPL-3.0-only. All
listed licenses are permissive (BSD-3-Clause, Apache-2.0) and compatible with
distribution under GPLv3 (see [GPL compatibility](#gpl-compatibility)).

How it was determined (so it can be reproduced and re-checked):

- Dart packages and versions come from `pubspec.lock`; main versus dev
  membership from `flutter pub deps --style=compact`.
- Dart licenses were read from the `LICENSE` files in the pub cache
  (`~/.pub-cache/hosted/pub.dev/<package>-<version>/`) and classified by their
  text (BSD-3-Clause: "Redistribution and use ... Neither the name of ...";
  Apache-2.0: "Apache License, Version 2.0"). SDK packages use the Flutter
  SDK `LICENSE` (BSD-3-Clause).
- Android libraries come from the `sdkDependencies.txt` that the Android
  Gradle Plugin generates for the release variant
  (`build/app/outputs/sdk-dependencies/release/`) and from the APK's
  `META-INF/*.version` files. Their licenses (Apache-2.0 for AndroidX, Kotlin,
  kotlinx.coroutines, Okio, JetBrains annotations, Guava `listenablefuture`,
  ReLinker, JSpecify; BSD-3-Clause for the Flutter embedding) are the
  publicly documented licenses of those artifacts and were **not** re-verified
  from the POM/jar files in this pass.
- The inventory must be regenerated whenever `pubspec.lock`, the Flutter pin
  or an Android dependency changes.

## What ships in the release APK

Only `dependencies` (and their transitive closure) are part of the app; the
`dev_dependencies` closure is used for tests and analysis only.

### Flutter engine and framework

| Component | Version | License | Source |
| --- | --- | --- | --- |
| Flutter framework (`flutter`, `flutter_localizations`, `sky_engine`) | 3.47.6 | BSD-3-Clause | [flutter/flutter](https://github.com/flutter/flutter), `LICENSE` of the SDK |
| Flutter engine (`libflutter.so`, per ABI) | `692136cb6582dbfc5af3fb33c2515a069f2f66d0` | BSD-3-Clause plus bundled third-party code | [flutter/flutter `engine/`](https://github.com/flutter/flutter/tree/3.47.6/engine) |
| Dart runtime (inside `libflutter.so` / `libapp.so`) | 3.13.5 | BSD-3-Clause | [dart-lang/sdk](https://github.com/dart-lang/sdk) |
| Material Icons font (`MaterialIcons-Regular.otf`) | bundled with Flutter 3.47.6 | Apache-2.0 | `bin/cache/artifacts/material_fonts/MaterialIcons_LICENSE.txt` in the SDK |
| Fragment shaders `ink_sparkle.frag`, `stretch_effect.frag` | bundled with Flutter 3.47.6 | BSD-3-Clause | Flutter SDK |

The engine statically bundles further third-party code (Skia, ICU, FreeType,
HarfBuzz, libpng, libjpeg-turbo, libwebp, zlib, BoringSSL, Impeller
dependencies and others) under their own licenses (BSD-style, MIT, ICU,
FreeType License, Apache-2.0 and similar). Flutter collects these notices
itself in the APK asset `assets/flutter_assets/NOTICES.Z`
(about 1.3 MB of text in the inspected build).

The inspected release APK is a locally built, debug-signed artifact; the
Material Icons font license text is not part of `NOTICES.Z` (see the
open points).

### Dart packages (main, ships)

Direct dependencies (`pubspec.yaml`):

| Package | Version | License | Source | In Android build |
| --- | --- | --- | --- | --- |
| `flutter` | 0.0.0 | BSD-3-Clause | Flutter SDK (`sdk: flutter`) | compiled |
| `flutter_localizations` | 0.0.0 | BSD-3-Clause | Flutter SDK (`sdk: flutter`) | compiled |
| `intl` | 0.20.3 | BSD-3-Clause | [pub.dev/packages/intl](https://pub.dev/packages/intl/versions/0.20.3) | compiled |
| `shared_preferences` | 2.5.6 | BSD-3-Clause | [pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences/versions/2.5.6) | compiled |

Transitive main dependencies. "compiled" means the package is part of the
Dart code path used on Android (inferred from the import graph and the
Android federated plugin, not from decompiling `libapp.so`); "graph only"
means pub resolves it because `shared_preferences` or `flutter` lists
platform implementations for other platforms (iOS, Linux, Windows, Web), but
it is not used by an Android build. They are listed anyway because Flutter
still includes their notices in `NOTICES.Z` and the conservative reading is
to treat them as part of the distribution.

| Package | Version | License | Source | In Android build |
| --- | --- | --- | --- | --- |
| `characters` | 1.4.1 | BSD-3-Clause | [pub.dev/packages/characters](https://pub.dev/packages/characters/versions/1.4.1) | compiled |
| `clock` | 1.1.3 | Apache-2.0 | [pub.dev/packages/clock](https://pub.dev/packages/clock/versions/1.1.3) | compiled |
| `collection` | 1.19.1 | BSD-3-Clause | [pub.dev/packages/collection](https://pub.dev/packages/collection/versions/1.19.1) | compiled |
| `ffi` | 2.2.0 | BSD-3-Clause | [pub.dev/packages/ffi](https://pub.dev/packages/ffi/versions/2.2.0) | graph only |
| `file` | 7.0.1 | BSD-3-Clause | [pub.dev/packages/file](https://pub.dev/packages/file/versions/7.0.1) | graph only |
| `flutter_web_plugins` | 0.0.0 | BSD-3-Clause | Flutter SDK (`sdk: flutter`) | graph only |
| `material_color_utilities` | 0.13.0 | Apache-2.0 | [pub.dev/packages/material_color_utilities](https://pub.dev/packages/material_color_utilities/versions/0.13.0) | compiled |
| `meta` | 1.19.0 | BSD-3-Clause | [pub.dev/packages/meta](https://pub.dev/packages/meta/versions/1.19.0) | compiled |
| `path` | 1.9.1 | BSD-3-Clause | [pub.dev/packages/path](https://pub.dev/packages/path/versions/1.9.1) | compiled |
| `path_provider_linux` | 2.2.2 | BSD-3-Clause | [pub.dev/packages/path_provider_linux](https://pub.dev/packages/path_provider_linux/versions/2.2.2) | graph only |
| `path_provider_platform_interface` | 2.1.3 | BSD-3-Clause | [pub.dev/packages/path_provider_platform_interface](https://pub.dev/packages/path_provider_platform_interface/versions/2.1.3) | graph only |
| `path_provider_windows` | 2.3.0 | BSD-3-Clause | [pub.dev/packages/path_provider_windows](https://pub.dev/packages/path_provider_windows/versions/2.3.0) | graph only |
| `platform` | 3.2.0 | BSD-3-Clause | [pub.dev/packages/platform](https://pub.dev/packages/platform/versions/3.2.0) | graph only |
| `plugin_platform_interface` | 2.1.8 | BSD-3-Clause | [pub.dev/packages/plugin_platform_interface](https://pub.dev/packages/plugin_platform_interface/versions/2.1.8) | compiled |
| `shared_preferences_android` | 2.4.28 | BSD-3-Clause | [pub.dev/packages/shared_preferences_android](https://pub.dev/packages/shared_preferences_android/versions/2.4.28) | compiled |
| `shared_preferences_foundation` | 2.5.7 | BSD-3-Clause | [pub.dev/packages/shared_preferences_foundation](https://pub.dev/packages/shared_preferences_foundation/versions/2.5.7) | graph only |
| `shared_preferences_linux` | 2.4.1 | BSD-3-Clause | [pub.dev/packages/shared_preferences_linux](https://pub.dev/packages/shared_preferences_linux/versions/2.4.1) | graph only |
| `shared_preferences_platform_interface` | 2.4.2 | BSD-3-Clause | [pub.dev/packages/shared_preferences_platform_interface](https://pub.dev/packages/shared_preferences_platform_interface/versions/2.4.2) | compiled |
| `shared_preferences_web` | 2.4.3 | BSD-3-Clause | [pub.dev/packages/shared_preferences_web](https://pub.dev/packages/shared_preferences_web/versions/2.4.3) | graph only |
| `shared_preferences_windows` | 2.4.1 | BSD-3-Clause | [pub.dev/packages/shared_preferences_windows](https://pub.dev/packages/shared_preferences_windows/versions/2.4.1) | graph only |
| `sky_engine` | 0.0.0 | BSD-3-Clause | Flutter SDK (`sdk: flutter`) | compiled |
| `vector_math` | 2.4.3 | BSD-3-Clause | [pub.dev/packages/vector_math](https://pub.dev/packages/vector_math/versions/2.4.3) | compiled |
| `web` | 1.1.1 | BSD-3-Clause | [pub.dev/packages/web](https://pub.dev/packages/web/versions/1.1.1) | graph only |
| `xdg_directories` | 1.1.0 | BSD-3-Clause | [pub.dev/packages/xdg_directories](https://pub.dev/packages/xdg_directories/versions/1.1.0) | graph only |

### Android and Gradle libraries (main, ships)

Resolved release runtime dependencies of the Android app (88 artifacts), from
the AGP SDK dependency report. The main sources are the Flutter
embedding and engine (`io.flutter`) and the `shared_preferences_android`
plugin (AndroidX DataStore 1.1.7, AndroidX Preference 1.2.1); the Kotlin
standard library and everything else is pulled in transitively.

| Group | Artifact | Version | License | Source |
| --- | --- | --- | --- | --- |
| `org.jetbrains.kotlin` | `kotlin-stdlib` | 2.4.0 | Apache-2.0 | Maven Central |
| `org.jetbrains` | `annotations` | 23.0.0 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlin` | `kotlin-stdlib-jdk8` | 1.8.20 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlin` | `kotlin-stdlib-jdk7` | 1.8.20 | Apache-2.0 | Maven Central |
| `io.flutter` | `armeabi_v7a_release` | 1.0.0-692136cb6582dbfc5af3fb33c2515a069f2f66d0 | BSD-3-Clause | Flutter engine Maven repository |
| `io.flutter` | `arm64_v8a_release` | 1.0.0-692136cb6582dbfc5af3fb33c2515a069f2f66d0 | BSD-3-Clause | Flutter engine Maven repository |
| `io.flutter` | `x86_64_release` | 1.0.0-692136cb6582dbfc5af3fb33c2515a069f2f66d0 | BSD-3-Clause | Flutter engine Maven repository |
| `androidx.datastore` | `datastore` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-android` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.annotation` | `annotation` | 1.8.1 | Apache-2.0 | Google Maven |
| `androidx.annotation` | `annotation-jvm` | 1.8.1 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-core` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-core-android` | 1.1.7 | Apache-2.0 | Google Maven |
| `org.jetbrains.kotlin` | `kotlin-parcelize-runtime` | 1.9.22 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlin` | `kotlin-android-extensions-runtime` | 1.9.22 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlinx` | `kotlinx-coroutines-core` | 1.7.3 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlinx` | `kotlinx-coroutines-core-jvm` | 1.7.3 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlinx` | `kotlinx-coroutines-bom` | 1.7.3 | Apache-2.0 | Maven Central |
| `org.jetbrains.kotlinx` | `kotlinx-coroutines-android` | 1.7.3 | Apache-2.0 | Maven Central |
| `androidx.datastore` | `datastore-core-okio` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-core-okio-jvm` | 1.1.7 | Apache-2.0 | Google Maven |
| `com.squareup.okio` | `okio` | 3.4.0 | Apache-2.0 | Maven Central |
| `com.squareup.okio` | `okio-jvm` | 3.4.0 | Apache-2.0 | Maven Central |
| `androidx.datastore` | `datastore-preferences` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-preferences-android` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-preferences-core` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-preferences-core-android` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-preferences-proto` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.datastore` | `datastore-preferences-external-protobuf` | 1.1.7 | Apache-2.0 | Google Maven |
| `androidx.preference` | `preference` | 1.2.1 | Apache-2.0 | Google Maven |
| `androidx.appcompat` | `appcompat` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.core` | `core` | 1.13.1 | Apache-2.0 | Google Maven |
| `androidx.annotation` | `annotation-experimental` | 1.4.0 | Apache-2.0 | Google Maven |
| `androidx.collection` | `collection` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.concurrent` | `concurrent-futures` | 1.1.0 | Apache-2.0 | Google Maven |
| `com.google.guava` | `listenablefuture` | 1.0 | Apache-2.0 | Maven Central |
| `androidx.interpolator` | `interpolator` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-runtime` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.arch.core` | `core-common` | 2.2.0 | Apache-2.0 | Google Maven |
| `androidx.arch.core` | `core-runtime` | 2.2.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-common` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-common-java8` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-process` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.startup` | `startup-runtime` | 1.1.1 | Apache-2.0 | Google Maven |
| `androidx.tracing` | `tracing` | 1.2.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-livedata-core` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-livedata` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-livedata-core-ktx` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-runtime-ktx` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-viewmodel` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-viewmodel-ktx` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.lifecycle` | `lifecycle-viewmodel-savedstate` | 2.7.0 | Apache-2.0 | Google Maven |
| `androidx.core` | `core-ktx` | 1.13.1 | Apache-2.0 | Google Maven |
| `androidx.savedstate` | `savedstate` | 1.2.1 | Apache-2.0 | Google Maven |
| `androidx.savedstate` | `savedstate-ktx` | 1.2.1 | Apache-2.0 | Google Maven |
| `androidx.profileinstaller` | `profileinstaller` | 1.3.1 | Apache-2.0 | Google Maven |
| `androidx.versionedparcelable` | `versionedparcelable` | 1.1.1 | Apache-2.0 | Google Maven |
| `androidx.cursoradapter` | `cursoradapter` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.fragment` | `fragment` | 1.7.1 | Apache-2.0 | Google Maven |
| `androidx.activity` | `activity` | 1.8.1 | Apache-2.0 | Google Maven |
| `androidx.activity` | `activity-ktx` | 1.8.1 | Apache-2.0 | Google Maven |
| `androidx.loader` | `loader` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.viewpager` | `viewpager` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.customview` | `customview` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.fragment` | `fragment-ktx` | 1.7.1 | Apache-2.0 | Google Maven |
| `androidx.collection` | `collection-ktx` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.appcompat` | `appcompat-resources` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.vectordrawable` | `vectordrawable` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.vectordrawable` | `vectordrawable-animated` | 1.1.0 | Apache-2.0 | Google Maven |
| `androidx.drawerlayout` | `drawerlayout` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.recyclerview` | `recyclerview` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.legacy` | `legacy-support-core-ui` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.legacy` | `legacy-support-core-utils` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.documentfile` | `documentfile` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.localbroadcastmanager` | `localbroadcastmanager` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.print` | `print` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.coordinatorlayout` | `coordinatorlayout` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.slidingpanelayout` | `slidingpanelayout` | 1.2.0 | Apache-2.0 | Google Maven |
| `androidx.window` | `window` | 1.2.0 | Apache-2.0 | Google Maven |
| `androidx.window.extensions.core` | `core` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.window` | `window-java` | 1.2.0 | Apache-2.0 | Google Maven |
| `androidx.transition` | `transition` | 1.4.1 | Apache-2.0 | Google Maven |
| `androidx.swiperefreshlayout` | `swiperefreshlayout` | 1.0.0 | Apache-2.0 | Google Maven |
| `androidx.asynclayoutinflater` | `asynclayoutinflater` | 1.0.0 | Apache-2.0 | Google Maven |
| `io.flutter` | `flutter_embedding_release` | 1.0.0-692136cb6582dbfc5af3fb33c2515a069f2f66d0 | BSD-3-Clause | Flutter engine Maven repository |
| `com.getkeepsafe.relinker` | `relinker` | 1.4.5 | Apache-2.0 | Maven Central |
| `androidx.exifinterface` | `exifinterface` | 1.4.1 | Apache-2.0 | Google Maven |
| `org.jspecify` | `jspecify` | 1.0.0 | Apache-2.0 | Maven Central |

The `android/` build files themselves declare only `junit:junit:4.13.2`
(`testImplementation`, not shipped). The pinned plugin versions are Android
Gradle Plugin 9.1.0 and Kotlin Gradle plugin 2.4.0 (`android/settings.gradle.kts`).

## Not shipped: dev and build-only tools

### Dart dev dependencies (tests and analysis)

These are in `pubspec.lock` but are not compiled into the app.

| Package | Version | License | Source |
| --- | --- | --- | --- |
| `async` | 2.13.1 | BSD-3-Clause | [pub.dev/packages/async](https://pub.dev/packages/async/versions/2.13.1) |
| `boolean_selector` | 2.1.2 | BSD-3-Clause | [pub.dev/packages/boolean_selector](https://pub.dev/packages/boolean_selector/versions/2.1.2) |
| `fake_async` | 1.3.3 | Apache-2.0 | [pub.dev/packages/fake_async](https://pub.dev/packages/fake_async/versions/1.3.3) |
| `flutter_lints` | 6.0.0 | BSD-3-Clause | [pub.dev/packages/flutter_lints](https://pub.dev/packages/flutter_lints/versions/6.0.0) |
| `flutter_test` | 0.0.0 | BSD-3-Clause | Flutter SDK (`sdk: flutter`) |
| `leak_tracker` | 11.0.2 | BSD-3-Clause | [pub.dev/packages/leak_tracker](https://pub.dev/packages/leak_tracker/versions/11.0.2) |
| `leak_tracker_flutter_testing` | 3.0.10 | BSD-3-Clause | [pub.dev/packages/leak_tracker_flutter_testing](https://pub.dev/packages/leak_tracker_flutter_testing/versions/3.0.10) |
| `leak_tracker_testing` | 3.0.2 | BSD-3-Clause | [pub.dev/packages/leak_tracker_testing](https://pub.dev/packages/leak_tracker_testing/versions/3.0.2) |
| `lints` | 6.1.0 | BSD-3-Clause | [pub.dev/packages/lints](https://pub.dev/packages/lints/versions/6.1.0) |
| `matcher` | 0.12.20 | BSD-3-Clause | [pub.dev/packages/matcher](https://pub.dev/packages/matcher/versions/0.12.20) |
| `source_span` | 1.10.2 | BSD-3-Clause | [pub.dev/packages/source_span](https://pub.dev/packages/source_span/versions/1.10.2) |
| `stack_trace` | 1.12.2 | BSD-3-Clause | [pub.dev/packages/stack_trace](https://pub.dev/packages/stack_trace/versions/1.12.2) |
| `stream_channel` | 2.1.4 | BSD-3-Clause | [pub.dev/packages/stream_channel](https://pub.dev/packages/stream_channel/versions/2.1.4) |
| `string_scanner` | 1.4.1 | BSD-3-Clause | [pub.dev/packages/string_scanner](https://pub.dev/packages/string_scanner/versions/1.4.1) |
| `term_glyph` | 1.2.2 | BSD-3-Clause | [pub.dev/packages/term_glyph](https://pub.dev/packages/term_glyph/versions/1.2.2) |
| `test_api` | 0.7.12 | BSD-3-Clause | [pub.dev/packages/test_api](https://pub.dev/packages/test_api/versions/0.7.12) |
| `vm_service` | 15.3.0 | BSD-3-Clause | [pub.dev/packages/vm_service](https://pub.dev/packages/vm_service/versions/15.3.0) |

Note that Flutter's `NOTICES.Z` in the inspected build also contains notices
for several of these packages (for example `flutter_lints`, `leak_tracker`,
`matcher`), because the Flutter tool collects notices from every package in
the resolved package graph. The in-app list is therefore a superset of what
strictly ships.

### Build toolchain

| Tool | Version | License | Where pinned |
| --- | --- | --- | --- |
| Flutter SDK / Dart SDK | 3.47.6 / 3.13.5 | BSD-3-Clause | `.flutter-version`, `.flutter-sha256` |
| Gradle (wrapper) | 9.3.1 | Apache-2.0 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 9.1.0 | Apache-2.0 | `android/settings.gradle.kts` |
| Kotlin Gradle plugin and compiler | 2.4.0 | Apache-2.0 | `android/settings.gradle.kts` |
| JDK (Eclipse Temurin 21 in Docker; Java 17 bytecode target) | 21 | GPL-2.0-with-classpath-exception | `Dockerfile` |
| Docker base image `eclipse-temurin:21-jdk-noble` (build stage) | digest-pinned | OS packages under their own licenses (Ubuntu 24.04 base, JDK GPL-2.0 with Classpath Exception) | `Dockerfile` |
| Docker base image `nginxinc/nginx-unprivileged:1-alpine` (runtime stage that serves the APK download page, not part of the APK) | digest-pinned | BSD-2-Clause (nginx) plus Alpine packages | `Dockerfile` |
| Lint, security and test tooling (ktlint, detekt, shellcheck, shfmt, markdownlint, yamllint, actionlint, gitleaks, osv-scanner, ruff, mypy, pytest) | see `tool/install_tools.sh`, `tool/requirements-dev.txt` | various OSS licenses | `tool/` |

None of these are linked into or redistributed inside the APK. Their licenses
are listed for completeness; per-tool license verification for the
lint/security tooling is an open point.

## How the app shows licenses to users

The About page (`lib/features/about/presentation/about_page.dart`) shows the
app license ("GNU GPL v3.0 (GPL-3.0-only)") and a button "Open-Source-Lizenzen"
that calls Flutter's `showLicensePage` with the app name, version and the
GPL legalese. Flutter's `LicenseRegistry` is fed from the bundled
`NOTICES.Z`, so the page lists:

- the Flutter framework and engine with their bundled third-party code,
- every Dart package of the resolved package graph (see the note above that
  this includes dev-only packages),
- the app itself (`raumfreund`).

This is complete for Dart packages and the Flutter engine. It is **not
complete** for the native Android libraries: AndroidX, Kotlin stdlib,
kotlinx.coroutines, Okio, JetBrains annotations, Guava `listenablefuture`,
ReLinker and JSpecify do not appear in `NOTICES.Z` (a search of the inspected
build found no match for "androidx", "kotlin", "okio" or "datastore"). The
app does not register any additional `LicenseEntry` for them, and the Apache
License 2.0 requires that recipients receive a copy of the license (section 4a).
Until that is closed, this document is the repository-level notice for those
libraries.

## GPL compatibility

- BSD-3-Clause and the other permissive licenses of the Dart packages and the
  Flutter engine are compatible with GPL-3.0-only.
- Apache-2.0 is compatible with GPLv3 (but not GPLv2-only; the app is GPLv3).
  This covers AndroidX, Kotlin, kotlinx.coroutines, Okio and the other
  Apache-2.0 components.
- The Android build toolchain (JDK under GPL-2.0 with Classpath Exception,
  Gradle, AGP) is not distributed in the APK, so it imposes no
  redistribution obligations on the app.
- No LGPL, GPL-only, AGPL, SSPL, proprietary or non-commercial license was
  found among the packages above. The Android SDK platform (`android.jar`)
  is the compile target and is not shipped. Google Play Services and other
  proprietary Google libraries are not dependencies.
- Not verified: the license of third-party code inside the engine beyond what
  Flutter's own `NOTICES.Z` states, and the transitive Android POM licenses
  noted above.

## Open points

1. Show Android/Kotlin library licenses in the in-app license page, for
   example with a generated `LicenseRegistry.addLicense` entry, or add a
   bundled Apache-2.0 notice listing these libraries.
2. Verify Android artifact licenses from their POM files and automate this
   inventory (for example, a script that diffs this document against
   `pubspec.lock` and `sdkDependencies.txt`) so it cannot go stale.
3. Check that the Material Icons font license text is surfaced in the app
   (it is not in `NOTICES.Z`).
4. Re-run this inventory for every release; `docs/releasing.md` requires a
   license inventory in each production release.
