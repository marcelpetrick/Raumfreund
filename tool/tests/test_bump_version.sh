#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# test_bump_version.sh – tests for tool/bump_version.sh on a temporary copy.
#
# Usage:   tool/tests/test_bump_version.sh
# Exit codes: 0 all tests passed, 1 at least one failure.
set -uo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bump_version.sh"
failures=0

check() {
	if [[ "$2" == "$3" ]]; then
		echo "ok   - $1"
	else
		echo "FAIL - $1: expected '$3', got '$2'"
		failures=$((failures + 1))
	fi
}

fixture() {
	local dir
	dir="$(mktemp -d)"
	printf 'name: x\nversion: %s\n' "$1" >"${dir}/pubspec.yaml"
	printf '# Changelog\n' >"${dir}/CHANGELOG.md"
	echo "${dir}"
}

run_bump() {
	RAUMFREUND_ROOT="$1" "${script}" "$2" "$3"
}

dir="$(fixture 1.2.3+7)"
check "patch bump" "$(run_bump "${dir}" patch 'fixes x')" "1.2.4+8"
check "pubspec updated" "$(grep '^version' "${dir}/pubspec.yaml")" "version: 1.2.4+8"
check "changelog line" "$(tail -1 "${dir}/CHANGELOG.md")" "* v1.2.4 fixes x"
check "minor bump resets patch" "$(run_bump "${dir}" minor 'adds y')" "1.3.0+9"
check "major bump resets minor" "$(run_bump "${dir}" major 'breaks z')" "2.0.0+10"
check "current" "$(RAUMFREUND_ROOT="${dir}" "${script}" --current)" "2.0.0+10"
rm -rf "${dir}"

dir="$(fixture 0.0.9+99)"
check "multi-digit carry" "$(run_bump "${dir}" patch 'p')" "0.0.10+100"
RAUMFREUND_ROOT="${dir}" "${script}" bogus 'x' 2>/dev/null
check "invalid part exits 2" "$?" "2"
RAUMFREUND_ROOT="${dir}" "${script}" patch 2>/dev/null
check "missing text exits 2" "$?" "2"
check "failed runs change nothing" "$(grep '^version' "${dir}/pubspec.yaml")" "version: 0.0.10+100"
rm -rf "${dir}"

dir="$(fixture broken)"
RAUMFREUND_ROOT="${dir}" "${script}" patch 'x' 2>/dev/null
check "unparsable version exits 2" "$?" "2"
rm -rf "${dir}"

[[ ${failures} -eq 0 ]] || exit 1
echo "all bump_version tests passed"
