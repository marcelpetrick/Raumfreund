// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Measures the physical line length of every function-like Dart declaration
/// using the analyzer AST (no regular expressions).
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// One measured function-like declaration.
final class FunctionSpan {
  /// Creates a span for [name] covering [startLine]..[endLine] (1-based).
  const FunctionSpan(this.name, this.startLine, this.endLine);

  /// Qualified, human-readable name such as `Foo.build.<closure>`.
  final String name;

  /// First line of the signature (annotations and doc comments excluded).
  final int startLine;

  /// Line of the closing brace (or terminating token for `=>` bodies).
  final int endLine;

  /// Number of physical lines, both ends inclusive.
  int get lines => endLine - startLine + 1;
}

/// Thrown when a source file cannot be parsed without diagnostics.
final class ParseFailure implements Exception {
  /// Creates a failure for [path] at [line] with the parser [message].
  const ParseFailure(this.path, this.line, this.message);

  /// File that failed to parse.
  final String path;

  /// 1-based line of the first diagnostic.
  final int line;

  /// Parser diagnostic message.
  final String message;

  @override
  String toString() => '$path:$line: parse error: $message';
}

/// Parses [content] and returns every function-like span it contains.
///
/// Nested functions are reported individually; their lines also count
/// towards every enclosing function because spans are physical ranges.
List<FunctionSpan> measureSource(String content, {String path = '<memory>'}) {
  final result = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  );
  if (result.errors.isNotEmpty) {
    final first = result.errors.first;
    final line = result.lineInfo.getLocation(first.offset).lineNumber;
    throw ParseFailure(path, line, first.message);
  }
  final visitor = _SpanVisitor(result.lineInfo);
  result.unit.accept(visitor);
  return visitor.spans;
}

final class _SpanVisitor extends RecursiveAstVisitor<void> {
  _SpanVisitor(this._lineInfo);

  final LineInfo _lineInfo;
  final List<String> _scope = <String>[];
  final List<FunctionSpan> spans = <FunctionSpan>[];

  int _line(Token token) => _lineInfo.getLocation(token.offset).lineNumber;

  String _qualify(String name) => <String>[..._scope, name].join('.');

  void _record(String name, Token begin, Token end, void Function() visit) {
    final qualified = _qualify(name);
    spans.add(FunctionSpan(qualified, _line(begin), _line(end)));
    _scope.add(name);
    visit();
    _scope.removeLast();
  }

  void _inScope(String name, void Function() visit) {
    _scope.add(name);
    visit();
    _scope.removeLast();
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) => _inScope(
    node.namePart.typeName.lexeme,
    () => super.visitClassDeclaration(node),
  );

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _inScope(node.name.lexeme, () => super.visitMixinDeclaration(node));

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _inScope(
    node.namePart.typeName.lexeme,
    () => super.visitEnumDeclaration(node),
  );

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) => _inScope(
    node.name?.lexeme ?? '<extension>',
    () => super.visitExtensionDeclaration(node),
  );

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) => _inScope(
    node.namePart.typeName.lexeme,
    () => super.visitExtensionTypeDeclaration(node),
  );

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _record(
    _accessorName(node.name.lexeme, node.isGetter, node.isSetter),
    node.firstTokenAfterCommentAndMetadata,
    node.endToken,
    // Visit the children of the FunctionExpression directly so that the
    // declaration itself is not reported a second time as a closure.
    () => node.functionExpression.visitChildren(this),
  );

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _record(
    _accessorName(node.name.lexeme, node.isGetter, node.isSetter),
    node.firstTokenAfterCommentAndMetadata,
    node.endToken,
    () => super.visitMethodDeclaration(node),
  );

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) => _record(
    node.name?.lexeme ?? 'new',
    node.firstTokenAfterCommentAndMetadata,
    node.endToken,
    () => super.visitConstructorDeclaration(node),
  );

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) => _record(
    '<primary constructor body>',
    node.firstTokenAfterCommentAndMetadata,
    node.endToken,
    () => super.visitPrimaryConstructorBody(node),
  );

  @override
  void visitFunctionExpression(FunctionExpression node) => _record(
    '<closure>',
    node.beginToken,
    node.endToken,
    () => super.visitFunctionExpression(node),
  );
}

String _accessorName(String name, bool isGetter, bool isSetter) {
  if (isGetter) {
    return 'get $name';
  }
  if (isSetter) {
    return 'set $name';
  }
  return name;
}
