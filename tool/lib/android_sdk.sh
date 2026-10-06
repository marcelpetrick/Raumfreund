# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# android_sdk.sh – sourced helper that finds the pinned Android build-tools.
#
# Usage:   source tool/lib/android_sdk.sh; dir="$(pinned_build_tools)" || exit 2
# Looks below ANDROID_HOME, else ANDROID_SDK_ROOT, else ~/Android/Sdk. Prints
# build-tools 36.0.0; returns 1 (message on stderr) if it is absent.

android_build_tools_version="36.0.0"

pinned_build_tools() {
	local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${HOME}/Android/Sdk}}"
	local pinned="${sdk}/build-tools/${android_build_tools_version}"
	if [[ ! -d "${pinned}" ]]; then
		echo "Android build-tools ${android_build_tools_version} missing below ${sdk}" >&2
		return 1
	fi
	printf '%s\n' "${pinned}"
}
