#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# kotlin_lint.sh – ktlint and detekt for the Kotlin host code.
#
# Usage:   tool/kotlin_lint.sh            check android/app/src/**/*.kt
#          tool/kotlin_lint.sh --format   let ktlint fix formatting first
#
# Uses the pinned CLI tools in .toolchain/bin (installed by the tooling
# script): `ktlint` (1.8.0) and `detekt-cli` (1.23.8). Set
# RAUMFREUND_TOOLS_BIN to use another directory with the same tools.
#
# CLIs instead of Gradle plugins: detekt 1.23.8 is built against Kotlin
# 2.0.21 and its Gradle plugin hooks into the legacy AGP variant API (it ran
# here only because the Flutter template still sets android.newDsl=false).
# The CLIs run on their own classpath, independent of the Kotlin 2.4/AGP 9.1
# build, are pinned by version and need no network access at build time.
# detekt uses config/detekt.yml on top of its defaults.
#
# Exit codes: 0 clean, 1 findings, 2 usage error, 3 tool missing.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tools_bin="${RAUMFREUND_TOOLS_BIN:-${root_dir}/.toolchain/bin}"
ktlint="${tools_bin}/ktlint"
detekt="${tools_bin}/detekt"
sources="${root_dir}/android/app/src"

format=0
case "${1:-}" in
"") ;;
--format) format=1 ;;
*)
	echo "usage: $0 [--format]" >&2
	exit 2
	;;
esac

for tool in "${ktlint}" "${detekt}"; do
	if [[ ! -x "${tool}" ]]; then
		echo "Missing ${tool}. Install the pinned Kotlin lint tools into" >&2
		echo ".toolchain/bin (ktlint 1.8.0, detekt-cli 1.23.8) or set" >&2
		echo "RAUMFREUND_TOOLS_BIN." >&2
		exit 3
	fi
done

status=0
cd "${root_dir}"
if [[ ${format} -eq 1 ]]; then
	"${ktlint}" --format "android/app/src/**/*.kt" || status=1
else
	"${ktlint}" "android/app/src/**/*.kt" || status=1
fi
"${detekt}" --input "${sources}" \
	--config "${root_dir}/config/detekt.yml" --build-upon-default-config ||
	status=1
exit "${status}"
