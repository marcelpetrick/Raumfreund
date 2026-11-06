# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

"""Regression checks for release DEX JNI contract verification."""

from check_jni_symbols import CLASSES, FLUTTER_ERROR, MEMBERS, REGISTRAR, missing_symbols


def _dump() -> str:
    chunks = []
    for index, owner in enumerate((*CLASSES, REGISTRAR, FLUTTER_ERROR)):
        entries = "".join(
            f"      name          : '{name}'\n      type          : '{signature}'\n"
            for name, signature in sorted(MEMBERS.get(owner, set()))
        )
        if owner == "Lkotlin/coroutines/intrinsics/IntrinsicsKt;":
            entries += "      name          : 'getCOROUTINE_SUSPENDED'\n"
            entries += "      type          : '()Ljava/lang/Object;'\n"
        chunks.append(f"Class #{index}            -\n  Class descriptor  : '{owner}'\n{entries}")
    return "\n".join(chunks)


def test_all_required_symbols_pass() -> None:
    assert missing_symbols(_dump()) == []


def test_obfuscated_kotlin_class_is_detected() -> None:
    result = missing_symbols(_dump().replace("Lkotlin/Unit;", "La;"))
    assert "Lkotlin/Unit;" in result


def test_obfuscated_suspend_method_descriptor_is_detected() -> None:
    result = missing_symbols(_dump().replace("Lkotlin/coroutines/Continuation;)", "Lw4;)"))
    assert any("setString" in item for item in result)
    assert any("getAll" in item for item in result)


def test_missing_private_result_value_is_detected() -> None:
    result = missing_symbols(_dump().replace("name          : 'value'", "name          : 'a'"))
    assert any("value" in item for item in result)


def test_intrinsics_method_must_be_available_on_facade_or_superclass() -> None:
    dump = _dump().replace(
        "  Class descriptor  : 'Lkotlin/coroutines/intrinsics/IntrinsicsKt;'\n",
        "  Class descriptor  : 'Lkotlin/coroutines/intrinsics/IntrinsicsKt;'\n"
        "  Superclass        : 'LobfuscatedParent;'\n",
    )
    method = (
        "      name          : 'getCOROUTINE_SUSPENDED'\n"
        "      type          : '()Ljava/lang/Object;'\n"
    )
    dump = dump.replace(method, "")
    assert any("getCOROUTINE_SUSPENDED" in item for item in missing_symbols(dump))
    dump += "\nClass #99            -\n  Class descriptor  : 'LobfuscatedParent;'\n" + method
    assert missing_symbols(dump) == []
