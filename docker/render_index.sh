#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# render_index.sh – render the download page for the files in a dist folder.
#
# Usage:   docker/render_index.sh <dist-dir> <template> <output.html>
#
# Picks the single *.apk in <dist-dir>, reads its checksum from SHA256SUMS and
# the version from VERSION, and substitutes __VERSION__, __APK__ and __SHA256__.
# Exit codes: 0 success, 1 missing/ambiguous APK or checksum, 2 usage error.
set -eu

[ $# -eq 3 ] || {
	echo "usage: $0 <dist-dir> <template> <output.html>" >&2
	exit 2
}
dist="$1"
apk="$(cd "${dist}" && ls -- *.apk)"
[ "$(printf '%s\n' "${apk}" | wc -l)" -eq 1 ] || {
	echo "expected exactly one APK in ${dist}" >&2
	exit 1
}
sha="$(grep " ${apk}\$" "${dist}/SHA256SUMS" | cut -d' ' -f1)"
[ -n "${sha}" ] || {
	echo "no checksum for ${apk}" >&2
	exit 1
}
version="$(cat "${dist}/VERSION")"
sed -e "s|__VERSION__|${version}|g" -e "s|__APK__|${apk}|g" -e "s|__SHA256__|${sha}|g" "$2" >"$3"
