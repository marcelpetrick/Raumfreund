// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:function_length/function_length.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Map<String, int> _lengths(String source) => <String, int>{
  for (final span in measureSource(source)) span.name: span.lines,
};

void main() {
  _boundaryTests();
  _nestingTests();
  _declarationTests();
  _closureTests();
  _errorTests();
}

void _boundaryTests() {
  group('boundary lengths', () {
    for (final lines in <int>[99, 100, 101]) {
      test('top-level function with $lines lines', () {
        final spans = measureSource(function('f', lines));
        expect(spans, hasLength(1));
        expect(spans.single.lines, lines);
        expect(spans.single.startLine, 1);
        expect(spans.single.endLine, lines);
      });
    }
  });

  test('blank lines and comments inside the body are counted', () {
    const source = 'void f() {\n\n  // a\n\n  /* b\n  c */\n\n}';
    expect(_lengths(source), <String, int>{'f': 8});
  });

  test('annotations and doc comments before the signature are excluded', () {
    const source =
        '/// Doc.\n/// More doc.\n@pragma(\'x\')\n@deprecated\n'
        'void f() {\n  print(1);\n}';
    final span = measureSource(source).single;
    expect(span.startLine, 5);
    expect(span.lines, 3);
  });

  test('multi-line signatures are counted from their first line', () {
    const source =
        'Future<int>\nf(\n  int a,\n  int b,\n) async {\n'
        '  return a + b;\n}';
    expect(_lengths(source), <String, int>{'f': 7});
  });

  test('expression bodies end at the terminating semicolon', () {
    const source = 'int f(int a) =>\n    a +\n    1;';
    expect(_lengths(source), <String, int>{'f': 3});
  });
}

void _nestingTests() {
  group('nested functions', () {
    test('inner 101 inside outer: both are measured', () {
      final source = function('outer', 110, inner: localFunction('inner', 101));
      expect(_lengths(source), <String, int>{'outer': 110, 'outer.inner': 101});
    });

    test('inner 50 inside outer 120: outer counts the inner lines', () {
      final source = function('outer', 120, inner: localFunction('inner', 50));
      expect(_lengths(source), <String, int>{'outer': 120, 'outer.inner': 50});
    });

    test('inner 100 inside outer 100 are both within the limit', () {
      final lines = <String>[
        'void outer() {',
        ...localFunction('inner', 98),
        '}',
      ];
      expect(_lengths(lines.join('\n')), <String, int>{
        'outer': 100,
        'outer.inner': 98,
      });
    });
  });
}

void _declarationTests() {
  test('class members: methods, accessors, constructors', () {
    const source = '''
class A {
  A(this.x) {
    print(x);
  }
  A.named() : x = 1;
  factory A.make() {
    return A(2);
  }
  int x;
  int get double =>
      x * 2;
  set value(int v) {
    x = v;
  }
  void m() {}
  static int s() {
    return 1;
  }
}''';
    expect(_lengths(source), <String, int>{
      'A.new': 3,
      'A.named': 1,
      'A.make': 3,
      'A.get double': 2,
      'A.set value': 3,
      'A.m': 1,
      'A.s': 3,
    });
  });

  test('mixins, enums, extensions and extension types are scopes', () {
    const source = '''
mixin M { void a() {} }
enum E { one; void b() {} }
extension X on int { void c() {} }
extension on String { void d() {} }
extension type T(int v) { void e() {} }
int get top => 1;
set top(int v) {}''';
    expect(_lengths(source).keys, <String>[
      'M.a',
      'E.b',
      'X.c',
      '<extension>.d',
      'T.e',
      'get top',
      'set top',
    ]);
  });
}

void _closureTests() {
  test('closures inside a widget build method are measured', () {
    final callback = <String>[
      '      onPressed: () {',
      ...filler(99, indent: '        '),
      '      },',
    ];
    final source = <String>[
      'class W extends StatelessWidget {',
      '  @override',
      '  Widget build(BuildContext context) {',
      '    return Builder(',
      '      builder: (context) => Text("x"),',
      ...callback,
      '    );',
      '  }',
      '}',
    ].join('\n');
    final spans = measureSource(source);
    expect(spans.map((s) => s.name), <String>[
      'W.build',
      'W.build.<closure>',
      'W.build.<closure>',
    ]);
    expect(spans.map((s) => s.lines), <int>[106, 1, 101]);
    expect(spans.first.startLine, 3);
  });

  test('primary constructor bodies are measured', () {
    const source =
        'class A(final int x) {\n  this : assert(x > 0) {\n'
        '    print(x);\n  }\n}';
    final span = measureSource(source).single;
    expect(span.name, 'A.<primary constructor body>');
    expect(span.startLine, 2);
    expect(span.lines, 3);
  });

  test('closures nested in closures are qualified', () {
    const source = 'void f() {\n  g(() {\n    h((x) => x);\n  });\n}';
    expect(_lengths(source), <String, int>{
      'f': 5,
      'f.<closure>': 3,
      'f.<closure>.<closure>': 1,
    });
  });
}

void _errorTests() {
  test('syntax errors raise ParseFailure with location', () {
    expect(
      () => measureSource('void f() {\n  int x = ;\n}', path: 'a.dart'),
      throwsA(
        isA<ParseFailure>()
            .having((e) => e.line, 'line', 2)
            .having((e) => e.toString(), 'text', startsWith('a.dart:2:')),
      ),
    );
  });
}
