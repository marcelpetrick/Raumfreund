#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# render_screenshots.sh – render the README screenshots of every monitor state
# and of the four UI languages.
#
# Renders the real widgets with the pinned Flutter SDK (Roboto and Material
# Icons, no emulator) for idle, green, yellow, red, Mia hiding, sleeping,
# waking up and an error (overview.png, two rows of four), and for the
# language choice in Settings plus the monitor in English, Croatian and
# Chinese (languages.png, one row). Writes docs/screenshots/<name>.png
# (540x1290 each). Chinese needs a CJK font: RAUMFREUND_CJK_FONT, default
# /usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc (Noto Sans CJK). Pixels
# depend on the SDK's renderer, so re-run after a Flutter update instead of
# comparing files.
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
