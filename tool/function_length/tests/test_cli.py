# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Tests for file collection and the command line of fnlen.py."""

from __future__ import annotations

import os
import runpy
import sys
from pathlib import Path

import pytest

import fnlen
from fixtures import function, source

SUFFIX = {"kotlin": ".kt", "bash": ".sh", "python": ".py"}


def write(path: Path, data: bytes) -> Path:
    """Create ``path`` (and parents) with ``data``."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return path


@pytest.mark.parametrize("language", ["kotlin", "bash", "python"])
def test_100_passes_101_fails(
    language: str, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    write(tmp_path / f"ok{SUFFIX[language]}", source(function(language, "ok", 100)))
    bad = write(tmp_path / f"bad{SUFFIX[language]}", source(function(language, "bad", 101)))
    assert fnlen.main(["--max", "100", str(tmp_path)]) == fnlen.EXIT_VIOLATIONS
    out, err = capsys.readouterr()
    assert out == f"{bad}:1: bad has 101 lines (max 100)\n"
    assert err == ""


def test_clean_tree_and_custom_max(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    path = write(tmp_path / "a.kts", source(function("kotlin", "a", 99)))
    assert fnlen.main([str(tmp_path)]) == fnlen.EXIT_OK
    assert fnlen.main(["--max=98", str(path)]) == fnlen.EXIT_VIOLATIONS
    assert "a has 99 lines (max 98)" in capsys.readouterr().out


def test_excluded_directories_and_unknown_suffixes(tmp_path: Path) -> None:
    long = source(function("bash", "g", 150))
    for directory in fnlen.EXCLUDED_DIRS:
        write(tmp_path / directory / "x.sh", long)
    write(tmp_path / "notes.txt", long)
    kept = write(tmp_path / "sub" / "deeper" / "kept.sh", long)
    (tmp_path / "link").symlink_to(tmp_path / ".git", target_is_directory=True)
    assert fnlen.collect_files([str(tmp_path)]) == [(kept, "bash")]


def test_explicit_files_use_shebang_detection(tmp_path: Path) -> None:
    script = write(tmp_path / "run", b"#!/usr/bin/env bash\n" + source(function("bash", "f", 3)))
    other = write(tmp_path / "data", b"#!/bin/sh\n")
    plain = write(tmp_path / "README", b"text\n")
    found = fnlen.collect_files([str(script), str(other), str(plain), str(script)])
    assert found == [(script, "bash")]


def test_missing_path_exits_2(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert fnlen.main([str(tmp_path / "nope")]) == fnlen.EXIT_USAGE
    assert "no such file or directory" in capsys.readouterr().err


def test_parse_error_exits_2(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    write(tmp_path / "broken.py", b"def f(:\n")
    assert fnlen.main([str(tmp_path)]) == fnlen.EXIT_USAGE
    assert "broken.py:1: parse error" in capsys.readouterr().err


@pytest.mark.skipif(os.geteuid() == 0, reason="root ignores file permissions")
def test_unreadable_file_exits_2(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    path = write(tmp_path / "secret.kt", b"fun f() {}\n")
    path.chmod(0)
    try:
        assert fnlen.main([str(path)]) == fnlen.EXIT_USAGE
    finally:
        path.chmod(0o600)
    assert "secret.kt" in capsys.readouterr().err


@pytest.mark.parametrize("argv", [[], ["--max", "0", "x"], ["--max", "abc", "x"], ["--bogus"]])
def test_usage_errors_exit_2(argv: list[str]) -> None:
    with pytest.raises(SystemExit) as info:
        fnlen.main(argv)
    assert info.value.code == fnlen.EXIT_USAGE


def test_help_exits_0(capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(SystemExit) as info:
        fnlen.main(["--help"])
    assert info.value.code == 0
    assert "Exit codes" in capsys.readouterr().out


def test_module_entry_point(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    write(tmp_path / "ok.sh", source(function("bash", "ok", 5)))
    monkeypatch.setattr(sys, "argv", ["fnlen.py", str(tmp_path)])
    with pytest.raises(SystemExit) as info:
        runpy.run_path(fnlen.__file__, run_name="__main__")
    assert info.value.code == fnlen.EXIT_OK
