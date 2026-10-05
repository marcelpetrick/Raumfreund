# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# android_sdk.sh – sourced helper that finds the newest Android build-tools.
#
# Usage:   source tool/lib/android_sdk.sh; dir="$(newest_build_tools)" || exit 2
# Looks below ANDROID_HOME, else ANDROID_SDK_ROOT, else ~/Android/Sdk. Prints
# the newest build-tools directory; returns 1 (message on stderr) if none exists.

newest_build_tools() {
	local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${HOME}/Android/Sdk}}" newest
	newest="$(find "${sdk}/build-tools" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
		sort -V | tail -n 1)"
	if [[ -z "${newest}" ]]; then
		echo "no Android build-tools below ${sdk}" >&2
		return 1
	fi
	printf '%s\n' "${newest}"
}
