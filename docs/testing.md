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

## Checking the alarm vibration on a device

The alarm vibrates in three pulses (about 1.1 s) with alarm usage, so it
follows the phone's alarm-vibration setting, also in silent mode.

1. In **Einstellungen**, lower **Rot ab** to about 55 dB, set **Alarm nach**
   to 3 seconds, switch **Vibration** on (optionally **Alarmton** off to feel
   only the vibration) and save.
2. Start the measurement and speak loudly or clap for more than three
   seconds until "Alarm!" appears and Mia hides.
3. Expected: three distinct pulses. If nothing vibrates, check the Android
   setting for alarm vibration (Settings, Sound and vibration, Vibration and
   haptics) and whether the device has a vibrator at all.
4. Restore the thresholds with **Standardwerte**.

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

On 2026-10-07 the emulator ran stably with the host GPU (`-gpu host`); the
crashes above occurred with the software renderer. Results on the Android 16
image (`ForkApi36`):

- With `-no-audio` the emulator microphone delivers digital silence. The
  debug build ended the measurement after about five seconds with the
  headline "Keine Messwerte" and its explanation, which confirms the
  digital-silence rule and the no-reading watchdog end to end.
- With host audio, the release build (`0.6.15+60`, AOT) measured real input
  (about 12 dB, green) for a **30-minute soak**: the same process throughout,
  memory (total PSS) flat between 86.8 and 88.5 MB without growth, a constant
  29 threads, no crash or ANR in logcat, exactly 30 quiet-minute stars, all
  kept in the wallet after stopping, and AudioService logged `rec stop` for
  the app's recording right after **Messung stoppen**.
- A local JIT debug build failed to start after an emulator reboot ("Could
  not prepare isolate"); a fresh install of the AOT release build started
  normally. Published debug releases are AOT release builds signed with the
  debug key (`tool/build_apk.sh`), so they are not affected.

Permission and lifecycle matrix on the same emulator (release build, judged
by screenshots; uiautomator dumps of the Flutter tree went stale and are not
used as evidence):

- Deny once: "Mikrofon nicht erlaubt" with **Erneut versuchen**, which shows
  the system dialog again.
- Deny twice: "Mikrofon dauerhaft gesperrt"; **Einstellungen öffnen** opens
  the Android app settings. After granting there and returning, nothing
  starts by itself. This pass found that the panel then offered no way to
  start; it now also offers **Erneut versuchen**, which starts measuring.
- Background (Home) while measuring: stopped, no restart on return, stars
  kept.
- Twelve rapid taps on the start/stop button end stopped; eleven end
  measuring with live readings. No crash or ANR in logcat.

- Rotating to landscape and back while the permission dialog is open keeps
  the dialog and the waiting state; allowing then starts measuring. Rotating
  while measuring keeps the session in both orientations. One earlier run of
  the dialog case ended with "Keine Messwerte" after allowing, and a retry in
  the same process did too; a repeat of the same steps worked. It is a watch
  item for the device tests, not a confirmed defect.

Emulator testing ends here by owner decision (2026-10-08, AGENTS.md
section 6): the prototype runs and works. A missing vibrator, an occupied
microphone and the rotated-dialog watch item are left to the owner's checks
on real devices. Real-device tests remain open
as listed above.
