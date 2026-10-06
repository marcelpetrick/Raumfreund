#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Tests tool/release_debug.sh with PATH shims for git and gh and stub
# build/SDK tools: no network, no real build, nothing is tagged or published.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
script="${root_dir}/tool/release_debug.sh"
fake="${work}/repo"
shims="${work}/shims"
sdk="${work}/sdk/build-tools/36.0.0"
calls="${work}/calls.log"
mkdir -p "${fake}/tool" "${shims}" "${sdk}"

# Writes an executable stub from stdin to the given path.
write_stub() {
	{
		echo '#!/usr/bin/env bash'
		cat
	} >"$1"
	chmod +x "$1"
}

setup_repo_stubs() {
	write_stub "${fake}/tool/bump_version.sh" <<'EOF'
echo 1.2.3+45
EOF
	write_stub "${fake}/tool/build_apk.sh" <<'EOF'
mkdir -p "$(dirname "$0")/../dist" && cd "$(dirname "$0")/../dist"
echo apk >raumfreund-1.2.3-debugsigned.apk && echo 1.2.3+45 >VERSION
sha256sum raumfreund-1.2.3-debugsigned.apk >SHA256SUMS
EOF
	printf '%s\n' '# Changelog' '* v1.2.1 adds an old feature' \
		'* v1.2.2 adds a middle feature' '* v1.2.3 adds a test feature' >"${fake}/CHANGELOG.md"
}

setup_shims() {
	write_stub "${shims}/gh" <<'EOF'
echo "gh $*" >>"${CALLS}"
[[ "${FAKE_NO_AUTH:-}" != 1 ]] || [[ "$1" != auth ]] || exit 1
[[ "${FAKE_RELEASE_FAILS:-}" != 1 ]] || [[ "$1" != release ]]
EOF
	write_stub "${shims}/git" <<'EOF'
echo "git $*" >>"${CALLS}"
[[ "$1" == -C ]] && shift 2
case "$1" in
branch) echo "${FAKE_BRANCH:-main}" ;;
status) echo "${FAKE_DIRTY:-}" ;;
rev-parse) case "$*" in
	*--verify*) [[ -n "${FAKE_LOCAL_TAG:-}" ]] ;;
	*origin/main*) echo "${FAKE_ORIGIN:-aaaaaaaaaaaaaaaa}" ;;
	*) echo "${FAKE_HEAD:-aaaaaaaaaaaaaaaa}" ;;
	esac ;;
ls-remote) [[ -n "${FAKE_REMOTE_TAG:-}" ]] ;;
tag) [[ "$2" != -l ]] || echo "${FAKE_PREV_TAG:-}" ;;
*) ;;
esac
EOF
}

setup_sdk_stubs() {
	write_stub "${sdk}/aapt2" <<'EOF'
cat <<'OUT'
package: name='it.marcelpetrick.raumfreund' versionCode='45' versionName='1.2.3'
minSdkVersion:'24'
targetSdkVersion:'36'
uses-permission: name='android.permission.RECORD_AUDIO'
uses-permission: name='android.permission.VIBRATE'
uses-permission: name='it.marcelpetrick.raumfreund.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
OUT
EOF
	write_stub "${sdk}/apksigner" <<'EOF'
cat <<'OUT'
Signer #1 certificate DN: CN=Android Debug, O=Android, C=US
Signer #1 certificate SHA-256 digest: c5552941
OUT
EOF
}

# run_release <expected exit> <expected output fragment> <command and env...>
run_release() {
	local want="$1" fragment="$2" status=0 out
	shift 2
	: >"${calls}"
	out="$(env "$@" 2>&1)" || status=$?
	if [[ "${status}" -ne "${want}" ]] || ! grep -qF -- "${fragment}" <<<"${out}"; then
		echo "FAIL: want exit ${want} with '${fragment}', got ${status}:" >&2
		echo "${out}" >&2
		exit 1
	fi
	LAST_OUT="${out}"
}

test_precondition_failures() {
	run_release 0 'Usage:' "${env_base[@]}" "${script}" --help
	run_release 2 'Usage:' "${env_base[@]}" "${script}" --bogus
	run_release 1 'not on branch main' "${env_base[@]}" FAKE_BRANCH=dev "${script}"
	run_release 1 'working tree is not clean' "${env_base[@]}" FAKE_DIRTY=' M x' "${script}"
	run_release 1 'HEAD is not equal to origin/main' "${env_base[@]}" FAKE_ORIGIN=bbbb "${script}"
	run_release 1 'tag debug-v1.2.3-build45 already exists locally' \
		"${env_base[@]}" FAKE_LOCAL_TAG=1 "${script}"
	run_release 1 'tag debug-v1.2.3-build45 already exists on origin' \
		"${env_base[@]}" FAKE_REMOTE_TAG=1 "${script}"
	run_release 1 'gh is not authenticated' "${env_base[@]}" FAKE_NO_AUTH=1 "${script}"
	mkdir -p "${fake}/android" && touch "${fake}/android/key.properties"
	run_release 1 'production-signed' "${env_base[@]}" "${script}"
	rm -rf "${fake}/android"
}

test_dry_run() {
	local expected
	run_release 0 'dry run, would publish debug-v1.2.3-build45' "${env_base[@]}" "${script}" --dry-run
	for expected in '# Raumfreund 1.2.3+45 — public debug APK' 'adds a test feature' \
		'Minimum Android: API 24' 'Target Android API: 36' 'microphone, vibration; no Internet' \
		"Signing certificate SHA-256: \`c5552941\`" "Source commit: \`aaaaaaaaaaaaaaaa\`"; do
		grep -qF -- "${expected}" <<<"${LAST_OUT}" || {
			echo "FAIL: notes lack '${expected}'" >&2
			exit 1
		}
	done
	if grep -Eq 'git .*(tag -a|push)|gh release create' "${calls}"; then
		echo "FAIL: dry run must not tag, push or publish" >&2
		exit 1
	fi
}

# Notes list every CHANGELOG entry after the previous debug release.
test_changelog_range() {
	run_release 0 'adds a middle feature' "${env_base[@]}" \
		FAKE_PREV_TAG=debug-v1.2.1-build43 "${script}" --dry-run
	if ! grep -qF 'adds a test feature' <<<"${LAST_OUT}" ||
		grep -qF 'adds an old feature' <<<"${LAST_OUT}"; then
		echo "FAIL: changelog range since debug-v1.2.1 is wrong" >&2
		exit 1
	fi
	run_release 0 'adds an old feature' "${env_base[@]}" "${script}" --dry-run
	if grep -qF 'DYNAMIC_RECEIVER' <<<"${LAST_OUT}"; then
		echo "FAIL: app-internal permission listed in notes" >&2
		exit 1
	fi
}

test_publish() {
	run_release 0 'published debug-v1.2.3-build45' "${env_base[@]}" "${script}"
	grep -q 'git -C .* tag -a debug-v1.2.3-build45' "${calls}"
	grep -q 'gh release create debug-v1.2.3-build45 .* --latest' "${calls}"
	grep -q -- '--title Raumfreund 1.2.3+45 – Debug APK' "${calls}"
}

# A failed release creation must not leave the pushed tag behind.
test_failed_publish_removes_tag() {
	run_release 1 'tag debug-v1.2.3-build45 removed again' "${env_base[@]}" \
		FAKE_RELEASE_FAILS=1 "${script}"
	grep -q 'git -C .* push --quiet origin --delete refs/tags/debug-v1.2.3-build45' "${calls}"
	grep -q 'git -C .* tag -d debug-v1.2.3-build45' "${calls}"
}

env_base=("PATH=${shims}:${PATH}" "RAUMFREUND_ROOT=${fake}" "CALLS=${calls}" "ANDROID_HOME=${work}/sdk")
setup_repo_stubs
setup_shims
setup_sdk_stubs
test_precondition_failures
test_dry_run
test_changelog_range
test_publish
test_failed_publish_removes_tag
echo "all release_debug tests passed"
