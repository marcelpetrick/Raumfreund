#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# check_release_version.sh – verify a release tag against the repository.
#
# Usage:   tool/check_release_version.sh <tag> [<previous-tag>]
#
# Checks that <tag> is SemVer (including alpha/beta/rc prereleases), equals the
# version in pubspec.yaml, that CHANGELOG.md contains the matching line, and
# tag is given – that the Android build number (versionCode) increased.
# Prints the release notes line on success.
#
# Environment: RAUMFREUND_ROOT overrides the repository root (tests).
# Exit codes: 0 consistent, 1 inconsistent, 2 usage error.
set -euo pipefail

root_dir="${RAUMFREUND_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

fail() {
	echo "release check failed: $*" >&2
	exit 1
}

build_number_at() {
	git -C "${root_dir}" show "$1:pubspec.yaml" |
		sed -n 's/^version: *[0-9A-Za-z.-]*+\([0-9]*\) *$/\1/p'
}

[[ $# -ge 1 && $# -le 2 ]] || {
	echo "usage: $0 <tag> [<previous-tag>]" >&2
	exit 2
}
tag="$1"
semver='[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?'
[[ "${tag}" =~ ^v(${semver})$ ]] || fail "tag '${tag}' is not a supported SemVer tag"
version="${BASH_REMATCH[1]}"
current="$(sed -n 's/^version: *\([0-9A-Za-z.-]*\)+\([0-9]*\) *$/\1 \2/p' "${root_dir}/pubspec.yaml")"
[[ "${current% *}" == "${version}" ]] || fail "pubspec.yaml has ${current% *}, tag is ${version}"
line="$(grep -F "* v${version} " "${root_dir}/CHANGELOG.md" || true)"
[[ -n "${line}" ]] || fail "CHANGELOG.md has no line for v${version}"
if [[ $# -eq 2 ]]; then
	previous="$(build_number_at "$2")"
	[[ -n "${previous}" && "${current#* }" -gt "${previous}" ]] ||
		fail "build number ${current#* } is not greater than ${previous:-?} of $2"
fi
echo "${line}"
