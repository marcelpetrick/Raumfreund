#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# test_check_privacy.sh – tests for tool/check_privacy.sh with a fake aapt2 and
# throw-away source trees; no real build or Android SDK is needed.
#
# Usage:   tool/tests/test_check_privacy.sh
# Exit codes: 0 all tests passed, 1 at least one failure.
set -uo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check_privacy.sh"
failures=0
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
kotlin_dir="${work}/android/app/src/main/kotlin"
apk_args=(--apk-only --apk "${work}/app.apk")

# expect <name> <exit> <output regex> <args…>
expect() {
	local name="$1" expected="$2" pattern="$3" out actual
	shift 3
	out="$(RAUMFREUND_ROOT="${work}" RAUMFREUND_AAPT2="${work}/aapt2" "${script}" "$@" 2>&1)"
	actual=$?
	if [[ ${actual} -eq ${expected} && "${out}" =~ ${pattern} ]]; then
		echo "ok   - ${name}"
	else
		echo "FAIL - ${name}: expected exit ${expected} /${pattern}/, got ${actual}: ${out}"
		failures=$((failures + 1))
	fi
}

# fake_aapt2 <badging line…>: the stub prints a badging with these lines.
fake_aapt2() {
	{
		echo '#!/usr/bin/env bash'
		echo "echo \"package: name='it.example.app' versionCode='1'\""
		local line
		for line in "$@"; do
			echo "echo \"${line}\""
		done
	} >"${work}/aapt2"
	chmod +x "${work}/aapt2"
}

# reset_tree [extra dependency line]: a clean tree; dev dependencies may use
# network packages because they never ship in the APK.
reset_tree() {
	rm -rf "${work:?}/android" "${work:?}/lib"
	mkdir -p "${kotlin_dir}" "${work}/lib"
	{
		printf 'dependencies:\n  flutter:\n    sdk: flutter\n  shared_preferences: 1.0.0\n'
		[[ -z "${1:-}" ]] || printf '  %s: 1.0.0\n' "$1"
		printf '\ndev_dependencies:\n  http: 1.0.0\n'
	} >"${work}/pubspec.yaml"
	echo 'val source = MediaRecorder.AudioSource.MIC' >"${kotlin_dir}/Ok.kt"
	echo '// FileOutputStream is only mentioned in a comment' >>"${kotlin_dir}/Ok.kt"
	echo 'void main() {}' >"${work}/lib/main.dart"
}

# bad_source <name> <file> <line>: a tree with one forbidden line must fail.
bad_source() {
	reset_tree
	echo "$3" >"${work}/$2"
	expect "source: $1" 1 "VIOLATION" --source-only
}

test_source_apis() {
	reset_tree
	expect "clean sources pass (AudioSource, comments, dev deps)" 0 "ok" --source-only
	bad_source "MediaRecorder instance" android/app/src/main/kotlin/A.kt 'val r = MediaRecorder()'
	bad_source "FileOutputStream" android/app/src/main/kotlin/A.kt 'FileOutputStream(f)'
	bad_source "openFileOutput" android/app/src/main/kotlin/A.kt 'openFileOutput("a", 0)'
	bad_source "okhttp" android/app/src/main/kotlin/A.kt 'import okhttp3.OkHttpClient'
	bad_source "java.net" android/app/src/main/kotlin/A.kt 'import java.net.URL'
	bad_source "Dart HttpClient" lib/a.dart 'final c = HttpClient();'
	bad_source "Dart package:http" lib/a.dart "import 'package:http/http.dart';"
	bad_source "Dart file write" lib/a.dart 'await f.writeAsBytes(b);'
	bad_source "Dart WebSocket" lib/a.dart 'WebSocket.connect(u);'
}

test_source_dependencies() {
	reset_tree firebase_core
	expect "firebase dependency" 1 "firebase_core" --source-only
	reset_tree my_analytics_kit
	expect "analytics dependency" 1 "my_analytics_kit" --source-only
	reset_tree sentry_flutter
	expect "sentry dependency" 1 "sentry_flutter" --source-only
	rm -rf "${work:?}/lib"
	expect "missing source directory is a usage error" 2 "missing" --source-only
}

test_apk_permissions() {
	touch "${work}/app.apk"
	fake_aapt2 "uses-permission: name='android.permission.RECORD_AUDIO'" \
		"uses-permission: name='android.permission.VIBRATE'" \
		"uses-permission: name='it.example.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'"
	expect "allowlisted permissions pass" 0 "ok" "${apk_args[@]}"
	fake_aapt2 "uses-permission: name='android.permission.INTERNET'"
	expect "INTERNET fails clearly" 1 "android.permission.INTERNET" "${apk_args[@]}"
	fake_aapt2 "uses-permission-sdk-23: name='android.permission.INTERNET'"
	expect "sdk-23 INTERNET fails" 1 "android.permission.INTERNET" "${apk_args[@]}"
	fake_aapt2 "uses-permission: name='android.permission.WRITE_EXTERNAL_STORAGE'"
	expect "storage permission fails" 1 "allowlist: android.permission.WRITE_EXTERNAL" "${apk_args[@]}"
	fake_aapt2 "uses-permission: name='android.permission.ACCESS_NETWORK_STATE'"
	expect "network state fails" 1 "ACCESS_NETWORK_STATE" "${apk_args[@]}"
	fake_aapt2 "uses-permission: name='other.pkg.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'"
	expect "foreign dynamic receiver permission fails" 1 "other.pkg" "${apk_args[@]}"
}

test_apk_inputs() {
	fake_aapt2 "uses-feature: name='android.hardware.wifi'"
	expect "wifi feature fails" 1 "android.hardware.wifi" "${apk_args[@]}"
	fake_aapt2 "uses-feature: name='android.hardware.microphone'"
	expect "microphone feature passes" 0 "ok" "${apk_args[@]}"
	expect "missing APK is a usage error" 2 "APK not found" --apk-only --apk "${work}/none.apk"
	expect "unknown flag is a usage error" 2 "check_privacy" --bogus
}

test_source_apis
test_source_dependencies
test_apk_permissions
test_apk_inputs
exit $((failures > 0))
