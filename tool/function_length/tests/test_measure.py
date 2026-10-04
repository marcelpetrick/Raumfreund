# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Tests for the per-language measurement functions of fnlen.py."""

from __future__ import annotations

import pytest
import tree_sitter_bash

import fnlen
from fixtures import filler, function, source

LANGUAGES = ("kotlin", "bash", "python")


def lengths(language: str, data: bytes) -> dict[str, int]:
    """Map qualified names to line counts for ``data``."""
    return {s.name: s.lines for s in fnlen.MEASURERS[language](data, "<test>")}


@pytest.mark.parametrize("language", LANGUAGES)
@pytest.mark.parametrize("lines", [99, 100, 101])
def test_boundary_lengths(language: str, lines: int) -> None:
    spans = fnlen.MEASURERS[language](source(function(language, "f", lines)), "<test>")
    assert [(s.name, s.start, s.end, s.lines) for s in spans] == [("f", 1, lines, lines)]


@pytest.mark.parametrize("language", LANGUAGES)
def test_inner_101_inside_outer(language: str) -> None:
    inner = function(language, "inner", 101, indent="    ")
    data = source(function(language, "outer", 110, inner=inner))
    assert lengths(language, data) == {"outer": 110, "outer.inner": 101}


@pytest.mark.parametrize("language", LANGUAGES)
def test_inner_50_inside_outer_120(language: str) -> None:
    inner = function(language, "inner", 50, indent="    ")
    data = source(function(language, "outer", 120, inner=inner))
    assert lengths(language, data) == {"outer": 120, "outer.inner": 50}


@pytest.mark.parametrize("language", LANGUAGES)
def test_comments_and_blank_lines_are_counted(language: str) -> None:
    body = filler(language, 7)
    assert body.count("") == 2
    data = source(function(language, "f", 9))
    assert lengths(language, data) == {"f": 9}


KOTLIN = b"""/** KDoc is not part of the signature. */
class A(val x: Int) : B() {
    /** KDoc */
    @Suppress("x")
    @JvmStatic
    override fun g(): Int {
        return 1
    }
    var p = 1
        @Deprecated("y") set(v) {
            field = v
        }
    val q: Int
        get() {
            return 2
        }
    companion object {
        fun h() {}
    }
    init {
        println(x)
    }
    constructor(y: String) : this(1) {
        println(y)
    }
}
object O {
    fun z() {
        listOf(1).forEach {
            println(it)
        }
    }
}
fun <T> T.ext() = fun(a: Int) {
}
"""


def test_kotlin_constructs() -> None:
    spans = fnlen.measure_kotlin(KOTLIN)
    assert [(s.name, s.start, s.lines) for s in spans] == [
        ("A.g", 6, 3),
        ("A.set p", 10, 3),
        ("A.get q", 14, 3),
        ("A.Companion.h", 18, 1),
        ("A.<init>", 20, 3),
        ("A.<constructor>", 23, 3),
        ("O.z", 28, 5),
        ("O.z.<lambda>", 29, 3),
        ("ext", 34, 2),
        ("ext.<anonymous>", 34, 2),
    ]


def test_kotlin_annotation_only_modifiers_and_local_functions() -> None:
    data = b"@Composable\nfun screen() {\n    fun local() = 1\n}\n"
    spans = fnlen.measure_kotlin(data)
    assert [(s.name, s.start, s.lines) for s in spans] == [
        ("screen", 2, 3),
        ("screen.local", 3, 1),
    ]


def test_bash_function_forms() -> None:
    data = b"#!/bin/bash\nfoo() {\n\t:\n}\nfunction bar {\n\tinner() { :; }\n}\nbaz() (\n\t:\n)\n"
    assert lengths("bash", data) == {"foo": 3, "bar": 3, "bar.inner": 1, "baz": 3}


def test_python_constructs() -> None:
    data = b"""@decorator
@other
def f() -> None:
    pass


class C:
    async def m(self) -> None:
        g = lambda: (
            1
        )
"""
    spans = fnlen.measure_python(data)
    assert [(s.name, s.start, s.lines) for s in spans] == [
        ("f", 3, 2),
        ("C.m", 8, 4),
        ("C.m.<lambda>", 9, 3),
    ]


@pytest.mark.parametrize(
    ("language", "data", "line"),
    [
        ("kotlin", b"fun f() {\n    val x = \n}\n", 2),
        # tree-sitter wraps the broken function in one ERROR node.
        ("kotlin", b"fun f() {\n    g(\n", 1),
        ("bash", b"f() {\n  echo\n", 1),
        ("python", b"def f():\n    x = (\n", 2),
    ],
)
def test_parse_errors(language: str, data: bytes, line: int) -> None:
    with pytest.raises(fnlen.ParseError) as info:
        fnlen.MEASURERS[language](data, "bad.src")
    assert info.value.line == line
    assert str(info.value).startswith(f"bad.src:{line}: parse error: ")


def test_defensive_fallbacks_on_degenerate_nodes() -> None:
    _owned_language, _parser, tree = fnlen._parse_tree_sitter(
        tree_sitter_bash.language(), b"\n\nf() { :; }\n", "x"
    )
    root = tree.root_node
    leaf = root.named_children[0].child_by_field_name("name")
    assert leaf is not None
    assert fnlen._signature_start(leaf) == 2
    assert fnlen._first_error(root) == root
    assert fnlen._property_name(root, b"\n\nf() { :; }\n", "get") == "get"


def test_large_tree_remains_owned_during_node_traversal() -> None:
    functions = [f"f{i}() {{\n  printf '%s\\n' {i}\n}}" for i in range(200)]
    data = ("\n".join(functions) + "\n").encode()
    spans = fnlen.measure_bash(data)
    assert len(spans) == 200
    assert spans[-1].name == "f199"
