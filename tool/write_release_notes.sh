#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# write_release_notes.sh – render concise notes for a verified release.
# Usage: tool/write_release_notes.sh <tag> <changelog-line> <dist-dir>
# Exit codes: 0 success, 1 missing artifacts, 2 usage.
set -euo pipefail

[[ $# -eq 3 ]] || {
	echo "usage: $0 <tag> <changelog-line> <dist-dir>" >&2
	exit 2
}
tag="$1"
line="$2"
dist="$3"
compgen -G "${dist}/*.apk" >/dev/null || {
	echo "release notes: no APK in ${dist}" >&2
	exit 1
}

printf '# Raumfreund %s\n\n' "${tag}"
printf '%s\n\n' "${line#\* "${tag}" }"
printf '## Installation\n\n'
printf 'Download the APK below and open it on an Android 7.0 or newer device. '
printf 'Android may ask you to allow installation from this source.\n\n'
printf 'Raumfreund works offline, stores no audio and is not a calibrated sound-level meter.\n\n'
printf '## Verification\n\n'
printf '%s\n' "Use \`SHA256SUMS\` to verify downloads. The release also contains an SPDX SBOM and licence notices."
