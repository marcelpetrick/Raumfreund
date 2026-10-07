#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Keep the third-party license inventory in step with the lockfile.

Purpose: docs/third-party-licenses.md lists every Dart package with its
exact version and license. A dependency update that forgets the inventory
would silently make the published license notice wrong, so this check
compares the document with pubspec.lock and .flutter-version:

  * every package in pubspec.lock has a row with the same version,
  * no row names a package that is no longer locked,
  * no package is listed twice with different versions,
  * the Flutter version in the introduction matches .flutter-version.

Dart rows are table rows whose first cell is a backticked package name and
whose second cell is a version (Android rows name a Maven group and an
artifact instead, so they never match).

Usage:      check_license_inventory.py [--root DIR]
Exit codes: 0 consistent, 1 mismatches found, 2 usage or missing input.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

INVENTORY = Path("docs/third-party-licenses.md")
LOCKFILE = Path("pubspec.lock")
FLUTTER_VERSION = Path(".flutter-version")

_LOCK_PACKAGE = re.compile(r"^  ([A-Za-z0-9_]+):\s*$")
_LOCK_VERSION = re.compile(r'^    version: "?([^"\s]+)"?\s*$')
_DOC_ROW = re.compile(r"^\| `([a-z0-9_]+)` \| ([0-9][^ |]*) \|")
_DOC_FLUTTER = re.compile(r"Flutter `([^`]+)`")


def parse_lock(text: str) -> dict[str, str]:
    """Return ``{package: version}`` of a pubspec.lock file."""
    packages: dict[str, str] = {}
    current: str | None = None
    for line in text.splitlines():
        if package := _LOCK_PACKAGE.match(line):
            current = package.group(1)
        elif (version := _LOCK_VERSION.match(line)) and current is not None:
            packages[current] = version.group(1)
            current = None
    return packages


def parse_inventory(text: str) -> tuple[dict[str, str], list[str]]:
    """Return the Dart rows ``{package: version}`` and duplicate conflicts."""
    rows: dict[str, str] = {}
    problems: list[str] = []
    for line in text.splitlines():
        row = _DOC_ROW.match(line)
        if row is None:
            continue
        name, version = row.groups()
        if rows.get(name, version) != version:
            problems.append(f"{name}: listed as {rows[name]} and {version}")
        rows.setdefault(name, version)
    return rows, problems


def compare(locked: dict[str, str], listed: dict[str, str]) -> list[str]:
    """Describe every difference between the lockfile and the inventory."""
    problems = [f"{name} {locked[name]}: missing" for name in sorted(locked.keys() - listed)]
    problems += [f"{name}: listed but not locked" for name in sorted(listed.keys() - locked)]
    problems += [
        f"{name}: listed as {listed[name]}, locked {locked[name]}"
        for name in sorted(locked.keys() & listed)
        if locked[name] != listed[name]
    ]
    return problems


def check_flutter(text: str, pinned: str) -> list[str]:
    """Check that the inventory names the pinned Flutter version."""
    found = _DOC_FLUTTER.search(text)
    if found is None:
        return ["the Flutter version is not stated"]
    if found.group(1) != pinned:
        return [f"Flutter: listed as {found.group(1)}, pinned {pinned}"]
    return []


def check(root: Path) -> list[str]:
    """Run every consistency check below ``root``."""
    inventory = (root / INVENTORY).read_text(encoding="utf-8")
    locked = parse_lock((root / LOCKFILE).read_text(encoding="utf-8"))
    pinned = (root / FLUTTER_VERSION).read_text(encoding="utf-8").strip()
    listed, problems = parse_inventory(inventory)
    return problems + compare(locked, listed) + check_flutter(inventory, pinned)


def main(argv: list[str] | None = None) -> int:
    """Command line entry point; see the module docstring."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=Path(), help="repository root")
    args = parser.parse_args(argv)
    try:
        problems = check(args.root)
    except OSError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    for problem in problems:
        print(f"{INVENTORY}: {problem}", file=sys.stderr)
    if problems:
        print("Update the inventory together with the dependencies.", file=sys.stderr)
        return 1
    print(f"{INVENTORY}: consistent with {LOCKFILE} and {FLUTTER_VERSION}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
