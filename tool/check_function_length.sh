#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# check_function_length.sh – enforce the 100-physical-line limit per function
# (vision section 6, AGENTS.md section 5) for all hand-written sources.
#
# Usage:   tool/check_function_length.sh [--max N]
#
# Runs both parser-based checkers over the repository's own sources:
#   Dart    tool/function_length/dart (package:analyzer) on lib/, test/,
#           integration_test/ and tool/ (generated files are skipped)
#   Kotlin, tool/function_length/fnlen.py (tree-sitter / ast) on
#   Bash,   android/app/src/, tool/ and every *.sh file in the repository
#   Python
# Needs the pinned Flutter SDK (tool/flutter.sh) and the Python venv created
# by tool/install_tools.sh. Both checkers always run, so one invocation
# reports every violation.
#
# Exit codes: 0 no violations, 1 violations found,
#             2 usage, setup or parse error.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
venv_python="${root_dir}/.toolchain/venv/bin/python"
max=100

usage() {
	sed -n '5,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--max)
			[[ $# -ge 2 ]] || {
				usage >&2
				exit 2
			}
			max="$2"
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			usage >&2
			exit 2
			;;
		esac
	done
}

# Prints the given repository-relative paths that exist, as absolute paths.
existing() {
	local path
	for path in "$@"; do
		if [[ -e "${root_dir}/${path}" ]]; then
			printf '%s\n' "${root_dir}/${path}"
		fi
	done
}

run_dart() {
	local sdk_dir dart paths
	sdk_dir="$("${root_dir}/tool/flutter.sh" --ensure)" || return 2
	dart="${sdk_dir}/bin/dart"
	mapfile -t paths < <(existing lib test integration_test tool)
	(
		cd "${root_dir}/tool/function_length/dart"
		"${dart}" --suppress-analytics pub get --enforce-lockfile >/dev/null || exit 2
		"${dart}" --suppress-analytics run bin/check.dart --max "${max}" "${paths[@]}"
	)
}

run_python() {
	local paths scripts
	if [[ ! -x "${venv_python}" ]]; then
		echo "error: ${venv_python} missing – run tool/install_tools.sh" >&2
		return 2
	fi
	mapfile -t paths < <(existing android/app/src tool)
	# Every shell script, tracked or new (ignored files such as .toolchain stay out).
	mapfile -t scripts < <(git -C "${root_dir}" ls-files -co --exclude-standard '*.sh')
	paths+=("${scripts[@]/#/${root_dir}/}")
	"${venv_python}" "${root_dir}/tool/function_length/fnlen.py" --max "${max}" "${paths[@]}"
}

# Shortens absolute paths in reports to repository-relative ones.
relative() {
	sed "s|^${root_dir}/||"
}

main() {
	local dart_rc=0 python_rc=0
	parse_args "$@"
	echo "== Dart function length (max ${max})"
	run_dart | relative || dart_rc=$?
	echo "== Kotlin/Bash/Python function length (max ${max})"
	run_python | relative || python_rc=$?
	if [[ ${dart_rc} -ge 2 || ${python_rc} -ge 2 ]]; then
		exit 2
	elif [[ ${dart_rc} -ne 0 || ${python_rc} -ne 0 ]]; then
		exit 1
	fi
	echo "OK: no function exceeds ${max} lines"
}

main "$@"
