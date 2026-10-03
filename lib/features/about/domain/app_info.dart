// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Build and version information shown on the About page.
final class AppInfo {
  /// Creates the info.
  const AppInfo({
    required this.versionName,
    required this.buildNumber,
    required this.gitCommit,
  });

  /// SemVer version, e.g. "0.4.2".
  final String versionName;

  /// Android versionCode.
  final int buildNumber;

  /// Short commit hash of the build, or "unknown".
  final String gitCommit;
}

/// Source of [AppInfo].
abstract interface class AppInfoPort {
  /// Loads the information of the running app.
  Future<AppInfo> load();
}
