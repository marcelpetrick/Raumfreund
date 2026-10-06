<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0003 – Alarm and measurement lifecycle semantics

- Status: accepted; implemented; independent review required before release
- Date: 2026-10-03 (alarm rules amended 2026-10-04 by ADR 0004; alarm delay
  made configurable 2026-10-04; no-reading watchdog added 2026-10-06)

## Context

Alarm continuity crosses asynchronous samples, navigation, Android lifecycle
events, permission dialogs and an alarm sound that the microphone can hear.
Without one ownership model, rapid start/stop actions or stale callbacks can
create duplicate recorders, early alarms or a self-triggering loop.

## Decision

The application controller is the single owner of a measurement session. It
serializes transitions and exposes explicit stopped, permission-pending,
starting, measuring, stopping and error states. Each native recording receives
a monotonically increasing session id; every callback checks both controller
state and id before changing state.

### Lifecycle rules

- Start while anything other than stopped/error is active is ignored or joins
  the in-flight start; it never creates a second recorder.
- Stop invalidates the active id before awaiting idempotent native cleanup.
- Genuine backgrounding, opening Settings/About, stream failure, the
  no-reading watchdog and controller disposal use the same stop path and
  clear alarm continuity.
- Foregrounding and returning from another page never restart automatically.
- The Android permission dialog is tracked as an application-owned request.
  Its temporary activity pause is not treated as genuine backgrounding.
- A granted permission result starts recording only if its request token is
  current and the activity is in the foreground. A result after stop,
  navigation, disposal or replacement is ignored.

### No-reading watchdog

A recorder can run without delivering anything (a stuck `AudioRecord`, a
microphone the system silences without an error). The sparse-reading hint
(ADR 0004) only works while readings still arrive, so the controller also
watches for their absence:

- Once a session is measuring, it must deliver a valid reading within 5 s;
  after that, within 3 s of the previous valid reading. Valid means finite
  and above the native digital-silence floor of -100 dBFS: Android's
  microphone privacy toggle feeds all-zero windows instead of stopping the
  recorder, and no real room is that quiet, so such windows must neither
  look like a calm green room nor earn stars. Short runs of them (for
  example right after `AudioRecord` starts) are simply ignored.
  Otherwise the session ends through the normal stop path with the failure
  `noReadings` ("Messung nicht möglich" with an explanation); start/"Erneut versuchen" begins a new
  session. Readings arrive about every 100 ms, so 3 s are 30 missed windows,
  far beyond scheduling hiccups, and equal to the zone release window: a
  stale zone stays visible no longer than a real one needs to cool down.
  Before the first reading the UI shows "starting" without a zone, never a
  calm state, so the first timeout can be more generous for slow audio
  routing.
- The session ends with an error instead of showing a "no signal" state
  while still measuring: a silent recorder rarely recovers by itself, an
  error clears zone, gauge, Mia's latch and star progress at once, stops
  the recorder and the keep-screen-on flag, and reuses the tested error and
  retry path. A visible-but-running state would need its own rules for
  zone, stars and alarm and could still look calm at a glance.
- While the own alarm output is active, readings are ignored on purpose;
  the watchdog is paused then and does not fire. When the output completes
  (successfully or not) and the active session is measuring, it is armed
  again with the full timeout (5 s if that session has had no valid reading
  yet, else 3 s). A session that is still starting arms it when it reaches
  measuring.
- The watchdog belongs to one session id. Stop, error and dispose cancel
  it before awaiting cleanup, and its callback ends the session only if
  that id is still active and measuring, so it never touches a newer
  session. Cancelling is idempotent.
- Time comes from an injected `TimerScheduler` (`lib/core/scheduler.dart`);
  tests drive it with a fake scheduler on the fake clock.

### Alarm rules

- Phases follow the *confirmed* zone, not the raw per-sample zone: fast
  attack (a zone is entered when it covers 50 % of the last second), slow
  release (it is left when it covers less than 15 % of the last three
  seconds) ([ADR 0004](0004-zone-hysteresis.md)). The first sample after
  start, reset or a gap is adopted immediately and held for one second.
- The phase start is the monotonic timestamp of the first sample of the
  contiguous loud run that led to the confirmation (after a reset or gap:
  the adopted sample). No sample between phase start and confirmation is
  below the phase's zone.
- The phase time is measured from the phase start to the latest sample whose
  raw zone is at least the phase's zone: dips between such samples count, a
  quiet tail after the last one does not. The alarm fires only on such a
  sample, once the phase time reaches the configured alarm delay (default
  10.0 seconds), and only while the
  release window is at least half covered; otherwise with the next such
  sample. While the zone holds, pauses and dips do not reset the phase.
- Samples that stay too sparse to fill the release window (e.g. one per
  second) for more than three seconds are treated like a gap.
- The alarm delay is a user setting (`AppSettings.alarmDelaySeconds`, whole
  seconds 3–60, default 10; owner decision 2026-10-04). The controller
  creates a new alarm machine with that delay for every session, so a change
  takes effect with the next start (opening Settings stops the measurement).
  The machine itself still rejects a delay shorter than the hysteresis window
  (1 s); the 3 s lower bound keeps a margin above it and avoids a nervous
  alarm, the 60 s upper bound keeps the feedback connected to its cause.
- A confirmed yellow-to-red or red-to-yellow transition creates a new phase
  and timer.
- Confirmed green, stop, background, error or a sample gap greater than one
  second resets the phase. Pauses while the zone holds do not. Time with no valid samples is
  never accumulated.
- Exactly one alarm is allowed per uninterrupted phase.
- While the alarm output future is active, incoming readings are ignored:
  they neither advance the alarm state machine nor reach the gauge, the
  timeline or the quiet stars (the microphone hears the own tone). This
  suppression follows the physical output lifetime even if the user stops and
  starts a replacement measurement session before that output completes.
  When output completes, continuity is reset. The next valid sample starts a
  new phase at zero.
- The native output ends after at most 500 ms. If its answer has not arrived
  after 2 s, the controller treats the output as failed and finishes it
  anyway; a later answer is ignored. Without this bound a lost answer would
  keep readings ignored and the no-reading watchdog paused for every later
  session, showing "measuring" with no zone indefinitely.

Mia (the kitty) walks away when the alarm of a confirmed red phase fires.
The controller latches this as `MonitorState.kittyAway`: it survives the
reset after the alarm tone and a drop to yellow, and clears on *settled*
green (a confirmed change, or an adopted green backed by a full window),
stop, reset or error.

The pure alarm machine receives timestamps and levels; it never reads a
real clock, widget state or native API. The controller invokes the alarm port
and applies the asynchronous completion rule.

## Race resolution

The newest user intent wins. Stop increments or clears the session token before
awaiting external calls. Late permission, start, level and stop callbacks
compare their captured token with the current one. Alarm completion additionally
ends controller-wide sample suppression: it may reset a replacement session
that deliberately ignored all samples during the old physical output, but it
must not revive or otherwise mutate a newer stopped intent. Cleanup calls remain
safe when repeated, partially initialized or already completed.

## Consequences

The controller needs deliberate serialization and extensive fake-clock tests.
There is a short, documented discontinuity during the app's own alarm. This is
preferable to counting the alarm sound or suppressing it with an unexplained
delay. Critical changes to these rules require independent review.
