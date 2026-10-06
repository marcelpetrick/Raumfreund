#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# check_privacy.sh – automated privacy gate (AGENTS.md section 7).
#
# Usage:   tool/check_privacy.sh [--source-only | --apk-only] [--apk FILE] [--help]
#
# Source check (no build needed):
#   * Kotlin below android/app/src/main/kotlin: MediaRecorder instances or
#     constants other than MediaRecorder.AudioSource (a plain source id for
#     AudioRecord), MediaMuxer, FileOutputStream, RandomAccessFile,
#     openFileOutput, java.net.*, HttpURLConnection, Socket, okhttp.
#   * Dart below lib/: HttpClient, Socket/WebSocket/RawSocket/ServerSocket,
#     package:http, package:dio, File(...) construction, writeAsBytes,
#     writeAsString, openWrite.
#   * pubspec.yaml `dependencies:` (not dev) must not name network, analytics,
#     crash-reporting or ad packages.
#   Comment-only lines are ignored. There is deliberately no allowlist: a
#   legitimate use must be discussed and the pattern narrowed in this file.
# APK check: `aapt2 dump badging` of the release APK (default
#   build/app/outputs/flutter-apk/app-release.apk). Every uses-permission must
#   be in an explicit allowlist (RECORD_AUDIO, VIBRATE and the
#   <package>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION that AndroidX adds);
#   network, storage and radio features are rejected as well.
# Without a mode flag both checks run. aapt2 is taken from the pinned Android
# build-tools (see tool/lib/android_sdk.sh) unless RAUMFREUND_AAPT2 is set.
#
# Environment: RAUMFREUND_ROOT overrides the repository root (tests).
# Exit codes: 0 no violation, 1 privacy violation, 2 usage error or missing
# input (APK, aapt2, source directory).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="${RAUMFREUND_ROOT:-$(cd "${script_dir}/.." && pwd)}"
# shellcheck source=tool/lib/android_sdk.sh
source "${script_dir}/lib/android_sdk.sh"

violations=0
mode="all"
apk="${root_dir}/build/app/outputs/flutter-apk/app-release.apk"

# "label::extended regex" pairs; matching is per line.
kotlin_rules=(
	"audio recording via MediaRecorder::MediaRecorder\\(|MediaRecorder\\.(OutputFormat|AudioEncoder|OnInfoListener)|setOutputFile"
	"media muxing (audio could be persisted)::MediaMuxer"
	"file writing::FileOutputStream|RandomAccessFile|openFileOutput"
	"network access::java\\.net\\.|HttpURLConnection|Socket|okhttp"
)
dart_rules=(
	"network access::HttpClient|Socket|package:http/|package:dio/"
	"file writing::\\bFile\\(|writeAsBytes|writeAsString|openWrite"
)
forbidden_packages='^(http|http2|dio|chopper|retrofit|web_socket_channel|socket_io_client|connectivity_plus|google_mobile_ads|mixpanel_flutter|amplitude_flutter|appsflyer_sdk|firebase_[a-z_]+|sentry[a-z_]*|[a-z_]*analytics[a-z_]*|[a-z_]*crashlytics[a-z_]*)$'
# Features that imply network, radio or storage access.
forbidden_features='android\.hardware\.(wifi|telephony|bluetooth|nfc|location)'

die_usage() {
	echo "check_privacy: $*" >&2
	exit 2
}

fail() {
	echo "check_privacy: VIOLATION: $*" >&2
	violations=$((violations + 1))
}

usage() {
	sed -n '5,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--source-only) mode="source" ;;
		--apk-only) mode="apk" ;;
		--apk) apk="${2:?--apk needs a file}" && shift ;;
		--help | -h) usage && exit 0 ;;
		*) usage >&2 && exit 2 ;;
		esac
		shift
	done
}

# scan_tree <dir> <include glob> <rules…>: reports every non-comment match.
scan_tree() {
	local dir="$1" glob="$2" rule hits
	shift 2
	[[ -d "${dir}" ]] || die_usage "source directory missing: ${dir}"
	for rule in "$@"; do
		hits="$(grep -rnE --include="${glob}" -e "${rule#*::}" "${dir}" 2>/dev/null |
			grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*)' || true)"
		[[ -z "${hits}" ]] || fail "${rule%%::*} in ${dir#"${root_dir}"/}:"$'\n'"${hits}"
	done
}

# Prints the package names below a top-level pubspec section.
pubspec_section() {
	awk -v sec="$1:" '
		/^[^ #]/ { in_sec = ($0 == sec); next }
		in_sec && /^  [A-Za-z0-9_]+:/ { sub(/^  /, ""); sub(/:.*/, ""); print }
	' "${root_dir}/pubspec.yaml"
}

check_dependencies() {
	local name
	[[ -f "${root_dir}/pubspec.yaml" ]] || die_usage "pubspec.yaml missing"
	while read -r name; do
		if [[ "${name}" =~ ${forbidden_packages} ]]; then
			fail "pubspec.yaml depends on network/analytics package '${name}'"
		fi
	done < <(pubspec_section dependencies)
}

check_source() {
	scan_tree "${root_dir}/android/app/src/main/kotlin" '*.kt' "${kotlin_rules[@]}"
	scan_tree "${root_dir}/lib" '*.dart' "${dart_rules[@]}"
	check_dependencies
}

# Prints the badging text of the APK (aapt2 from RAUMFREUND_AAPT2 or the SDK).
dump_badging() {
	local aapt2="${RAUMFREUND_AAPT2:-}" tools
	if [[ -z "${aapt2}" ]]; then
		tools="$(pinned_build_tools)" || exit 2
		aapt2="${tools}/aapt2"
	fi
	[[ -x "${aapt2}" ]] || die_usage "aapt2 not executable: ${aapt2}"
	"${aapt2}" dump badging "$1" || die_usage "aapt2 could not read $1"
}

# check_permission <name> <package>: allowlist decision for one permission.
check_permission() {
	case "$1" in
	android.permission.RECORD_AUDIO | android.permission.VIBRATE) ;;
	"$2.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION") ;;
	android.permission.INTERNET)
		fail "APK requests android.permission.INTERNET (release builds must work offline)"
		;;
	*) fail "APK requests permission outside the allowlist: $1" ;;
	esac
}

check_apk() {
	local badging package name
	[[ -f "${apk}" ]] || die_usage "APK not found: ${apk}"
	badging="$(dump_badging "${apk}")" || exit 2
	package="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<<"${badging}")"
	[[ -n "${package}" ]] || die_usage "no package name in badging of ${apk}"
	while read -r name; do
		check_permission "${name}" "${package}"
	done < <(sed -n "s/^uses-permission[a-z0-9-]*: name='\([^']*\)'.*/\1/p" <<<"${badging}")
	while read -r name; do
		if [[ "${name}" =~ ${forbidden_features} ]]; then
			fail "APK declares network/radio feature: ${name}"
		fi
	done < <(sed -n "s/^uses-\(implied-\)\{0,1\}feature[a-z-]*: name='\([^']*\)'.*/\2/p" <<<"${badging}")
}

main() {
	parse_args "$@"
	[[ "${mode}" == "apk" ]] || check_source
	[[ "${mode}" == "source" ]] || check_apk
	if [[ ${violations} -gt 0 ]]; then
		echo "check_privacy: ${violations} violation(s)" >&2
		exit 1
	fi
	echo "check_privacy: ok (${mode})"
}

main "$@"
