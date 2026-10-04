#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# docker_check.sh – build the Docker image and verify that it really works.
#
# Usage:   tool/docker_check.sh [--no-build] [--image <name:tag>]
#
# Builds the image (unless --no-build), starts a container on a free port and
# checks: the health endpoint answers, the download page shows the version
# from pubspec.yaml, the linked APK downloads, matches its SHA-256 from
# SHA256SUMS and is a valid APK (contains AndroidManifest.xml and classes.dex).
# The container is always removed afterwards.
#
# Exit codes: 0 all checks passed, 1 a check failed, 2 usage error/no docker.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="raumfreund:local"
build=1
container=""
work="$(mktemp -d)"

cleanup() {
	[[ -n "${container}" ]] && docker rm -f "${container}" >/dev/null 2>&1
	rm -rf "${work}"
}
trap cleanup EXIT

fail() {
	echo "docker check FAILED: $*" >&2
	exit 1
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--no-build) build=0 ;;
		--image) image="${2:?--image needs a value}" && shift ;;
		*) echo "usage: $0 [--no-build] [--image <name:tag>]" >&2 && exit 2 ;;
		esac
		shift
	done
	command -v docker >/dev/null || {
		echo "docker is not installed" >&2
		exit 2
	}
}

build_image() {
	local commit
	commit="$(git -C "${root_dir}" rev-parse --short=12 HEAD)"
	DOCKER_BUILDKIT=1 docker build --build-arg "GIT_COMMIT=${commit}" \
		-t "${image}" "${root_dir}"
}

start_container() {
	container="$(docker run -d -p 127.0.0.1::8080 "${image}")"
	port="$(docker port "${container}" 8080/tcp | head -1 | sed 's/.*://')"
	base="http://127.0.0.1:${port}"
	local attempt
	for attempt in $(seq 1 30); do
		curl -sf "${base}/healthz" >/dev/null && return 0
		sleep 1
	done
	fail "health endpoint did not answer after ${attempt} s"
}

check_download() {
	local version apk expected actual listing="${work}/apk-listing.txt"
	version="$("${root_dir}/tool/bump_version.sh" --current)"
	curl -sf "${base}/" -o "${work}/index.html" || fail "no download page"
	grep -q "Version <strong>${version}</strong>" "${work}/index.html" ||
		fail "download page does not show version ${version}"
	apk="$(sed -n 's/.*href="\([^"]*\.apk\)".*/\1/p' "${work}/index.html" | head -1)"
	[[ -n "${apk}" ]] || fail "no APK link on the download page"
	curl -sf "${base}/${apk}" -o "${work}/${apk}" || fail "APK ${apk} not downloadable"
	curl -sf "${base}/SHA256SUMS" -o "${work}/SHA256SUMS" || fail "no SHA256SUMS"
	expected="$(grep " ${apk}\$" "${work}/SHA256SUMS" | cut -d' ' -f1)"
	actual="$(sha256sum "${work}/${apk}" | cut -d' ' -f1)"
	[[ "${expected}" == "${actual}" ]] || fail "checksum mismatch for ${apk}"
	unzip -l "${work}/${apk}" >"${listing}" || fail "APK is not a readable zip archive"
	grep -q 'AndroidManifest.xml' "${listing}" || fail "APK has no manifest"
	grep -q 'classes.dex' "${listing}" || fail "APK has no classes.dex"
	echo "docker check passed: ${apk} (${version}) sha256 ${actual}"
}

parse_args "$@"
[[ ${build} -eq 1 ]] && build_image
start_container
check_download
