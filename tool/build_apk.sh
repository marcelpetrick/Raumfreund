#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# build_apk.sh – build distributable Android artifacts into dist/.
#
# Usage:   tool/build_apk.sh [--aab] [--commit <sha>]
#
# Builds the release APK (and with --aab the App Bundle for Google Play),
# embeds the git commit via --dart-define=GIT_COMMIT, copies the results to
# dist/raumfreund-<version>.apk/.aab and writes dist/SHA256SUMS.
# Signing: uses android/key.properties when present (see docs/releasing.md);
# without it Gradle falls back to the debug key and the file name gets the
# suffix "-debugsigned" so such an APK can never be mistaken for a release.
#
# Exit codes: 0 success, 1 build failure, 2 usage error.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter="${root_dir}/tool/flutter.sh"
dist="${root_dir}/dist"
build_aab=0
commit=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--aab) build_aab=1 ;;
	--commit) commit="${2:?--commit needs a value}" && shift ;;
	*) echo "usage: $0 [--aab] [--commit <sha>]" >&2 && exit 2 ;;
	esac
	shift
done

if [[ -z "${commit}" ]]; then
	commit="$(git -C "${root_dir}" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
fi
version="$("${root_dir}/tool/bump_version.sh" --current)"
suffix=""
[[ -f "${root_dir}/android/key.properties" ]] || suffix="-debugsigned"
name="raumfreund-${version%+*}${suffix}"
define="--dart-define=GIT_COMMIT=${commit}"

cd "${root_dir}"
rm -rf "${dist}" && mkdir -p "${dist}"
"${flutter}" build apk --release "${define}"
cp build/app/outputs/flutter-apk/app-release.apk "${dist}/${name}.apk"
if [[ ${build_aab} -eq 1 ]]; then
	"${flutter}" build appbundle --release "${define}"
	cp build/app/outputs/bundle/release/app-release.aab "${dist}/${name}.aab"
fi
(cd "${dist}" && sha256sum -- * >SHA256SUMS)
printf '%s\n' "${version}" >"${dist}/VERSION"
echo "Artifacts in ${dist}:" && ls -l "${dist}"
