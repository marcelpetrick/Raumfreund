#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# check_secrets.sh – scan Git history and the source working tree with gitleaks.
#
# Usage: tool/check_secrets.sh
# Exit codes: gitleaks status; 2 when the pinned tool is unavailable.
#
# The directory scan receives only tracked and non-ignored untracked files.
# SDKs, build output, reports, caches and agent worktrees are intentionally not
# copied, avoiding false findings and multi-gigabyte scans of generated data.
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gitleaks="${root_dir}/.toolchain/bin/gitleaks"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

[[ -x "${gitleaks}" ]] || {
	echo "error: pinned gitleaks is missing; run tool/install_tools.sh" >&2
	exit 2
}

"${gitleaks}" git --no-banner --redact "${root_dir}"
git -C "${root_dir}" ls-files --cached --others --exclude-standard -z |
	while IFS= read -r -d '' path; do
		[[ -e "${root_dir}/${path}" ]] && printf '%s\0' "${path}"
	done |
	tar -C "${root_dir}" --null -cf - --files-from=- |
	tar -xf - -C "${work}"
"${gitleaks}" dir --no-banner --redact "${work}"
