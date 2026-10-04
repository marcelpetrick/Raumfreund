<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Measurement model

Raumfreund reads approximately 100 ms windows of mono 16-bit PCM through
Android `AudioRecord`. Kotlin calculates RMS and converts it to dBFS. The PCM
buffer is reused or discarded immediately; only a numeric level and session ID
cross into Dart.

The phone microphone has no calibrated sound-pressure reference. Raumfreund
therefore maps the digital result into its 0–130 display scale, applies the
user's bounded calibration correction and labels the result as estimated. It
is useful for room feedback, not occupational safety, legal evidence or
certified acoustic measurement.

Alarm decisions use unsmoothed calibrated values. The gauge uses a separate
display smoother, so animation can never delay or accelerate an alarm. A valid
yellow or red phase must remain continuous for ten seconds. Green, a zone
change, a gap over one second, session stop or the app's own alarm starts a new
phase. Each phase alarms at most once.

The 30-minute timeline stores only timestamp/number pairs in RAM. Quiet stars
are session-local encouragement and are not an acoustic record.
