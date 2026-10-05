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
