# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Tests for check_license_inventory.py."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

import pytest

import check_license_inventory as inventory

LOCK = """packages:
  clock:
    dependency: transitive
    description:
      name: clock
      url: "https://pub.dev"
    source: hosted
    version: "1.1.3"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
sdks:
  dart: ">=3.13.0 <4.0.0"
"""

DOC = """# Third-party licenses

Raumfreund (Flutter `3.47.6`, Dart `3.13.5`).

| Package | Version | License |
| --- | --- | --- |
| `flutter` | 0.0.0 | BSD-3-Clause |
| `clock` | 1.1.3 | Apache-2.0 |

| Group | Artifact | Version |
| --- | --- | --- |
| `io.flutter` | `flutter_embedding_release` | 1.0.0 |
"""


def repo(tmp_path: Path, doc: str = DOC, lock: str = LOCK, flutter: str = "3.47.6\n") -> Path:
    """Create a minimal repository with the three inputs."""
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs/third-party-licenses.md").write_text(doc, encoding="utf-8")
    (tmp_path / "pubspec.lock").write_text(lock, encoding="utf-8")
    (tmp_path / ".flutter-version").write_text(flutter, encoding="utf-8")
    return tmp_path


def test_parse_lock_reads_every_package() -> None:
    assert inventory.parse_lock(LOCK) == {"clock": "1.1.3", "flutter": "0.0.0"}


def test_parse_inventory_ignores_android_rows() -> None:
    rows, problems = inventory.parse_inventory(DOC)
    assert rows == {"flutter": "0.0.0", "clock": "1.1.3"}
    assert problems == []


def test_parse_inventory_reports_conflicting_duplicates() -> None:
    doc = DOC + "| `clock` | 1.1.2 | Apache-2.0 |\n| `flutter` | 0.0.0 | BSD |\n"
    _, problems = inventory.parse_inventory(doc)
    assert problems == ["clock: listed as 1.1.3 and 1.1.2"]


def test_consistent_repository_passes(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert inventory.main(["--root", str(repo(tmp_path))]) == 0
    assert "consistent" in capsys.readouterr().out


def test_reports_missing_stale_and_changed_packages(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    lock = LOCK.replace('"1.1.3"', '"1.2.0"') + '  intl:\n    version: "0.20.3"\n'
    doc = DOC + "| `gone` | 1.0.0 | MIT |\n"
    assert inventory.main(["--root", str(repo(tmp_path, doc=doc, lock=lock))]) == 1
    err = capsys.readouterr().err
    assert "intl 0.20.3: missing" in err
    assert "gone: listed but not locked" in err
    assert "clock: listed as 1.1.3, locked 1.2.0" in err


def test_reports_wrong_or_missing_flutter_version(tmp_path: Path) -> None:
    root = repo(tmp_path, flutter="3.48.0\n")
    assert inventory.check(root) == ["Flutter: listed as 3.47.6, pinned 3.48.0"]
    assert inventory.check_flutter("no version here", "3.47.6") == [
        "the Flutter version is not stated"
    ]


def test_missing_input_is_a_usage_error(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert inventory.main(["--root", str(tmp_path)]) == 2
    assert "error:" in capsys.readouterr().err


def test_runs_as_a_script(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(sys, "argv", ["check_license_inventory.py", "--root", str(repo(tmp_path))])
    with pytest.raises(SystemExit) as exit_info:
        runpy.run_path(inventory.__file__, run_name="__main__")
    assert exit_info.value.code == 0


def test_real_repository_is_consistent() -> None:
    root = Path(__file__).resolve().parents[3]
    assert inventory.check(root) == []
