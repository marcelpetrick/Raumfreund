#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Tests tool/write_release_notes.sh with temporary artifacts.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
script="${root_dir}/tool/write_release_notes.sh"

if "${script}" v1.0.0 '* v1.0.0 test' "${work}" >/dev/null 2>&1; then
	echo "expected missing APK to fail" >&2
	exit 1
fi
touch "${work}/raumfreund.apk"
notes="$(${script} v1.0.0 '* v1.0.0 adds release' "${work}")"
grep -q '^# Raumfreund v1.0.0$' <<<"${notes}"
grep -q '^adds release$' <<<"${notes}"
grep -q 'SHA256SUMS' <<<"${notes}"
echo "all write_release_notes tests passed"
