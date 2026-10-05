<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Privacy

Raumfreund processes microphone samples locally in RAM to calculate a numeric
level. It never stores or transmits audio. It has no accounts, analytics, ads
or tracking, and its release manifest requests no Internet permission.

Persisted data is limited to the user's thresholds, calibration correction,
alarm delay, alarm-sound choice, vibration choice and a settings schema
version. The star shop
additionally stores the star balance and the names of the bought and worn
Kitty accessories (for example `bow`), only on the device, as one snapshot
with a schema version; the teacher can delete it with "Sterne
zurücksetzen". Numeric history and the level readings disappear when the
process exits. Logs contain neither audio
content nor personal data.

Android microphone permission is requested only when measurement starts. A
denial leaves the app usable; a permanent denial offers a shortcut to Android's
app settings. Opening any secondary app view stops active measurement.

## What is proven automatically

`tool/check_privacy.sh` (pipeline step `privacy`, run by `./localPipeline.sh`
and the CI Android job on every commit) checks:

- the **release APK** (`flutter build apk --release`) with `aapt2 dump
  badging`: only `RECORD_AUDIO`, `VIBRATE` and AndroidX's
  `<package>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` are allowed. `INTERNET`,
  storage and network-state permissions and Wi-Fi, telephony, Bluetooth, NFC
  or location features fail the build. The debug APK is not checked because
  Flutter's debug manifest adds `INTERNET` for hot reload;
- **Kotlin and Dart sources** for audio-persisting or network APIs
  (`MediaRecorder` instances, `MediaMuxer`, file output streams, `java.net`,
  sockets, OkHttp, `HttpClient`, `package:http`, file writes). There is no
  allowlist: the single legitimate hit class, `MediaRecorder.AudioSource`
  constants for `AudioRecord`, is excluded by a narrow pattern;
- the `dependencies:` section of `pubspec.yaml` for network, analytics,
  crash-reporting and advertising packages (`http`, `dio`, `firebase_*`,
  `sentry*`, `*analytics*`, ...).

## What remains manual

The scans are pattern based and cannot prove the absence of every possible
data flow, for example through a future transitive plugin dependency or
reflection. Reviewers must still read dependency updates, and the claim that
samples are only held in RAM rests on code review and the unit tests, not on
the gate.

Security or privacy reports should follow [`../SECURITY.md`](../SECURITY.md).
