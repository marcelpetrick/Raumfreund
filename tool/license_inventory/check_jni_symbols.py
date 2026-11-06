#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Verify JNI symbols used by Android preferences in a minified release APK.

Usage: python3 tool/license_inventory/check_jni_symbols.py <apk> <dexdump>
Exit codes: 0 symbols present; 1 missing symbols; 2 invalid input or dump error.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

# These are looked up by literal name in jni's Kotlin bridge. The registrar
# uses a literal method descriptor for each suspend call.
CLASSES = (
    "Lkotlin/Unit;",
    "Lkotlin/Result;",
    "Lkotlin/Result$Failure;",
    "Lkotlin/coroutines/Continuation;",
    "Lkotlin/coroutines/intrinsics/CoroutineSingletons;",
    "Lkotlin/coroutines/intrinsics/IntrinsicsKt;",
)
REGISTRAR = "Lio/flutter/plugins/sharedpreferences/SharedPreferencesApiRegistrar;"
FLUTTER_ERROR = "Lio/flutter/plugins/sharedpreferences/FlutterError;"
INTRINSICS = "Lkotlin/coroutines/intrinsics/IntrinsicsKt;"
MEMBERS = {
    "Lkotlin/Unit;": {("INSTANCE", "Lkotlin/Unit;")},
    "Lkotlin/Result;": {("value", "Ljava/lang/Object;")},
    "Lkotlin/Result$Failure;": {
        ("exception", "Ljava/lang/Throwable;"),
        ("<init>", "(Ljava/lang/Throwable;)V"),
    },
    "Lkotlin/coroutines/Continuation;": {("resumeWith", "(Ljava/lang/Object;)V")},
    FLUTTER_ERROR: {
        ("getCode", "()Ljava/lang/String;"),
        ("getMessage", "()Ljava/lang/String;"),
        ("getDetails", "()Ljava/lang/Object;"),
    },
    REGISTRAR: {
        ("<init>", "()V"),
        (
            "getInstance",
            "(Ljava/lang/String;)Lio/flutter/plugins/sharedpreferences/SharedPreferencesApiRegistrar;",
        ),
        (
            "setString",
            "(Ljava/lang/String;Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;",
        ),
        (
            "getAll",
            "(Ljava/lang/String;Ljava/util/List;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;",
        ),
    },
}


def missing_symbols(dump: str) -> list[str]:
    """Return required types and members absent from dexdump output."""
    blocks = re.split(r"(?m)^Class #\d+\s+-\s*$", dump)
    classes: dict[str, str] = {}
    for block in blocks:
        match = re.search(r"(?m)^\s*Class descriptor\s+: '([^']+)'", block)
        if match:
            classes[match.group(1)] = block
    missing = [name for name in (*CLASSES, REGISTRAR, FLUTTER_ERROR) if name not in classes]
    for owner, members in MEMBERS.items():
        block = classes.get(owner, "")
        if not block:
            continue
        found = set(re.findall(r"(?m)^\s*name\s+: '([^']+)'\n\s*type\s+: '([^']+)'", block))
        missing.extend(f"{owner} {name} {signature}" for name, signature in sorted(members - found))
    # Kotlin's facade inherits this static method from a superclass; R8 may
    # rename the superclass while preserving JNI lookup through the facade.
    if INTRINSICS in classes and not _has_intrinsics_method(classes):
        missing.append(f"{INTRINSICS} getCOROUTINE_SUSPENDED ()Ljava/lang/Object;")
    return missing


def _has_intrinsics_method(classes: dict[str, str]) -> bool:
    current = INTRINSICS
    visited: set[str] = set()
    while current in classes and current not in visited:
        visited.add(current)
        block = classes[current]
        if re.search(
            r"(?m)^\s*name\s+: 'getCOROUTINE_SUSPENDED'\n"
            r"\s*type\s+: '\(\)Ljava/lang/Object;'",
            block,
        ):
            return True
        parent = re.search(r"(?m)^\s*Superclass\s+: '([^']+)'", block)
        current = parent.group(1) if parent else ""
    return False


def dump_apk(apk: Path, dexdump: Path) -> str:
    """Dump every classes*.dex, including split multidex output."""
    with zipfile.ZipFile(apk) as archive, tempfile.TemporaryDirectory() as temporary:
        dexes = [name for name in archive.namelist() if re.fullmatch(r"classes\d*\.dex", name)]
        if not dexes:
            raise ValueError("APK contains no classes*.dex")
        chunks = []
        for name in dexes:
            target = Path(temporary) / name
            target.write_bytes(archive.read(name))
            # Both executables and arguments are explicit paths; no shell is involved.
            result = subprocess.run(  # noqa: S603
                [str(dexdump), "-f", str(target)], check=True, capture_output=True, text=True
            )
            chunks.append(result.stdout)
        return "\n".join(chunks)


def main() -> int:
    """Run the release APK check."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("dexdump", type=Path)
    args = parser.parse_args()
    try:
        missing = missing_symbols(dump_apk(args.apk, args.dexdump))
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print(f"JNI check failed: {error}", file=sys.stderr)
        return 2
    if missing:
        print("Release APK is missing JNI symbols:\n" + "\n".join(missing), file=sys.stderr)
        return 1
    print("Release APK retains the required preferences JNI symbols")
    return 0


if __name__ == "__main__":
    sys.exit(main())
