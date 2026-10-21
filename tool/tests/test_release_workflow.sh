#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# Tests that every workflow job using the Android signing secrets names the
# "release" environment: GitHub hands environment secrets only to jobs that
# declare the environment, and the secrets are stored there (docs/releasing.md).
# Without it the first production release fails while writing the key.
# Usage: tool/tests/test_release_workflow.sh
# Exit codes: 0 passed; 1 assertion failure or missing project venv.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python="${root_dir}/.toolchain/venv/bin/python"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

fail() { echo "not ok - $*" >&2 && exit 1; }
ok() { echo "ok   - $*"; }

[[ -x "${python}" ]] || fail "project venv missing (run tool/install_tools.sh)"

# Prints "<file>: <job>" for every job that reads ANDROID_* secrets without
# environment "release"; exits 1 if there is any.
check() {
	"${python}" -I - "$@" <<'EOF'
import sys
import yaml

bad = []
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as handle:
        workflow = yaml.safe_load(handle)
    for name, job in (workflow.get("jobs") or {}).items():
        uses_secrets = "secrets.ANDROID_" in yaml.safe_dump(job)
        environment = job.get("environment")
        if isinstance(environment, dict):
            environment = environment.get("name")
        if uses_secrets and environment != "release":
            bad.append(f"{path}: {name}")
print("\n".join(bad))
sys.exit(1 if bad else 0)
EOF
}

out="$(check "${root_dir}"/.github/workflows/*.yml)" ||
	fail "jobs read signing secrets without the release environment: ${out}"
ok "every job with signing secrets names the release environment"

grep -q 'secrets.ANDROID_KEYSTORE_BASE64' "${root_dir}/.github/workflows/release.yml" ||
	fail "release workflow no longer reads the signing secrets"
ok "release workflow reads the signing secrets"

# The check must catch a job that lost its environment.
sed '/^    environment: release$/d' "${root_dir}/.github/workflows/release.yml" \
	>"${work}/release.yml"
if out="$(check "${work}/release.yml")"; then
	fail "missing environment not detected"
fi
[[ "${out}" == *": build"* ]] || fail "unexpected report: ${out}"
ok "a signing job without the environment is reported"
