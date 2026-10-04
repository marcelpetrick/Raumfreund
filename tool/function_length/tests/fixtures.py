# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Generators for fixtures with an exact physical line count.

Fixtures are generated instead of committed so that the repository's own
function-length check never sees intentionally oversized functions.
"""

from __future__ import annotations

from collections.abc import Sequence

COMMENT = {"kotlin": "//", "bash": "#", "python": "#"}
STATEMENT = {"kotlin": "println({i})", "bash": "echo {i}", "python": "x = {i}"}
HEADER = {"kotlin": "fun {name}() {{", "bash": "{name}() {{", "python": "def {name}() -> None:"}
FOOTER = {"kotlin": "}", "bash": "}", "python": None}


def filler(language: str, count: int, indent: str = "    ") -> list[str]:
    """Return ``count`` body lines mixing statements, comments and blanks.

    The last line is always a statement so that Python bodies end on it.
    """
    lines: list[str] = []
    for i in range(count):
        if i == count - 1 or i % 3 == 0:
            lines.append(indent + STATEMENT[language].format(i=i))
        elif i % 3 == 1:
            lines.append(f"{indent}{COMMENT[language]} comment line {i}")
        else:
            lines.append("")
    return lines


def function(
    language: str,
    name: str,
    lines: int,
    inner: Sequence[str] = (),
    indent: str = "",
) -> list[str]:
    """Return a function named ``name`` spanning exactly ``lines`` lines."""
    footer = FOOTER[language]
    body_count = lines - 1 - len(inner) - (0 if footer is None else 1)
    result = [indent + HEADER[language].format(name=name), *inner]
    result += filler(language, body_count, indent + "    ")
    if footer is not None:
        result.append(indent + footer)
    return result


def source(lines: Sequence[str]) -> bytes:
    """Join ``lines`` into source bytes with a trailing newline."""
    return ("\n".join(lines) + "\n").encode()
