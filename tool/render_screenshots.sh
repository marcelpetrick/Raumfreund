#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# render_screenshots.sh – render the README screenshots of every monitor state.
#
# Renders the real MonitorPage widgets with the pinned Flutter SDK (Roboto and
# Material Icons, no emulator) for idle, green, yellow, red, Mia hiding,
# sleeping, waking up and an error, and an overview of all eight. Writes
# docs/screenshots/<state>.png and docs/screenshots/overview.png (540x1290
# each, overview two rows of four). Pixels depend on the SDK's renderer, so
# re-run after a Flutter update instead of comparing files.
#
# Usage:      tool/render_screenshots.sh [OUT_DIR]   (default docs/screenshots)
# Exit codes: 0 rendered; otherwise the exit code of `flutter test`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$(realpath -m "${1:-${root}/docs/screenshots}")"
mkdir -p "${out}"
cd "${root}"
RAUMFREUND_SCREENSHOT_DIR="${out}" tool/flutter.sh test tool/screenshots/screenshots_test.dart
ls -1 "${out}"
