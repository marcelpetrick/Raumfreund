#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Parser-based function-length checker for Kotlin, Bash and Python.

Purpose: enforce the 100-physical-line limit (vision section 6, AGENTS.md
section 5) for every hand-written function. Kotlin and Bash are parsed with
tree-sitter grammars, Python with the standard library ``ast`` module; no
regular expressions are involved.

Measured constructs:
  Kotlin  fun declarations (incl. local), lambdas, anonymous functions,
          init blocks, secondary constructors, property getters/setters.
  Bash    function definitions (both ``f() {}`` and ``function f {}``).
  Python  def / async def (incl. nested) and lambdas.

A span runs from the first line of the signature (annotations, decorators
and doc comments before it are excluded) to the closing brace inclusive, so
blank lines and comments count. Python has no closing brace; its span ends
on the last line of the body. Nested functions are reported on their own
and also count towards every enclosing function.

Usage:      fnlen.py [--max N] <path>...
Exit codes: 0 ok, 1 violations found, 2 usage, missing path or parse error.
"""

from __future__ import annotations

import argparse
import ast
import sys
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import override

import tree_sitter_bash
import tree_sitter_kotlin
from tree_sitter import Language, Node, Parser, Tree

EXIT_OK = 0
EXIT_VIOLATIONS = 1
EXIT_USAGE = 2

EXCLUDED_DIRS = frozenset(
    {
        ".dart_tool",
        ".git",
        ".gradle",
        ".mypy_cache",
        ".pytest_cache",
        ".ruff_cache",
        ".toolchain",
        ".venv",
        "__pycache__",
        "build",
        "node_modules",
    }
)
SUFFIXES = {".kt": "kotlin", ".kts": "kotlin", ".sh": "bash", ".py": "python"}
COMMENT_TYPES = frozenset({"comment", "line_comment", "block_comment"})


@dataclass(frozen=True)
class Span:
    """A measured function-like construct (1-based, inclusive lines)."""

    name: str
    start: int
    end: int

    @property
    def lines(self) -> int:
        """Number of physical lines, both ends inclusive."""
        return self.end - self.start + 1


class ParseError(Exception):
    """Raised when a file cannot be parsed without syntax errors."""

    def __init__(self, path: str, line: int, message: str) -> None:
        """Store the location and message of the first syntax error."""
        super().__init__(f"{path}:{line}: parse error: {message}")
        self.path = path
        self.line = line


class MissingPathError(Exception):
    """Raised when a command-line path does not exist."""


# --- tree-sitter (Kotlin, Bash) ------------------------------------------

Namer = Callable[[Node, bytes], str]


def _text(node: Node | None, source: bytes, default: str) -> str:
    if node is None:
        return default
    return source[node.start_byte : node.end_byte].decode("utf-8", errors="replace")


def _field_name(node: Node, source: bytes, default: str) -> str:
    return _text(node.child_by_field_name("name"), source, default)


def _property_name(accessor: Node, source: bytes, prefix: str) -> str:
    prop = accessor.parent
    if prop is not None:
        for child in prop.named_children:
            if child.type == "variable_declaration":
                identifier = next((c for c in child.named_children if c.type == "identifier"), None)
                return f"{prefix} {_text(identifier, source, '?')}"
    return prefix


KOTLIN_FUNCTIONS: dict[str, Namer] = {
    "function_declaration": lambda n, s: _field_name(n, s, "<fun>"),
    "lambda_literal": lambda _n, _s: "<lambda>",
    "anonymous_function": lambda _n, _s: "<anonymous>",
    "anonymous_initializer": lambda _n, _s: "<init>",
    "secondary_constructor": lambda _n, _s: "<constructor>",
    "getter": lambda n, s: _property_name(n, s, "get"),
    "setter": lambda n, s: _property_name(n, s, "set"),
}
KOTLIN_SCOPES: dict[str, Namer] = {
    "class_declaration": lambda n, s: _field_name(n, s, "<class>"),
    "object_declaration": lambda n, s: _field_name(n, s, "<object>"),
    "companion_object": lambda n, s: _field_name(n, s, "Companion"),
}
BASH_FUNCTIONS: dict[str, Namer] = {
    "function_definition": lambda n, s: _field_name(n, s, "<function>"),
}


def _signature_start(node: Node) -> int:
    """Return the 0-based row of the first non-annotation, non-comment token."""
    for child in node.children:
        if child.type == "modifiers":
            for modifier in child.children:
                if modifier.type != "annotation" and modifier.type not in COMMENT_TYPES:
                    return modifier.start_point.row
        elif child.type != "annotation" and child.type not in COMMENT_TYPES:
            return child.start_point.row
    return node.start_point.row


def _first_error(node: Node) -> Node:
    """Return the first ERROR or MISSING node below a tree with errors."""
    stack = [node]
    while stack:
        current = stack.pop()
        if current.is_error or current.is_missing:
            return current
        stack.extend(reversed(current.children))
    return node


def _tree_sitter_spans(
    root: Node,
    source: bytes,
    functions: dict[str, Namer],
    scopes: dict[str, Namer],
) -> list[Span]:
    spans: list[Span] = []

    def visit(node: Node, scope: tuple[str, ...]) -> None:
        if node.type in functions:
            name = functions[node.type](node, source)
            qualified = ".".join((*scope, name))
            start = _signature_start(node) + 1
            spans.append(Span(qualified, start, node.end_point.row + 1))
            scope = (*scope, name)
        elif node.type in scopes:
            scope = (*scope, scopes[node.type](node, source))
        for child in node.named_children:
            visit(child, scope)

    visit(root, ())
    return spans


def _parse_tree_sitter(language: object, source: bytes, path: str) -> tuple[Language, Parser, Tree]:
    """Parse source and retain the owning tree for every node traversal.

    The Python bindings expose nodes backed by native tree memory. Returning
    only ``root_node`` allowed the temporary ``Tree`` to be collected first,
    which could segfault while traversing larger real-world shell scripts.
    """
    owned_language = Language(language)
    parser = Parser(owned_language)
    tree = parser.parse(source)
    if tree.root_node.has_error:
        error = _first_error(tree.root_node)
        kind = "missing" if error.is_missing else "unexpected"
        raise ParseError(path, error.start_point.row + 1, f"{kind} {error.type}")
    return owned_language, parser, tree


def measure_kotlin(source: bytes, path: str = "<memory>") -> list[Span]:
    """Measure Kotlin source with the tree-sitter-kotlin grammar."""
    _owned_language, _parser, tree = _parse_tree_sitter(tree_sitter_kotlin.language(), source, path)
    return _tree_sitter_spans(tree.root_node, source, KOTLIN_FUNCTIONS, KOTLIN_SCOPES)


def measure_bash(source: bytes, path: str = "<memory>") -> list[Span]:
    """Measure Bash source with the tree-sitter-bash grammar."""
    _owned_language, _parser, tree = _parse_tree_sitter(tree_sitter_bash.language(), source, path)
    return _tree_sitter_spans(tree.root_node, source, BASH_FUNCTIONS, {})


# --- Python (stdlib ast) --------------------------------------------------


class _PythonVisitor(ast.NodeVisitor):
    def __init__(self) -> None:
        self.spans: list[Span] = []
        self._scope: list[str] = []

    def _record(self, name: str, node: ast.expr | ast.stmt) -> None:
        end = node.end_lineno if node.end_lineno is not None else node.lineno
        self.spans.append(Span(".".join([*self._scope, name]), node.lineno, end))
        self._scope.append(name)
        self.generic_visit(node)
        self._scope.pop()

    @override
    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self._record(node.name, node)

    @override
    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self._record(node.name, node)

    @override
    def visit_Lambda(self, node: ast.Lambda) -> None:
        self._record("<lambda>", node)

    @override
    def visit_ClassDef(self, node: ast.ClassDef) -> None:
        self._scope.append(node.name)
        self.generic_visit(node)
        self._scope.pop()


def measure_python(source: bytes, path: str = "<memory>") -> list[Span]:
    """Measure Python source with the standard library ``ast`` module."""
    try:
        tree = ast.parse(source, filename=path)
    except SyntaxError as error:
        raise ParseError(path, error.lineno or 1, error.msg) from error
    visitor = _PythonVisitor()
    visitor.visit(tree)
    return visitor.spans


MEASURERS: dict[str, Callable[[bytes, str], list[Span]]] = {
    "kotlin": measure_kotlin,
    "bash": measure_bash,
    "python": measure_python,
}


# --- files and command line -----------------------------------------------


def language_of(path: Path, *, explicit: bool = False) -> str | None:
    """Return the language of ``path`` by suffix (or bash shebang if explicit)."""
    language = SUFFIXES.get(path.suffix)
    if language is None and explicit:
        with path.open("rb") as handle:
            first = handle.readline()
        if first.startswith(b"#!") and b"bash" in first:
            return "bash"
    return language


def _walk(directory: Path) -> Iterator[Path]:
    for entry in sorted(directory.iterdir()):
        if entry.is_dir() and not entry.is_symlink():
            if entry.name not in EXCLUDED_DIRS:
                yield from _walk(entry)
        elif entry.is_file() and language_of(entry) is not None:
            yield entry


def collect_files(paths: Sequence[str]) -> list[tuple[Path, str]]:
    """Return ``(file, language)`` pairs below ``paths``, sorted and unique."""
    found: dict[Path, str] = {}
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            found.update((f, SUFFIXES[f.suffix]) for f in _walk(path))
        elif path.is_file():
            language = language_of(path, explicit=True)
            if language is not None:
                found[path] = language
        else:
            raise MissingPathError(f"{raw}: no such file or directory")
    return sorted(found.items())


def _positive_int(value: str) -> int:
    try:
        number = int(value)
    except ValueError:
        number = 0
    if number < 1:
        message = f"needs a positive integer, got {value!r}"
        raise argparse.ArgumentTypeError(message)
    return number


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="fnlen.py",
        description="Report Kotlin, Bash and Python functions longer than N lines.",
        epilog="Exit codes: 0 = ok, 1 = violations found, 2 = usage or parse error.",
    )
    parser.add_argument("--max", type=_positive_int, default=100, metavar="N")
    parser.add_argument("paths", nargs="+", metavar="path")
    return parser


def check(paths: Sequence[str], maximum: int) -> list[str]:
    """Return one report line per function longer than ``maximum`` lines."""
    report: list[str] = []
    for path, language in collect_files(paths):
        for span in MEASURERS[language](path.read_bytes(), str(path)):
            if span.lines > maximum:
                report.append(
                    f"{path}:{span.start}: {span.name} has {span.lines} lines (max {maximum})"
                )
    return report


def main(argv: Sequence[str] | None = None) -> int:
    """Run the checker and return the process exit code."""
    args = _parser().parse_args(argv)
    try:
        report = check(args.paths, args.max)
    except (MissingPathError, ParseError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return EXIT_USAGE
    for line in report:
        print(line)
    return EXIT_VIOLATIONS if report else EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
