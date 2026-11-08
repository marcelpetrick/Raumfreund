#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Checks download page signing notices for debug and non-debug APK names.
# Usage: tool/tests/test_render_index.sh
# Exit codes: 0 passed; nonzero on a failure.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

render() {
	local apk="$1"
	rm -f "${work}"/*.apk
	printf 'apk content\n' >"${work}/${apk}"
	(cd "${work}" && sha256sum "${apk}" >SHA256SUMS)
	printf '1.2.3+45\n' >"${work}/VERSION"
	"${root_dir}/docker/render_index.sh" "${work}" \
		"${root_dir}/docker/index.html.template" "${work}/index.html"
}

render raumfreund-1.2.3-debugsigned.apk
grep -qF 'Debug-signierte Testversion' "${work}/index.html"
grep -qF 'Nicht für Google Play oder den Produktionseinsatz' "${work}/index.html"
grep -qF 'verschiedene Schlüssel' "${work}/index.html"
grep -qF 'raumfreund-1.2.3-debugsigned.apk' "${work}/index.html"

render raumfreund-1.2.3.apk
grep -qF 'nicht als Debug-Version gekennzeichnet' "${work}/index.html"
if grep -qF 'Debug-signierte Testversion' "${work}/index.html"; then
	echo 'A non-debug artifact was incorrectly labelled debug-signed' >&2
	exit 1
fi
if grep -qF '__SIGNING_NOTICE__' "${work}/index.html"; then
	echo 'Signing notice placeholder was not rendered' >&2
	exit 1
fi
echo 'download page signing notices passed'
