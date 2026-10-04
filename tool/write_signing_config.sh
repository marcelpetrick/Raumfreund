#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# write_signing_config.sh – materialise the release signing key for a build.
#
# Usage:   tool/write_signing_config.sh            (write files)
#          tool/write_signing_config.sh --remove   (delete them again)
#
# Reads ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS
# and ANDROID_KEY_PASSWORD (GitHub secrets in the release workflow) and writes
# android/upload-keystore.jks plus android/key.properties, both git-ignored.
# Missing values are a release blocker: the script fails loudly instead of
# silently producing a debug-signed "release".
#
# Exit codes: 0 written/removed, 1 a secret is missing or invalid.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
signing_dir="${RAUMFREUND_SIGNING_DIR:-${root_dir}/android}"
keystore="${signing_dir}/upload-keystore.jks"
properties="${signing_dir}/key.properties"
keystore_tmp=""
properties_tmp=""

cleanup_temps() {
	[[ -n "${keystore_tmp}" ]] && rm -f "${keystore_tmp}"
	[[ -n "${properties_tmp}" ]] && rm -f "${properties_tmp}"
	return 0
}
trap cleanup_temps EXIT

escape_property() {
	local value="$1"
	value="${value//\\/\\\\}"
	value="${value// /\\ }"
	value="${value//:/\\:}"
	value="${value//=/\\=}"
	printf '%s' "${value}"
}

[[ $# -le 1 && ($# -eq 0 || "$1" == "--remove") ]] || {
	echo "usage: $0 [--remove]" >&2
	exit 2
}

if [[ "${1:-}" == "--remove" ]]; then
	rm -f "${keystore}" "${properties}"
	exit 0
fi

missing=()
for name in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
	[[ -n "${!name:-}" ]] || missing+=("${name}")
done
if [[ ${#missing[@]} -gt 0 ]]; then
	echo "RELEASE BLOCKER: signing secrets missing: ${missing[*]} (see docs/releasing.md)" >&2
	exit 1
fi
for name in ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
	[[ "${!name}" != *$'\n'* && "${!name}" != *$'\r'* ]] || {
		echo "RELEASE BLOCKER: ${name} contains a line break" >&2
		exit 1
	}
done

umask 077
mkdir -p "${signing_dir}"
keystore_tmp="$(mktemp "${keystore}.tmp.XXXXXX")"
properties_tmp="$(mktemp "${properties}.tmp.XXXXXX")"
printf '%s' "${ANDROID_KEYSTORE_BASE64}" | base64 --decode >"${keystore_tmp}" || {
	echo "RELEASE BLOCKER: ANDROID_KEYSTORE_BASE64 is not valid base64" >&2
	exit 1
}
keytool -list -keystore "${keystore_tmp}" -storepass "${ANDROID_KEYSTORE_PASSWORD}" \
	-alias "${ANDROID_KEY_ALIAS}" >/dev/null || {
	echo "RELEASE BLOCKER: keystore password or alias is invalid" >&2
	exit 1
}
{
	printf 'storeFile=upload-keystore.jks\n'
	printf 'storePassword=%s\n' "$(escape_property "${ANDROID_KEYSTORE_PASSWORD}")"
	printf 'keyAlias=%s\n' "$(escape_property "${ANDROID_KEY_ALIAS}")"
	printf 'keyPassword=%s\n' "$(escape_property "${ANDROID_KEY_PASSWORD}")"
} >"${properties_tmp}"
mv "${keystore_tmp}" "${keystore}"
keystore_tmp=""
mv "${properties_tmp}" "${properties}"
properties_tmp=""
echo "signing config written"
