// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:io';

import 'package:function_length/function_length.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

final class _Run {
  _Run(List<String> args) {
    code = run(args, out, err);
  }

  final StringBuffer out = StringBuffer();
  final StringBuffer err = StringBuffer();
  late final int code;
}

/// Temporary directory per test with a helper to create files in it.
final class _Sandbox {
  late Directory dir;

  void create() => dir = Directory.systemTemp.createTempSync('fnlen_dart_');

  void delete() => dir.deleteSync(recursive: true);

  String write(String relative, String content) {
    final file = File('${dir.path}/$relative')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
    return file.path;
  }
}

void main() {
  final box = _Sandbox();
  setUp(box.create);
  tearDown(box.delete);
  group('reporting', () => _reportingTests(box));
  group('errors', () => _errorTests(box));
  _usageTests();
}

void _reportingTests(_Sandbox box) {
  test('100 lines pass, 101 lines fail with the documented format', () {
    box.write('ok.dart', function('ok', 100));
    final bad = box.write('bad.dart', function('bad', 101));
    final result = _Run(<String>['--max', '100', box.dir.path]);
    expect(result.code, exitViolations);
    expect(result.out.toString(), '$bad:1: bad has 101 lines (max 100)\n');
    expect(result.err.toString(), isEmpty);
  });

  test('clean tree exits 0 and --max=N is honoured', () {
    final path = box.write('a.dart', function('a', 99));
    expect(_Run(<String>[path]).code, exitOk);
    final strict = _Run(<String>['--max=98', path]);
    expect(strict.code, exitViolations);
    expect(strict.out.toString(), contains('a has 99 lines (max 98)'));
  });

  test('generated files and excluded directories are skipped', () {
    final long = function('g', 150);
    box.write('x.g.dart', long);
    box.write('x.freezed.dart', long);
    box.write('lib/l10n/generated/app_localizations.dart', long);
    for (final dir in excludedDirectories) {
      box.write('$dir/y.dart', long);
    }
    box.write('notes.txt', long);
    expect(_Run(<String>[box.dir.path]).code, exitOk);
  });

  test('explicitly named generated file is still skipped', () {
    final path = box.write('z.g.dart', function('g', 150));
    expect(_Run(<String>[path]).code, exitOk);
  });
}

void _errorTests(_Sandbox box) {
  test('parse errors exit 2', () {
    box.write('broken.dart', 'void f( {');
    final result = _Run(<String>[box.dir.path]);
    expect(result.code, exitUsage);
    expect(result.err.toString(), contains('parse error'));
  });

  test('missing path exits 2', () {
    final result = _Run(<String>['${box.dir.path}/nope']);
    expect(result.code, exitUsage);
    expect(result.err.toString(), contains('no such file or directory'));
  });

  test('unreadable file exits 2', () {
    final path = box.write('latin1.dart', '');
    File(path).writeAsBytesSync(<int>[0xff, 0xfe, 0x00]);
    final result = _Run(<String>[path]);
    expect(result.code, exitUsage);
    expect(result.err.toString(), contains('latin1.dart'));
  });
}

void _usageTests() {
  group('usage errors', () {
    for (final args in <List<String>>[
      <String>[],
      <String>['--max'],
      <String>['--max', '0', 'x'],
      <String>['--max=abc', 'x'],
      <String>['--bogus', 'x'],
    ]) {
      test('$args exits 2', () {
        final result = _Run(args);
        expect(result.code, exitUsage);
        expect(result.err.toString(), contains('Usage:'));
      });
    }
  });

  test('--help prints usage and exits 0', () {
    final result = _Run(<String>['--help']);
    expect(result.code, exitOk);
    expect(result.out.toString(), contains('Exit codes'));
  });
}
