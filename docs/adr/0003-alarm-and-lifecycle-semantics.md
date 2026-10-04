<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0003 – Alarm and measurement lifecycle semantics

- Status: accepted; implemented; independent review required before release
- Date: 2026-10-03

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

- The phase start is the monotonic timestamp of the first valid yellow or red
  sample after a reset or zone change.
- The alarm cannot fire before 10.0 seconds. It fires no later than the next
  valid sample at or after that boundary.
- A yellow-to-red or red-to-yellow transition creates a new phase and timer.
- Green, stop, background, error or a sample gap greater than one second resets
  the phase. Time with no valid samples is never accumulated.
- Exactly one alarm is allowed per uninterrupted phase.
- While the alarm output future is active, incoming readings may update a
  clearly marked display but cannot advance or trigger the alarm state machine.
  When output completes, continuity is reset. The next valid sample starts a
  new phase at zero.

The pure alarm machine receives timestamps and zone decisions; it never reads a
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
