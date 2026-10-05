#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# release_debug.sh – build, verify and publish the public debug APK release.
#
# Usage:   tool/release_debug.sh [--dry-run] [--help]
#
# Steps: check preconditions (on main, clean tree, HEAD pushed, gh logged in,
# tag debug-v<X.Y.Z>-build<N> free locally and remotely, no
# android/key.properties) -> tool/build_apk.sh -> verify checksum, package,
# version, permissions and debug certificate -> render release notes ->
# create and push the annotated tag -> `gh release create --latest`.
# --dry-run does everything except tag, push and publish, and prints the notes.
#
# Why locally and not in CI: Android installs an update over an existing app
# only if the signing certificate matches. GitHub runners create a fresh debug
# keystore for every run, so a CI-built debug APK could never update an earlier
# one. Debug releases are therefore always signed with this machine's
# ~/.android/debug.keystore; the notes print the certificate digest. RISK: if
# that keystore is lost, testers must uninstall the app once before updating.
#
# Environment: ANDROID_HOME / ANDROID_SDK_ROOT (else ~/Android/Sdk) locate
# aapt2 and apksigner; RAUMFREUND_ROOT overrides the repository root (tests).
# Exit codes: 0 success, 1 precondition, build or verification failure,
# 2 usage error or required tool missing.
set -euo pipefail

root_dir="${RAUMFREUND_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
dist="${root_dir}/dist"
package_id="it.marcelpetrick.raumfreund"
dry_run=0
aapt2=""
apksigner=""
badging=""
certs=""
apk_sha=""
notes_file="" # removed by the EXIT trap

die() {
	echo "release_debug: $*" >&2
	exit 1
}

usage() {
	sed -n '5,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run) dry_run=1 ;;
		--help | -h) usage && exit 0 ;;
		*) usage >&2 && exit 2 ;;
		esac
		shift
	done
}

# Prints the tag name for a "X.Y.Z+N" version string.
tag_for_version() {
	local version="$1"
	printf 'debug-v%s-build%s\n' "${version%+*}" "${version#*+}"
}

git_root() { git -C "${root_dir}" "$@"; }

check_preconditions() {
	local tag="$1"
	command -v gh >/dev/null || {
		echo "release_debug: gh is required" >&2
		exit 2
	}
	gh auth status >/dev/null 2>&1 || die "gh is not authenticated (gh auth login)"
	[[ ! -f "${root_dir}/android/key.properties" ]] ||
		die "android/key.properties exists: production-signed build, use the production release path"
	[[ "$(git_root branch --show-current)" == "main" ]] || die "not on branch main"
	[[ -z "$(git_root status --porcelain)" ]] || die "working tree is not clean"
	git_root fetch --quiet origin main || die "cannot fetch origin/main"
	[[ "$(git_root rev-parse HEAD)" == "$(git_root rev-parse origin/main)" ]] ||
		die "HEAD is not equal to origin/main (push or pull first)"
	if git_root rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
		die "tag ${tag} already exists locally"
	fi
	if git_root ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1; then
		die "tag ${tag} already exists on origin"
	fi
}

# Sets aapt2 and apksigner from the newest build-tools directory.
locate_sdk_tools() {
	local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${HOME}/Android/Sdk}}" newest
	newest="$(find "${sdk}/build-tools" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
		sort -V | tail -n 1)"
	[[ -n "${newest}" ]] || {
		echo "release_debug: no Android build-tools below ${sdk}" >&2
		exit 2
	}
	aapt2="${newest}/aapt2"
	apksigner="${newest}/apksigner"
	[[ -x "${aapt2}" && -x "${apksigner}" ]] || {
		echo "release_debug: aapt2/apksigner missing in ${newest}" >&2
		exit 2
	}
}

# Extracts a top-level badging value such as sdkVersion from ${badging}.
badging_value() {
	sed -n "s/^$1:'\([^']*\)'.*/\1/p" <<<"${badging}" | head -n 1
}

# Verifies the dist directory; fills badging, certs and apk_sha.
verify_artifacts() {
	local version="$1" apk name code
	apk="${dist}/raumfreund-${version%+*}-debugsigned.apk"
	[[ -f "${apk}" ]] || die "expected ${apk} was not built"
	(cd "${dist}" && sha256sum -c SHA256SUMS >/dev/null) || die "SHA256SUMS check failed"
	badging="$("${aapt2}" dump badging "${apk}")"
	name="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<<"${badging}")"
	code="$(sed -n "s/^package: .*versionCode='\([^']*\)'.*/\1/p" <<<"${badging}")"
	[[ "${name}" == "${package_id}" ]] || die "unexpected package ${name}"
	[[ "${code}" == "${version#*+}" ]] || die "versionCode ${code} != ${version#*+}"
	grep -q "versionName='${version%+*}'" <<<"${badging}" || die "versionName mismatch"
	if grep -q "name='android.permission.INTERNET'" <<<"${badging}"; then
		die "APK requests android.permission.INTERNET"
	fi
	certs="$("${apksigner}" verify --print-certs "${apk}")" || die "apksigner verify failed"
	grep -q 'CN=Android Debug' <<<"${certs}" || die "APK is not signed with the Android debug certificate"
	apk_sha="$(sha256sum "${apk}" | cut -d' ' -f1)"
}

# Prints the badging permissions in plain words, comma separated.
permission_summary() {
	local out="" p word
	while read -r p; do
		case "${p}" in
		"${package_id}".*) continue ;; # app-internal, not user-facing
		android.permission.RECORD_AUDIO) word="microphone" ;;
		android.permission.VIBRATE) word="vibration" ;;
		*) word="${p}" ;;
		esac
		out+="${out:+, }${word}"
	done < <(sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" <<<"${badging}")
	printf '%s; no Internet permission' "${out:-none}"
}

# Renders the release notes (structure of debug-v0.1.2-build14) to stdout.
write_notes() {
	local version="$1" commit="$2" changelog="$3" apk_name cert_digest
	apk_name="raumfreund-${version%+*}-debugsigned.apk"
	cert_digest="$(sed -n 's/^Signer #1 certificate SHA-256 digest: *//p' <<<"${certs}" | head -n 1)"
	cat <<NOTES
# Raumfreund ${version} — public debug APK

> **Debug build for sideloading at your own risk.** This APK uses Android's
> standard debug certificate. It is not production-signed, not a Google Play
> build, and not intended for store distribution.

${changelog}

Raumfreund works fully offline, stores or transmits no audio, and is not a
calibrated sound-level meter.

## Installation

Download \`${apk_name}\` below and open it on an Android 7.0 or newer device.
Android may ask you to allow installation from this source. Updates install over
an earlier debug release only because all debug releases share one signing
certificate (see the certificate digest below).

## Verification

- Source commit: \`${commit}\`
- Version: \`${version%+*}\` (\`versionCode\` ${version#*+})
- Minimum Android: API $(badging_value minSdkVersion)
- Target Android API: $(badging_value targetSdkVersion)
- APK signature: valid, \`CN=Android Debug\`
- Signing certificate SHA-256: \`${cert_digest}\`
- APK SHA-256: \`${apk_sha}\`
- Permissions: $(permission_summary)

Use the attached \`SHA256SUMS\` file to verify the downloaded APK.
NOTES
}

# Prints the CHANGELOG entries after the previous debug release up to and
# including X.Y.Z, as a Markdown list. One release usually spans several
# versions, so the notes list all of them, not only the newest line.
changelog_since_last_release() {
	local current="$1" previous lines
	previous="$(git_root tag -l 'debug-v*' --sort=-v:refname | head -n 1)"
	previous="${previous#debug-v}"
	previous="${previous%-build*}"
	grep -q -F "* v${current} " "${root_dir}/CHANGELOG.md" ||
		die "CHANGELOG.md has no entry for v${current}"
	lines="$(awk -v prev="* v${previous} " -v cur="* v${current} " '
		index($0, "* v") != 1 { next }
		prev != "* v " && index($0, prev) == 1 { started = 1; next }
		prev == "* v " || started { print }
		index($0, cur) == 1 { exit }
	' "${root_dir}/CHANGELOG.md")"
	[[ -n "${lines}" ]] || lines="$(grep -m 1 -F "* v${current} " "${root_dir}/CHANGELOG.md")"
	printf '## Changes\n\n%s\n' "${lines}"
}

publish() {
	local tag="$1" version="$2" notes="$3"
	git_root tag -a "${tag}" -m "Raumfreund ${version} debug APK" HEAD
	git_root push origin "refs/tags/${tag}"
	if ! gh release create "${tag}" \
		"${dist}/raumfreund-${version%+*}-debugsigned.apk" "${dist}/SHA256SUMS" "${dist}/VERSION" \
		--title "Raumfreund ${version%+*}+${version#*+} – Debug APK" \
		--notes-file "${notes}" --latest --verify-tag; then
		# Without this, the orphaned tag would block every retry with
		# "tag already exists".
		git_root push --quiet origin --delete "refs/tags/${tag}" || true
		git_root tag -d "${tag}" >/dev/null || true
		die "gh release create failed; tag ${tag} removed again, retry later"
	fi
}

main() {
	local version tag commit notes
	parse_args "$@"
	version="$("${root_dir}/tool/bump_version.sh" --current)"
	tag="$(tag_for_version "${version}")"
	check_preconditions "${tag}"
	locate_sdk_tools
	commit="$(git_root rev-parse HEAD)"
	"${root_dir}/tool/build_apk.sh" --commit "${commit:0:12}" || die "build failed"
	verify_artifacts "${version}"
	notes="$(mktemp)"
	trap 'rm -f "${notes_file}"' EXIT
	notes_file="${notes}"
	write_notes "${version}" "${commit}" "$(changelog_since_last_release "${version%+*}")" >"${notes}"
	if [[ ${dry_run} -eq 1 ]]; then
		cat "${notes}"
		echo "release_debug: dry run, would publish ${tag}; nothing tagged or pushed" >&2
		return 0
	fi
	publish "${tag}" "${version}" "${notes}"
	echo "release_debug: published ${tag}"
}

main "$@"
