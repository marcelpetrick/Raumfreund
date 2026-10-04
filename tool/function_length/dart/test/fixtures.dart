// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Generators for Dart fixtures with an exact physical line count.
///
/// Fixtures are generated instead of committed so that the repository's own
/// function-length check never sees intentionally oversized functions.
library;

/// Body filler of [count] lines mixing statements, comments and blanks.
List<String> filler(int count, {String indent = '  '}) =>
    List<String>.generate(count, (i) {
      switch (i % 3) {
        case 0:
          return '${indent}print($i);';
        case 1:
          return '$indent// comment line $i';
        default:
          return '';
      }
    });

/// A top-level function named [name] spanning exactly [lines] lines.
String function(String name, int lines, {List<String> inner = const []}) {
  final body = filler(lines - 2 - inner.length);
  return <String>['void $name() {', ...inner, ...body, '}'].join('\n');
}

/// A local function named [name] spanning exactly [lines] lines.
List<String> localFunction(String name, int lines) => <String>[
  '  void $name() {',
  ...filler(lines - 2, indent: '    '),
  '  }',
];
