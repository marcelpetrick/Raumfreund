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
#   tools       install/verify pinned lint and security tools (tool/install_tools.sh)
#   deps        flutter pub get --enforce-lockfile (app and tool packages)
#   format      dart format check (no changes allowed)
#   analyze     flutter analyze --fatal-infos --fatal-warnings
#   fnlen       100-physical-line limit per function (parser based)
#   shell       shellcheck + shfmt for all shell scripts
#   python      ruff lint/format, mypy --strict, pytest (tooling code)
#   tooltests   tests of the repository scripts and the Dart checker
#   docs        markdownlint for all Markdown files
#   licenses    license inventory matches pubspec.lock and .flutter-version
#   yaml        yamllint (strict) + actionlint for GitHub workflows
#   kotlin      ktlint + detekt for native Android sources
#   native      JVM unit tests + Android lint
#   secrets     gitleaks secret scan of the git history and working tree
#   vulns       osv-scanner on all lockfiles
#   test        flutter test with coverage
#   coverage    line coverage gate (>= 95 %) on own Dart code
#   apk         flutter build apk --debug
#   privacy     privacy gate: source scan + release APK permissions (tool/check_privacy.sh),
#               then the Android rows of the license inventory vs. the release build
#   docker      build the Docker image and verify it (tool/docker_check.sh)
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
TOOLS="${ROOT_DIR}/.toolchain/bin"
VENV="${ROOT_DIR}/.toolchain/venv/bin"
CHECKER_DIR="${ROOT_DIR}/tool/function_length/dart"
COVERAGE_MIN_LINE_PERCENT="95.0"
ALL_STEPS=(toolchain tools deps format analyze fnlen shell python tooltests docs licenses yaml secrets vulns kotlin native test coverage apk privacy docker)
VERBOSE=0
ONLY=""
SKIP=""
FAILED=0
declare -a SUMMARY_LINES=()

print_usage() {
	sed -n '5,42p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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
		"$@" 2>&1 | tee -a "${log}"
		return "${PIPESTATUS[0]}"
	fi
	if "$@" >>"${log}" 2>&1; then
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
step_tools() { run_logged tools "${ROOT_DIR}/tool/install_tools.sh"; }

step_deps() {
	run_logged deps "${FLUTTER}" pub get --enforce-lockfile &&
		run_logged deps "${FLUTTER}" pub get --enforce-lockfile -C "${CHECKER_DIR}"
}

step_fnlen() { run_logged fnlen "${ROOT_DIR}/tool/check_function_length.sh"; }

step_python() {
	run_logged python "${VENV}/ruff" check tool &&
		run_logged python "${VENV}/ruff" format --check tool &&
		run_logged python "${VENV}/mypy" --config-file tool/pyproject.toml tool/function_length tool/demo \
			tool/license_inventory &&
		run_logged python "${VENV}/pytest" -q -c tool/pyproject.toml
}

step_docs() {
	run_logged docs "${ROOT_DIR}/tool/node/node_modules/.bin/markdownlint" '**/*.md'
}

step_licenses() {
	run_logged licenses "${VENV}/python" "${ROOT_DIR}/tool/license_inventory/check_license_inventory.py" \
		--root "${ROOT_DIR}"
}

step_yaml() {
	run_logged yaml "${VENV}/yamllint" --strict . &&
		run_logged yaml "${TOOLS}/actionlint"
}

step_secrets() {
	run_logged secrets "${ROOT_DIR}/tool/check_secrets.sh"
}

step_vulns() {
	run_logged vulns "${TOOLS}/osv-scanner" scan source --lockfile pubspec.lock \
		--lockfile tool/function_length/dart/pubspec.lock \
		--lockfile tool/node/package-lock.json \
		--lockfile requirements.txt:tool/requirements-dev.txt
}

step_kotlin() { run_logged kotlin "${ROOT_DIR}/tool/kotlin_lint.sh"; }

step_native() {
	run_logged native "${ROOT_DIR}/android/gradlew" -p "${ROOT_DIR}/android" \
		testDebugUnitTest lintDebug
}

step_format() {
	local dart_bin dirs=(lib test)
	dart_bin="$("${FLUTTER}" --ensure)/bin/dart"
	[[ -d integration_test ]] && dirs+=(integration_test)
	run_logged format "${dart_bin}" format --output=none --set-exit-if-changed \
		"${dirs[@]}"
}

step_analyze() {
	# The git-ignored coverage import test lists every library below lib/;
	# regenerate it first so a stale copy cannot reference removed files.
	"${ROOT_DIR}/tool/generate_coverage_imports.sh" &&
		run_logged analyze "${FLUTTER}" analyze --fatal-infos --fatal-warnings
}

step_shell() {
	local scripts=()
	mapfile -t scripts < <(shell_scripts)
	run_logged shell "${TOOLS}/shellcheck" --external-sources "${scripts[@]}" &&
		run_logged shell "${TOOLS}/shfmt" -d "${scripts[@]}"
}

step_tooltests() {
	local test_script status=0
	for test_script in "${ROOT_DIR}"/tool/tests/test_*.sh; do
		run_logged tooltests "${test_script}" || status=1
	done
	(cd "${CHECKER_DIR}" && run_logged tooltests "$("${FLUTTER}" --ensure)/bin/dart" test) || status=1
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

# The debug APK of the apk step legitimately holds INTERNET (hot reload), so
# the permission proof builds the release variant it ships: without
# android/key.properties Gradle signs it with the debug key, which is fine here.
step_privacy() {
	run_logged privacy "${ROOT_DIR}/tool/check_privacy.sh" --source-only &&
		run_logged privacy "${FLUTTER}" build apk --release &&
		run_logged privacy "${ROOT_DIR}/tool/check_privacy.sh" --apk-only &&
		run_logged privacy "${VENV}/python" "${ROOT_DIR}/tool/license_inventory/check_license_inventory.py" \
			--root "${ROOT_DIR}" \
			--sdk-dependencies "${ROOT_DIR}/build/app/outputs/sdk-dependencies/release/sdkDependencies.txt"
}

step_docker() { run_logged docker "${ROOT_DIR}/tool/docker_check.sh"; }

# Explicit dispatch (instead of calling "step_${step}") keeps every call
# visible to static analysis and makes typos fail loudly.
dispatch_step() {
	case "$1" in
	toolchain) step_toolchain ;;
	tools) step_tools ;;
	deps) step_deps ;;
	format) step_format ;;
	analyze) step_analyze ;;
	fnlen) step_fnlen ;;
	shell) step_shell ;;
	python) step_python ;;
	tooltests) step_tooltests ;;
	docs) step_docs ;;
	licenses) step_licenses ;;
	yaml) step_yaml ;;
	secrets) step_secrets ;;
	vulns) step_vulns ;;
	kotlin) step_kotlin ;;
	native) step_native ;;
	test) step_test ;;
	coverage) step_coverage ;;
	apk) step_apk ;;
	privacy) step_privacy ;;
	docker) step_docker ;;
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
	: >"${REPORT_DIR}/${step}.log"
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
	docker) printf ' – %s' "$(tail -1 "${REPORT_DIR}/docker.log")" ;;
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
