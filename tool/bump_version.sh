#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# bump_version.sh – bump the app version and record it in the changelog.
#
# Usage:   tool/bump_version.sh <patch|minor|major> "<changelog text>"
#          tool/bump_version.sh --current
#
# Reads `version: X.Y.Z+N` from pubspec.yaml, increments the requested SemVer
# part (lower parts reset to 0) and always increments the build number N, which
# becomes the monotonic Android versionCode. Appends "* vX.Y.Z <text>" to
# CHANGELOG.md (newest line at the bottom). Prints the new version.
#
# Environment: RAUMFREUND_ROOT overrides the repository root (used by tests).
# Exit codes: 0 success, 2 usage error or unparsable version.
set -euo pipefail

root_dir="${RAUMFREUND_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
pubspec="${root_dir}/pubspec.yaml"
changelog="${root_dir}/CHANGELOG.md"

usage() {
	sed -n '5,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
	exit 2
}

current_version() {
	sed -n 's/^version: *\([0-9]*\.[0-9]*\.[0-9]*+[0-9]*\) *$/\1/p' "${pubspec}"
}

next_version() {
	local part="$1" current="$2" major minor patch build
	IFS='.+' read -r major minor patch build <<<"${current}"
	case "${part}" in
	major) major=$((major + 1)) minor=0 patch=0 ;;
	minor) minor=$((minor + 1)) patch=0 ;;
	patch) patch=$((patch + 1)) ;;
	*) usage ;;
	esac
	echo "${major}.${minor}.${patch}+$((build + 1))"
}

main() {
	[[ "${1:-}" == "--current" ]] && {
		current_version
		return 0
	}
	[[ $# -eq 2 && -n "$2" ]] || usage
	local current next
	current="$(current_version)"
	[[ -n "${current}" ]] || {
		echo "No 'version: X.Y.Z+N' line in ${pubspec}" >&2
		exit 2
	}
	next="$(next_version "$1" "${current}")"
	sed -i "s/^version: *${current//./\\.} *\$/version: ${next}/" "${pubspec}"
	printf '* v%s %s\n' "${next%+*}" "$2" >>"${changelog}"
	echo "${next}"
}

main "$@"
