#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# coverage_gate.sh – fail when Dart line coverage is below a threshold.
#
# Usage:   tool/coverage_gate.sh <lcov.info> <min-percent>
#
# Sums LF (lines found) and LH (lines hit) of all own sources below lib/,
# excluding generated localization code, prints per-file results below the
# threshold and a final line "line coverage: NN.NN % (hit/found, min M %)".
#
# Exit codes: 0 coverage >= threshold, 1 below threshold, 2 usage/missing file.
set -euo pipefail

[[ $# -eq 2 && -f "$1" ]] || {
	echo "usage: $0 <lcov.info> <min-percent>" >&2
	exit 2
}

awk -v min="$2" '
	/^SF:/ { file = substr($0, 4); keep = (file ~ /(^|\/)lib\// && file !~ /lib\/l10n\/generated\//) }
	/^LF:/ && keep { found = substr($0, 4); total_found += found }
	/^LH:/ && keep { hit = substr($0, 4); total_hit += hit }
	/^end_of_record/ && keep && found > 0 && hit / found * 100 < min {
		printf "  %-60s %6.2f %%\n", file, hit / found * 100
	}
	END {
		if (total_found == 0) { print "line coverage: no data"; exit 1 }
		pct = total_hit / total_found * 100
		printf "line coverage: %.2f %% (%d/%d, min %s %%)\n", pct, total_hit, total_found, min
		exit (pct + 1e-9 < min) ? 1 : 0
	}' "$1"
