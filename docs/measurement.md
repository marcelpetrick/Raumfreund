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
display smoother, so animation can never delay or accelerate an alarm.

Zones use a fast-attack, slow-release hysteresis
([ADR 0004](adr/0004-zone-hysteresis.md)). Each sample is classified (a value
exactly on a limit belongs to the higher zone) and weighted with the time since
the previous sample, capped at 200 ms so that a delayed sample cannot stand for
a whole stall. A zone is entered when at least 50 % of the covered part of the
last second was at or above it, and left only when less than 15 % of the last
three seconds was; a window counts only once at least half of it is covered.
Noise peaks therefore show up within about 0.5 s, while a room needs about
2.5 s of quiet to cool down. Bursts with pauses (e.g. 0.6 s loud every 2 s, or 0.5 s shouts every 3 s),
a level hovering around a limit or short dips keep the zone and still alarm; a
quiet room with occasional clicks (one in eight samples) becomes green. The
first sample after start, reset or a gap over one second is adopted immediately
and held for one second.

A yellow or red phase is measured from the first sample of the contiguous loud
run that led to its confirmation to the latest sample that is still at least
as loud as the phase's zone. Pauses between loud samples count (a classroom
with a shout every few seconds is loud), but a quiet tail does not: 8 s of
shouting followed by silence never alarms. The alarm fires only on a loud
sample, 10 s or more after the phase start. Samples that arrive too sparsely to
fill the three-second window (e.g. one per second) for more than three seconds
are treated like a gap and never trigger an alarm. Confirmed green, a confirmed zone change, a gap
over one second, session stop or the app's own alarm starts a new phase. Each
phase alarms at most once. While the alarm tone plays, readings are ignored:
the displayed zone stays frozen and gauge and timeline do not show the tone.

When the alarm of a red phase fires, Mia walks away. She stays away, even if
the room drops to yellow, until green is settled (confirmed by the hysteresis,
or, right after the alarm tone, backed by at least 1.5 s with less than 15 %
above green) or the measurement stops, resets or fails.

The timeline covers the last 10 minutes and stores only timestamp/number pairs
in RAM. Every raw level feeds a peak envelope with instant attack and a 4 s
exponential release, so peaks show at once and cool down slowly. The chart
keeps one point per 10 s bucket (the mean of the envelope, at most 60 points);
the open bucket is shown as a live point refreshed at most once per second.
The gauge uses the same idea with a 100 ms attack and a 1 s release. Chart
colour shares describe these smoothed points, not the alarm's confirmed zone.
Quiet stars are session-local encouragement and are not an acoustic record.
