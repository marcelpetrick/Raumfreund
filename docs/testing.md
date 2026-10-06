<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Testing

`./localPipeline.sh` is the authoritative gate. It verifies formatting,
analysis, the 100-line function limit, shell/Python/Kotlin tooling, docs and
workflow YAML, secret and vulnerability scans, Dart/JVM/widget tests, at least
95% line coverage for measurable first-party Dart, Android lint, APK creation,
the privacy gate (`tool/check_privacy.sh`: release-APK permission allowlist
plus a scan for audio-persisting and network APIs, see
[`privacy.md`](privacy.md)) and the Docker package.

Automated tests cover the alarm state machine, measurement/session races,
permission outcomes, stale events, settings migrations, channel payloads,
phone/tablet widgets, Settings and About. Golden assets are deterministic and
use bundled test fonts.

Open device acceptance work:

- microphone permission and settings redirection on two manufacturers;
- occupied/interrupted microphone behavior;
- vibration availability and alarm audibility;
- background/foreground behavior and a 30-minute thermal soak;
- TalkBack, large text and reduced-motion checks on real hardware.

These checks are never claimed from an emulator-only run.

## Emulator smoke tests and a known emulator defect

Manual emulator checks on 2026-10-04/05 (Android 16 / API 36 and Android 14 /
API 34 images, emulator 36.6.11, Linux host) confirmed: in-place update over
earlier debug releases, settings migration and persistence across restarts,
the start of a measurement in the confirmed green zone, and the rendering of
the monitor, Settings and Sternenladen pages.

The emulator process itself (`qemu-system-x86_64-headless`) repeatedly died
with SIGSEGV on this host: around microphone start/stop, while scrolling the
shop page and once during boot before the app was launched, with
`swiftshader_indirect` and with `guest` rendering, with and without host
audio. Core dumps show a smashed host stack, and the crash during boot rules
out the app as the cause. Longer emulator sessions (earning stars, the red
zone, alarms) are therefore not possible on this host; they belong to the
real-device checks above.

On 2026-10-06 the `0.6.3+48` debug build installed over the previous build on
the Android 16 image (`ForkApi36`, headless, `-no-audio`,
`swiftshader_indirect`) and launched to the monitor page with the
Sternenladen total; no app exception was logged. Pressing **Messung starten**
again killed the emulator process itself within two seconds, so the
no-reading watchdog, the quick-star mode and the in-app licence page remain
covered by unit, widget and app tests only and are **open** on devices.
