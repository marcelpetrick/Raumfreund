#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
#
# record_demo.sh – record the storyboard of the demo video on an emulator.
#
# Usage:   tool/demo/record_demo.sh <output-dir>
#
# Needs a booted emulator (1080x2400; the host GPU, `-gpu host`, is stable
# where the software renderer crashed) with the demo build installed:
#   tool/flutter.sh build apk --debug -t tool/demo/demo_main.dart \
#     --dart-define=GIT_COMMIT=$(git rev-parse --short=12 HEAD)
# The app data is cleared first. The script then walks through Settings
# (alarm delay, star test mode, save), a measurement with the scripted noise
# curve, the shop (bow and party hat), a second measurement and About, while
# `screenrecord` captures the screen. Writes <output-dir>/take.mp4 and
# <output-dir>/events.log (seconds since recording start per scene), which
# tool/demo/cut_demo_video.py turns into the 4:5 candidates.
#
# Exit codes: 0 recorded, 1 recording or pulling failed, 2 usage error.
set -uo pipefail

out="${1:-}"
[[ -n "${out}" ]] || {
	echo "usage: $0 <output-dir>" >&2
	exit 2
}
mkdir -p "${out}"
adb="${ANDROID_HOME:-${HOME}/Android/Sdk}/platform-tools/adb"
pkg=it.marcelpetrick.raumfreund

# Prints the UI hierarchy of the current screen.
dump() {
	"${adb}" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
	"${adb}" shell cat /sdcard/ui.xml
}

# tap_text <label> [nth]: taps the nth node whose label contains <label>.
tap_text() {
	local point
	point="$(dump | python3 -I -c '
import re, sys
xml, want, nth = sys.stdin.read(), sys.argv[1], int(sys.argv[2])
node = r"<node [^>]*?text=\"([^\"]*)\"[^>]*?content-desc=\"([^\"]*)\"[^>]*?"
box = r"bounds=\"\[(\d+),(\d+)\]\[(\d+),(\d+)\]\""
hits = [
    ((int(a) + int(c)) // 2, (int(b) + int(d)) // 2)
    for t, desc, a, b, c, d in re.findall(node + box, xml)
    if want in t or want in desc
]
print(*hits[nth] if len(hits) > nth else ())
' "$1" "${2:-0}")"
	[[ -n "${point}" ]] || {
		echo "not found: $1" >&2
		return 1
	}
	# shellcheck disable=SC2086 # "x y" must split into two arguments.
	"${adb}" shell input tap ${point}
}

tap() { "${adb}" shell input tap "$1" "$2"; }
swipe() { "${adb}" shell input swipe "$@"; }

t0=""
mark() {
	echo "$(echo "$(date +%s.%N) - ${t0}" | bc) $1" | tee -a "${out}/events.log"
}

settings_scene() {
	mark settings
	tap 880 202
	sleep 1.8
	swipe 540 1900 540 700 900
	sleep 1.5
	mark delay
	for _ in 1 2 3 4; do
		tap_text "verkürzen"
		sleep 0.3
	done
	sleep 0.8
	swipe 540 1900 540 900 700
	sleep 1.5
	mark quickstars
	tap_text "Schneller Stern-Testmodus"
	sleep 1.2
	swipe 540 1900 540 700 600
	sleep 1.5
	mark save
	tap 540 2200
	sleep 2.5
}

measure_scene() {
	mark run1
	tap 540 1983
	sleep 3.5
	mark graph
	swipe 540 1700 540 900 700
	sleep 3.5
	swipe 540 900 540 1700 700
	mark loud
	sleep 30
}

shop_scene() {
	mark shop
	tap 754 202
	sleep 2
	mark buybow
	tap 540 1273
	sleep 1.0
	tap 792 1342
	sleep 1.2
	tap 540 1273
	sleep 1.5
	swipe 540 1900 540 1200 600
	sleep 1.5
	mark buyhat
	tap_text Kaufen 1
	sleep 1.0
	tap_text Kaufen 0
	sleep 1.2
	tap_text Anlegen 0
	sleep 1.0
	swipe 540 1000 540 1900 600
	sleep 2
}

finale_scene() {
	mark run2
	tap 74 202
	sleep 1.2
	tap 540 1983
	sleep 7
	mark about
	tap 1006 202
	sleep 2.2
	swipe 540 1900 540 900 900
	sleep 2.2
	mark end
	tap 74 202
	sleep 1.5
}

"${adb}" shell am force-stop "${pkg}"
"${adb}" shell pm clear "${pkg}" >/dev/null
"${adb}" shell monkey -p "${pkg}" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 5
"${adb}" shell rm -f /sdcard/demo.mp4
"${adb}" shell screenrecord --bit-rate 20000000 --time-limit 170 /sdcard/demo.mp4 &
recorder=$!
sleep 1
t0="$(date +%s.%N)"
: >"${out}/events.log"
mark idle
sleep 2.5
settings_scene
measure_scene
shop_scene
finale_scene
"${adb}" shell pkill -INT screenrecord
wait "${recorder}"
sleep 2
"${adb}" pull /sdcard/demo.mp4 "${out}/take.mp4" >/dev/null || exit 1
echo "recorded ${out}/take.mp4"
