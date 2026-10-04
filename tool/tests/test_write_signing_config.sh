#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Tests write_signing_config.sh in an isolated temporary signing directory.
# Usage: tool/tests/test_write_signing_config.sh
# Exit codes: 0 passed; 1 assertion/script failure.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="${root_dir}/tool/write_signing_config.sh"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
export RAUMFREUND_SIGNING_DIR="${work}/target"

fail() { echo "not ok - $*" >&2 && exit 1; }
ok() { echo "ok   - $*"; }

if env -u ANDROID_KEYSTORE_BASE64 -u ANDROID_KEYSTORE_PASSWORD \
	-u ANDROID_KEY_ALIAS -u ANDROID_KEY_PASSWORD "${script}" 2>/dev/null; then
	fail "missing secrets accepted"
fi
[[ ! -e "${RAUMFREUND_SIGNING_DIR}/upload-keystore.jks" ]] || fail "partial key"
ok "missing secrets rejected without partial files"

if ANDROID_KEYSTORE_BASE64='!' ANDROID_KEYSTORE_PASSWORD=changeit \
	ANDROID_KEY_ALIAS=raumfreund ANDROID_KEY_PASSWORD=changeit \
	"${script}" 2>/dev/null; then
	fail "invalid base64 accepted"
fi
[[ ! -e "${RAUMFREUND_SIGNING_DIR}/upload-keystore.jks" ]] || fail "invalid key left"
ok "invalid base64 rejected without partial files"

keytool -genkeypair -keystore "${work}/source.jks" -storepass changeit \
	-keypass changeit -alias raumfreund -keyalg RSA -dname 'CN=Raumfreund Test' \
	-validity 1 >/dev/null 2>&1
encoded="$(base64 -w 0 "${work}/source.jks")"
ANDROID_KEYSTORE_BASE64="${encoded}" ANDROID_KEYSTORE_PASSWORD=changeit \
	ANDROID_KEY_ALIAS=raumfreund ANDROID_KEY_PASSWORD=changeit "${script}" >/dev/null
[[ -s "${RAUMFREUND_SIGNING_DIR}/upload-keystore.jks" ]] || fail "key missing"
grep -q '^keyAlias=raumfreund$' "${RAUMFREUND_SIGNING_DIR}/key.properties" ||
	fail "properties missing"
ok "valid keystore and properties written"

"${script}" --remove
[[ ! -e "${RAUMFREUND_SIGNING_DIR}/key.properties" ]] || fail "remove failed"
ok "signing files removed"
