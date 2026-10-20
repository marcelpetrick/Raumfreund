<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0005 – Mia sleeps in the background and wakes up on return

- Status: accepted (owner decision 2026-10-20, GitHub issue #7)
- Date: 2026-10-20
- Amends: [ADR 0003](0003-alarm-and-lifecycle-semantics.md) lifecycle rules
  and section 3 of `Raumfreund-VISION.md` ("Kehre ohne automatischen Neustart
  zurück")

## Context

Until now, leaving the app (home button, app switcher, screen lock, another
app in front) stopped the measurement, and returning showed "Bereit". The
teacher had to notice that and tap "Messung starten" again; a measurement
that silently stayed off after a quick look at another app defeats the
purpose of the app. The owner asked for a pause instead: Mia falls asleep
while the app is away and wakes up and keeps measuring when it is back.

Measuring in the background is not an option. It would need a foreground
service of type `microphone` with a permanent notification, Android 14+
forbids starting microphone access from the background anyway, and the
privacy promise is "the microphone is only used while the app is visible".

## Decision

- The app never records in the background. Leaving the app ends the
  recording through the same stop path as before: the recorder is released,
  the keep-screen-on flag is cleared, alarm continuity, the debouncer and
  the star progress are reset. The level history stays (RAM only); its gap
  shows the pause, and no time without samples is counted.
- New controller status `sleeping`: when the app goes `hidden` or `paused`
  while a measurement is `starting` or `measuring`, the session ends in
  `sleeping` instead of `stopped`. A permission grant that arrives while the
  app is not in the foreground also ends in `sleeping` (the user asked for a
  measurement); recording still never starts outside the foreground.
- When the app is visible again (`inactive` or `resumed`) while `sleeping`,
  the controller starts a new session automatically (new session id, the
  permission is checked again; a revoked permission takes the normal
  request/failure path). Android usually revokes a one-time permission by
  ending the process, which makes the return a cold start that shows
  "Bereit" instead. If the app returns while the teardown of the pause is
  still running, the new session starts right after the teardown – unless
  an explicit stop (Settings, About, star shop, applying settings,
  `detached`) arrived meanwhile: that stop wins and the controller ends in
  `stopped`.
- `detached` (no activity any more) stops as before; a sleeping controller
  becomes `stopped`.
- Explicit user actions are unchanged: stop, opening Settings, About or the
  star shop, applying settings, errors and the no-reading watchdog end in
  `stopped`/`error` without an automatic restart. Stop while `sleeping`
  ends in `stopped`.
- The permission dialog keeps its special handling: `hidden`/`paused` while
  the request is pending do not end the session (ADR 0003).
- The session that wakes up is marked `waking` until it measures or ends,
  so the UI can show the wake-up.

### Presentation

- While `sleeping` (and while a waking session prepares) Mia sleeps: closed
  eyes, relaxed ears, slow breathing, a nose bubble, drifting "Z z z" and a
  calm lavender glow. The headline says "Mia schläft – Messung pausiert"
  with a short note that she wakes up when the app is back; while the
  waking session prepares it says "Mia wacht auf …".
- The `sleeping` state itself is rarely seen: it begins after the app has
  left the screen, and the return starts the waking session before the
  next frame. Whether Android's app-switcher thumbnail shows it depends on
  when the system takes it and is not promised. What the teacher sees is
  the wake-up.
- When the waking session measures, Mia wakes up in 2.2 s: she stays asleep
  for the first quarter (so the return visibly starts with a sleeping Mia),
  then the Z fade, she yawns, blinks, stretches and her ears perk up, and
  she shows the mood of the measured zone. The measurement itself runs from
  the start of the animation. A waking session that fails or is stopped
  shows no wake-up; Mia only crossfades. With reduced motion the states
  only crossfade.

## Consequences

- A measurement resumes without a tap after the app comes back, with a gap
  of the time away plus the restart (permission check and `AudioRecord`
  start, typically well under a second).
- A phone call or another app that holds the microphone makes the wake-up
  fail with the existing "Mikrofon belegt" error and its retry button.
- Unit and widget tests cover the controller rules and the presentation
  with fake ports. Behaviour on real devices (home button, app switcher,
  screen lock, split screen, an incoming call) is checked by the owner;
  no emulator tests (owner decision 2026-10-08).
