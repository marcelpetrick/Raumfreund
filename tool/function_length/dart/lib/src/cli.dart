// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Command-line front end of the Dart function-length checker.
library;

import 'dart:io';

import 'files.dart';
import 'measure.dart';

/// Exit code when every function is within the limit.
const int exitOk = 0;

/// Exit code when at least one function exceeds the limit.
const int exitViolations = 1;

/// Exit code for usage errors, missing paths and parse errors.
const int exitUsage = 2;

/// Usage text printed for `--help` and on usage errors.
const String usage = '''
Usage: dart run bin/check.dart [--max N] <path>...

Reports every Dart function, method, constructor, getter, setter, local
function and closure longer than N physical lines (default 100).

Exit codes: 0 = ok, 1 = violations found, 2 = usage or parse error.''';

/// Parsed command-line options.
final class Options {
  /// Creates options with the line [max] and the [paths] to check.
  const Options(this.max, this.paths);

  /// Maximum allowed physical lines per function.
  final int max;

  /// Files or directories to check.
  final List<String> paths;
}

/// Thrown for invalid command-line arguments.
final class UsageError implements Exception {
  /// Creates the error with a human-readable [message].
  const UsageError(this.message);

  /// Description of the problem.
  final String message;
}

/// Parses [args]; returns `null` when help was requested.
Options? parseArgs(List<String> args) {
  var max = 100;
  final paths = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      return null;
    } else if (arg == '--max' || arg.startsWith('--max=')) {
      final value = arg == '--max'
          ? (++i < args.length ? args[i] : '')
          : arg.substring('--max='.length);
      max = _parseMax(value);
    } else if (arg.startsWith('-')) {
      throw UsageError('unknown option: $arg');
    } else {
      paths.add(arg);
    }
  }
  if (paths.isEmpty) {
    throw const UsageError('no paths given');
  }
  return Options(max, paths);
}

int _parseMax(String value) {
  final max = int.tryParse(value);
  if (max == null || max < 1) {
    throw UsageError('--max needs a positive integer, got "$value"');
  }
  return max;
}

/// Runs the checker and returns the process exit code.
int run(List<String> args, StringSink out, StringSink err) {
  final Options? options;
  try {
    options = parseArgs(args);
  } on UsageError catch (e) {
    err.writeln('error: ${e.message}\n\n$usage');
    return exitUsage;
  }
  if (options == null) {
    out.writeln(usage);
    return exitOk;
  }
  try {
    return _check(options, out);
  } on MissingPath catch (e) {
    err.writeln('error: $e');
  } on ParseFailure catch (e) {
    err.writeln('error: $e');
  } on FileSystemException catch (e) {
    err.writeln('error: ${e.path}: ${e.message}');
  }
  return exitUsage;
}

int _check(Options options, StringSink out) {
  var violations = 0;
  for (final path in collectDartFiles(options.paths)) {
    final content = File(path).readAsStringSync();
    for (final span in measureSource(content, path: path)) {
      if (span.lines > options.max) {
        violations++;
        out.writeln(
          '$path:${span.startLine}: ${span.name} has ${span.lines} lines '
          '(max ${options.max})',
        );
      }
    }
  }
  return violations == 0 ? exitOk : exitViolations;
}
