#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# localPipeline.sh – the single local quality gate of Raumfreund.
#
# Every commit must pass this script. GitHub Actions call the same script (with
# --only/--skip to split it into parallel jobs), so CI never has its own
# command list: change the gate here, not in the workflows.
#
# Steps (in order, names usable with --only/--skip):
#   toolchain   ensure the pinned Flutter SDK (tool/flutter.sh)
#   deps        flutter pub get --enforce-lockfile
#   format      dart format check (no changes allowed)
#   analyze     flutter analyze --fatal-infos --fatal-warnings
#   shell       shellcheck for all shell scripts
#   tooltests   tests of the repository scripts in tool/tests
#   test        flutter test with coverage
#   coverage    line coverage gate (>= 95 %) on own Dart code
#   apk         flutter build apk --debug
#
# Usage:
#   ./localPipeline.sh                 run all steps
#   ./localPipeline.sh --only analyze,test
#   ./localPipeline.sh --skip apk
#   ./localPipeline.sh --verbose       stream command output instead of logging
#   ./localPipeline.sh --list          print step names
#
# Logs of each step go to reports/pipeline/<step>.log; on failure the log is
# printed. Exit codes: 0 all selected steps passed, 1 at least one step failed,
# 2 invalid arguments.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${ROOT_DIR}/reports/pipeline"
FLUTTER="${ROOT_DIR}/tool/flutter.sh"
COVERAGE_MIN_LINE_PERCENT="95.0"
ALL_STEPS=(toolchain deps format analyze shell tooltests test coverage apk)
VERBOSE=0
ONLY=""
SKIP=""
FAILED=0
declare -a SUMMARY_LINES=()

print_usage() {
	sed -n '5,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

info() { printf '[INFO] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

mark_result() {
	SUMMARY_LINES+=("$(printf '%-10s : %-4s %s' "$1" "$2" "$3")")
}

print_summary() {
	printf '\n========== Local Pipeline Summary ==========\n'
	printf '%s\n' "${SUMMARY_LINES[@]}"
	printf '============================================\n'
}

# run_logged <step> <command…>: run a command, logging to reports/pipeline.
run_logged() {
	local step="$1" log="${REPORT_DIR}/$1.log"
	shift
	if [[ ${VERBOSE} -eq 1 ]]; then
		"$@" 2>&1 | tee "${log}"
		return "${PIPESTATUS[0]}"
	fi
	if "$@" >"${log}" 2>&1; then
		return 0
	fi
	error "${step} failed. Captured output (${log}):"
	sed 's/^/  | /' "${log}" >&2
	return 1
}

shell_scripts() {
	git -C "${ROOT_DIR}" ls-files --cached --others --exclude-standard '*.sh' |
		sed "s|^|${ROOT_DIR}/|"
}

step_toolchain() { run_logged toolchain "${FLUTTER}" --ensure; }
step_deps() { run_logged deps "${FLUTTER}" pub get --enforce-lockfile; }

step_format() {
	local dart_bin dirs=(lib test)
	dart_bin="$("${FLUTTER}" --ensure)/bin/dart"
	[[ -d integration_test ]] && dirs+=(integration_test)
	run_logged format "${dart_bin}" format --output=none --set-exit-if-changed \
		"${dirs[@]}"
}

step_analyze() {
	run_logged analyze "${FLUTTER}" analyze --fatal-infos --fatal-warnings
}

step_shell() {
	local scripts=()
	mapfile -t scripts < <(shell_scripts)
	run_logged shell shellcheck --external-sources "${scripts[@]}"
}

step_tooltests() {
	local test_script status=0
	for test_script in "${ROOT_DIR}"/tool/tests/test_*.sh; do
		run_logged tooltests "${test_script}" || status=1
	done
	return "${status}"
}

step_test() {
	"${ROOT_DIR}/tool/generate_coverage_imports.sh" &&
		run_logged test "${FLUTTER}" test --coverage --reporter expanded
}

step_coverage() {
	run_logged coverage "${ROOT_DIR}/tool/coverage_gate.sh" \
		"${ROOT_DIR}/coverage/lcov.info" "${COVERAGE_MIN_LINE_PERCENT}"
}

step_apk() { run_logged apk "${FLUTTER}" build apk --debug; }

# Explicit dispatch (instead of calling "step_${step}") keeps every call
# visible to static analysis and makes typos fail loudly.
dispatch_step() {
	case "$1" in
	toolchain) step_toolchain ;;
	deps) step_deps ;;
	format) step_format ;;
	analyze) step_analyze ;;
	shell) step_shell ;;
	tooltests) step_tooltests ;;
	test) step_test ;;
	coverage) step_coverage ;;
	apk) step_apk ;;
	*) error "No implementation for step '$1'" && return 1 ;;
	esac
}

contains() { [[ ",$1," == *",$2,"* ]]; }

selected() {
	if [[ -n "${ONLY}" ]]; then contains "${ONLY}" "$1" && return 0 || return 1; fi
	! contains "${SKIP}" "$1"
}

validate_steps() {
	local step
	for step in ${1//,/ }; do
		[[ " ${ALL_STEPS[*]} " == *" ${step} "* ]] || {
			error "Unknown step '${step}'. Use --list."
			exit 2
		}
	done
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--only) ONLY="${2:?--only needs steps}" && shift ;;
		--skip) SKIP="${2:?--skip needs steps}" && shift ;;
		--verbose) VERBOSE=1 ;;
		--list) printf '%s\n' "${ALL_STEPS[@]}" && exit 0 ;;
		-h | --help) print_usage && exit 0 ;;
		*) error "Unknown argument '$1'" && print_usage >&2 && exit 2 ;;
		esac
		shift
	done
	validate_steps "${ONLY}"
	validate_steps "${SKIP}"
}

run_step() {
	local step="$1" started duration
	if ! selected "${step}"; then
		mark_result "${step}" "SKIP" "not selected"
		return
	fi
	info "Running ${step} …"
	started=${SECONDS}
	if dispatch_step "${step}"; then
		duration=$((SECONDS - started))
		mark_result "${step}" "PASS" "${duration}s$(step_details "${step}")"
	else
		FAILED=1
		mark_result "${step}" "FAIL" "see ${REPORT_DIR#"${ROOT_DIR}"/}/${step}.log"
	fi
}

step_details() {
	case "$1" in
	coverage) printf ' – %s' "$(tail -1 "${REPORT_DIR}/coverage.log")" ;;
	test) printf ' – %s' "$(grep -Eo '\+[0-9]+.*All tests passed!' "${REPORT_DIR}/test.log" | tail -1)" ;;
	esac
}

main() {
	parse_args "$@"
	cd "${ROOT_DIR}" || exit 1
	mkdir -p "${REPORT_DIR}"
	local step
	for step in "${ALL_STEPS[@]}"; do
		run_step "${step}"
	done
	print_summary
	exit "${FAILED}"
}

main "$@"
