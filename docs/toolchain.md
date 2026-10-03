# Toolchain

Verified on **2026-10-03**. Versions are pinned; updates arrive as reviewed,
green commits (see the weekly maintenance workflow).

## Versions

| Component | Version | Pinned in | Source |
| --- | --- | --- | --- |
| Flutter (stable) | 3.47.6 (released 2026-10-01, framework 5fc3468) | `.flutter-version` | [releases_linux.json](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json), [archive](https://docs.flutter.dev/install/archive) |
| Dart | 3.13.5 (bundled with Flutter 3.47.6) | `pubspec.yaml` `environment.sdk` | same |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle.kts` | Flutter 3.47.6 app template |
| Kotlin Gradle Plugin | 2.4.0 | `android/settings.gradle.kts` | Flutter 3.47.6 app template |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` | Flutter 3.47.6 app template |
| JDK (build) | 21 (Temurin in CI/Docker) | `.github/actions/setup`, `Dockerfile` | AGP 9 requires JDK 17+; 21 is the current LTS supported by Gradle 9.3 |
| Java/Kotlin bytecode target | 17 | `android/app/build.gradle.kts` | Flutter template default |
| compileSdk | 36 | Flutter default (`flutter.compileSdkVersion`) | Flutter 3.47.6 `FlutterExtension.kt` |
| targetSdk | 36 (Android 16) | Flutter default | meets Play requirement "new apps and updates must target API 36 from 2026-08-31" ([target-sdk](https://developer.android.com/google/play/requirements/target-sdk)) |
| minSdk | 24 (Android 7.0) | Flutter default | Flutter 3.47.6 minimum supported Android version |
| NDK | 28.2.13676358 | Flutter default | Flutter 3.47.6 `FlutterExtension.kt` |
| ABIs | arm64-v8a, armeabi-v7a, x86_64 | Flutter release defaults | Flutter Android release builds |

AGP, Kotlin and Gradle are taken exactly from the template that Flutter 3.47.6
generates, because that is the combination the Flutter team tests; newer single
releases of AGP or Kotlin are not adopted ahead of Flutter.

## Why a project-local Flutter SDK

`tool/flutter.sh` downloads the official release archive of the pinned version
into `.toolchain/flutter` (git-ignored) and runs it. A globally installed
Flutter is neither used nor modified, so every checkout, CI job and the Docker
build use the identical SDK. In Docker/CI the SDK can be provided via
`RAUMFREUND_FLUTTER_ROOT` if it has exactly the pinned version.

## Lint profile

`analysis_options.yaml` = `flutter_lints` 6.0.0 + strict language modes
(`strict-casts`, `strict-inference`, `strict-raw-types`) + a curated list of
stricter rules (API docs, trailing commas, futures handling, no dynamic calls,
no empty catches …). Style rules that contradict each other (e.g.
`always_specify_types` vs. `omit_local_variable_types`) are intentionally not
combined. `flutter analyze --fatal-infos --fatal-warnings` must report nothing.

## Fresh checkout (Linux)

```sh
git clone https://github.com/marcelpetrick/Raumfreund.git
cd Raumfreund
./localPipeline.sh            # installs the pinned SDK on first run
```

Requirements: bash, curl, xz, git, a JDK 21 and an Android SDK (platform 36,
build-tools) with `ANDROID_HOME` set or `~/Android/Sdk`. macOS and Windows:
see `docs/building.md`; the Docker image provides a fully reproducible
alternative on every OS.
