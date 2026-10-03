#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# flutter.sh – run the project-pinned Flutter SDK.
#
# Usage:   tool/flutter.sh <flutter arguments…>
#          tool/flutter.sh --ensure      (only install, print SDK path)
#
# Reads the exact stable version from .flutter-version, downloads the official
# Linux release archive into .toolchain/flutter on first use (or when the pin
# changes), verifies it against the SHA-256 pinned in .flutter-sha256 (value
# from Flutter's official releases_linux.json) and then executes it. The global Flutter installation is never used
# or modified. Set RAUMFREUND_FLUTTER_ROOT to use an existing SDK of exactly
# the pinned version instead (e.g. in Docker or CI).
#
# Exit codes: the exit code of flutter, 2 on version mismatch/download errors.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pinned="$(tr -d '[:space:]' <"${root_dir}/.flutter-version")"
pinned_sha256="$(tr -d '[:space:]' <"${root_dir}/.flutter-sha256")"
sdk_dir="${RAUMFREUND_FLUTTER_ROOT:-${root_dir}/.toolchain/flutter}"
base_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux"

installed_version() {
	local version_file="${sdk_dir}/bin/cache/flutter.version.json"
	if [[ -f "${version_file}" ]]; then
		sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p' "${version_file}"
	elif [[ -f "${sdk_dir}/version" ]]; then
		tr -d '[:space:]' <"${sdk_dir}/version"
	fi
}

install_sdk() {
	if [[ -n "${RAUMFREUND_FLUTTER_ROOT:-}" ]]; then
		echo "RAUMFREUND_FLUTTER_ROOT=${sdk_dir} is not Flutter ${pinned}" >&2
		exit 2
	fi
	echo "Installing Flutter ${pinned} into ${sdk_dir} …" >&2
	local archive
	archive="$(mktemp)"
	curl -sSfL -o "${archive}" "${base_url}/flutter_linux_${pinned}-stable.tar.xz" || exit 2
	if ! echo "${pinned_sha256}  ${archive}" | sha256sum --check --quiet; then
		echo "Checksum mismatch for Flutter ${pinned} archive" >&2
		rm -f "${archive}"
		exit 2
	fi
	rm -rf "${sdk_dir}"
	mkdir -p "$(dirname "${sdk_dir}")"
	tar -xJf "${archive}" -C "$(dirname "${sdk_dir}")" || exit 2
	rm -f "${archive}"
	"${sdk_dir}/bin/flutter" --version --suppress-analytics >/dev/null
	"${sdk_dir}/bin/flutter" config --no-analytics >/dev/null
}

if [[ "$(installed_version)" != "${pinned}" ]]; then
	install_sdk
fi

if [[ "${1:-}" == "--ensure" ]]; then
	echo "${sdk_dir}"
	exit 0
fi
exec "${sdk_dir}/bin/flutter" --suppress-analytics "$@"
