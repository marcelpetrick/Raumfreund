#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# publish_release.sh – publish verified files as one GitHub Release.
# Usage: tool/publish_release.sh <tag> <notes.md> <dist-dir>
# Exit codes: gh status; 1 missing files; 2 usage/tool unavailable.
set -euo pipefail

[[ $# -eq 3 ]] || {
	echo "usage: $0 <tag> <notes.md> <dist-dir>" >&2
	exit 2
}
command -v gh >/dev/null || {
	echo "gh is required" >&2
	exit 2
}
tag="$1"
notes="$2"
dist="$3"
[[ -s "${notes}" && -d "${dist}" ]] || {
	echo "notes or dist directory missing" >&2
	exit 1
}
mapfile -d '' artifacts < <(find "${dist}" -maxdepth 1 -type f -print0 | sort -z)
[[ ${#artifacts[@]} -gt 0 ]] || {
	echo "no release artifacts in ${dist}" >&2
	exit 1
}
gh release create "${tag}" "${artifacts[@]}" \
	--title "Raumfreund ${tag}" --notes-file "${notes}" --verify-tag
