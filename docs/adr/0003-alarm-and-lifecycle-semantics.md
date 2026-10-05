<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0003 – Alarm and measurement lifecycle semantics

- Status: accepted; implemented; independent review required before release
- Date: 2026-10-03 (alarm rules amended 2026-10-04 by ADR 0004; alarm delay
  made configurable 2026-10-04)

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
- Genuine backgrounding, opening Settings/About, stream failure and controller
  disposal use the same stop path and clear alarm continuity.
- Foregrounding and returning from another page never restart automatically.
- The Android permission dialog is tracked as an application-owned request.
  Its temporary activity pause is not treated as genuine backgrounding.
- A granted permission result starts recording only if its request token is
  current and the activity is in the foreground. A result after stop,
  navigation, disposal or replacement is ignored.

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
  timeline or the quiet stars (the microphone hears the own tone).
  When output completes, continuity is reset. The next valid sample starts a
  new phase at zero.

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
awaiting external calls. Late permission, start, level, alarm-completion and
stop callbacks compare their captured token with the current one. Cleanup calls
remain safe when repeated, partially initialized or already completed.

## Consequences

The controller needs deliberate serialization and extensive fake-clock tests.
There is a short, documented discontinuity during the app's own alarm. This is
preferable to counting the alarm sound or suppressing it with an unexplained
delay. Critical changes to these rules require independent review.
