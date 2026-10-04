<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Privacy

Raumfreund processes microphone samples locally in RAM to calculate a numeric
level. It never stores or transmits audio. It has no accounts, analytics, ads
or tracking, and its release manifest requests no Internet permission.

Persisted data is limited to the user's thresholds, calibration correction,
alarm-sound choice, vibration choice and a settings schema version. Numeric
history and stars disappear when the process exits. Logs contain neither audio
content nor personal data.

Android microphone permission is requested only when measurement starts. A
denial leaves the app usable; a permanent denial offers a shortcut to Android's
app settings. Opening any secondary app view stops active measurement.

Security or privacy reports should follow [`../SECURITY.md`](../SECURITY.md).
