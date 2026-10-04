// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Collects the hand-written Dart sources below the given paths.
library;

import 'dart:io';

/// Directory names that never contain hand-written sources.
const Set<String> excludedDirectories = <String>{
  '.dart_tool',
  '.toolchain',
  'build',
  'node_modules',
};

/// Thrown when a command-line path does not exist.
final class MissingPath implements Exception {
  /// Creates the exception for [path].
  const MissingPath(this.path);

  /// The path that does not exist.
  final String path;

  @override
  String toString() => '$path: no such file or directory';
}

/// Whether [path] is generated code that is exempt from the length limit.
///
/// Generated files are exempt per vision section 6: `*.g.dart`,
/// `*.freezed.dart` and everything below `lib/l10n/generated/`.
bool isGenerated(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.endsWith('.g.dart') ||
      normalized.endsWith('.freezed.dart') ||
      normalized.contains('lib/l10n/generated/');
}

/// Returns the sorted list of Dart files to check below [paths].
///
/// Directories are walked recursively, skipping [excludedDirectories];
/// generated files are dropped even when named explicitly.
///
/// Throws [MissingPath] if a path does not exist.
List<String> collectDartFiles(Iterable<String> paths) {
  final found = <String>{};
  for (final path in paths) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      found.add(path);
    } else if (type == FileSystemEntityType.directory) {
      found.addAll(_walk(Directory(path)));
    } else {
      throw MissingPath(path);
    }
  }
  return found
      .where((p) => p.endsWith('.dart'))
      .where((p) => !isGenerated(p))
      .toList()
    ..sort();
}

Iterable<String> _walk(Directory directory) sync* {
  final entries = directory.listSync(followLinks: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entry in entries) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entry is Directory && !excludedDirectories.contains(name)) {
      yield* _walk(entry);
    } else if (entry is File) {
      yield entry.path;
    }
  }
}
