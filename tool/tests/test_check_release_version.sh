#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# test_check_release_version.sh – tests for tool/check_release_version.sh
# using a throw-away git repository.
#
# Usage:   tool/tests/test_check_release_version.sh
# Exit codes: 0 all tests passed, 1 at least one failure.
set -uo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check_release_version.sh"
failures=0
repo="$(mktemp -d)"
trap 'rm -rf "${repo}"' EXIT

expect_exit() {
	local name="$1" expected="$2"
	shift 2
	RAUMFREUND_ROOT="${repo}" "${script}" "$@" >/dev/null 2>&1
	local actual=$?
	if [[ ${actual} -eq ${expected} ]]; then
		echo "ok   - ${name}"
	else
		echo "FAIL - ${name}: expected exit ${expected}, got ${actual}"
		failures=$((failures + 1))
	fi
}

commit_version() {
	printf 'version: %s\n' "$1" >"${repo}/pubspec.yaml"
	printf '# Changelog\n* v%s adds things\n' "${1%+*}" >"${repo}/CHANGELOG.md"
	git -C "${repo}" add -A && git -C "${repo}" commit -qm "v$1" && git -C "${repo}" tag "v${1%+*}"
}

git -C "${repo}" init -q && git -C "${repo}" config user.email t@t && git -C "${repo}" config user.name t
commit_version 0.1.0+10
commit_version 0.1.1+11

expect_exit "matching tag" 0 v0.1.1
expect_exit "matching tag with increased build" 0 v0.1.1 v0.1.0
expect_exit "tag differs from pubspec" 1 v0.1.2
expect_exit "malformed tag" 1 0.1.1
printf 'version: 0.2.0-beta.1+12\n' >"${repo}/pubspec.yaml"
printf '* v0.2.0-beta.1 adds beta\n' >>"${repo}/CHANGELOG.md"
expect_exit "prerelease tag accepted" 0 v0.2.0-beta.1
printf 'version: 0.1.1+11\n' >"${repo}/pubspec.yaml"
expect_exit "usage" 2
printf 'version: 0.1.2+10\n' >"${repo}/pubspec.yaml"
printf '* v0.1.2 x\n' >>"${repo}/CHANGELOG.md"
expect_exit "build number not increased" 1 v0.1.2 v0.1.0
printf 'version: 0.1.3+12\n' >"${repo}/pubspec.yaml"
expect_exit "missing changelog line" 1 v0.1.3

[[ ${failures} -eq 0 ]] || exit 1
echo "all check_release_version tests passed"
