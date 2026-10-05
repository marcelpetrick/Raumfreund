<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0004 – Zone hysteresis: fast attack, slow release

- Status: accepted (owner decision 2026-10-04); independent review required
  before release
- Date: 2026-10-04
- Amends: [ADR 0003](0003-alarm-and-lifecycle-semantics.md) alarm rules

## Context

Levels arrive every ~100 ms and were classified individually. A level hovering
around a threshold flipped the zone several times per second; the traffic light
and Mia flickered, and every flip restarted the 10-second phase, so a room that
was clearly too loud might never alarm.

Earlier drafts failed review:

- "Confirm a zone held for 1 s" and "confirm the highest zone of a 1 s window
  that differs from the confirmed zone": one sample of the confirmed zone ended
  the window, so loud rooms with short dips stayed green; mixing both sides of
  the confirmed zone let a mostly green room turn red; backdating to the window
  start could begin a phase on a green sample.
- A symmetric 1 s sliding window (enter 50 %, leave 25 %): burst/pause rhythms
  such as 1.2 s loud / 0.8 s quiet or 0.6 s loud / 1.4 s quiet flickered about
  once per second and never alarmed; a delayed sample weighed its whole
  preceding interval (a stall plus one sample flipped the zone).

Owner intent: "peak noise goes up fast, but needs time to cool down".

## Decision

`ZoneDebouncer` (pure Dart, no clock) decides the confirmed zone C from two
sliding windows:

- Each sample covers the time since the previous sample of its run (the
  recorder's level describes the window ending at the sample), capped at
  200 ms (2× nominal). `share_W(L)` is the share of the *covered* part of
  window W covered by samples with raw zone `>= L`; a window is usable once at
  least half of it is covered.
- Attack window A = last 1 s (`holdTime`); release window R = last 3 s
  (`releaseTime`). Only R's samples are kept in memory.
- A zone L *holds* if `share_R(L) >= 15 %` or `share_A(L) >= 50 %`; green
  always holds.
- Up (fast, A usable): the highest zone Z above C with `share_A(Z) >= 50 %` is
  confirmed with the next sample whose raw zone is `>= Z`.
- Down (slow, R usable): if C does not hold, the target is the highest lower
  zone that holds (yellow when the room is still yellow, else green). Yellow is
  confirmed with the next yellow sample, green at once.
- Otherwise C is kept and its phase continues.
- The first sample after start, reset or a gap (more than 1 s, or a timestamp
  going backwards) is adopted immediately and held for 1 s (no decisions
  before).
- Phase start of a newly confirmed zone Z: the first sample of the current
  contiguous run of raw samples in Z's range (`>= Z` going up; yellow going
  down from red). Because the confirming sample itself must be in that range,
  every sample from phase start to confirmation is `>= Z`, and the alarm can
  never fire before `alarmDelay` of such samples.
- Phase time runs from the phase start to the latest sample whose raw zone is
  `>= Z`; the alarm fires only on such a sample. Dips inside the phase count,
  a quiet tail does not (8 s of red followed by silence never alarms).
- Thin data: if the release window stays less than half covered for more than
  `releaseTime` while samples continue (e.g. one sample per second, each
  weighing only 200 ms), this counts as a gap and the current sample is
  adopted. The alarm never fires while the release window is unusable
  (`ZoneDecision.usable`).
- The leave share 15 % lies between a quiet room with clicks (7 green : 1 red,
  at most 13.3 % over 3 s, must become green) and the worst 3 s alignment of
  0.6 s bursts every 2 s (20 %, must stay loud).
- Owner decision 2026-10-04: repeated shouts (0.5 s every 3 s) may hold red
  and alarm, because a classroom with a shout every 3 s is loud. The duty
  needed to *hold* a zone after a loud period (worst 3 s alignment at 100 ms
  samples) is:

  | Duty after a loud period | Minimum 3 s share | Result |
  | --- | --- | --- |
  | Clicks 1 in 8 (12.5 %) | 10 % | leaves |
  | Clicks 1 in 7 (14.3 %) | 13.3 % | leaves |
  | 0.4 s every 3 s (13.3 %) | 13.3 % | leaves |
  | Clicks 1 in 6 (16.7 %) | 16.7 % | holds |
  | 0.5 s every 3 s (16.7 %) | 16.7 % | holds, alarms |
  | 0.6 s every 2 s (30 %) | 20 % | holds, alarms |

  Clicks of at most ~14 % never hold a zone; from ~15 % on they hold it after
  a loud period. Entering from green always needs 50 % of one second.
- `AlarmStateMachine` drives phases from the confirmed zone and rejects
  `alarmDelay < holdTime` (a confirmation may lie up to one attack window after
  the phase start). The Settings range for the delay starts at 3 s; that is
  added separately.
- `AlarmSnapshot.zone` is the confirmed zone; the controller uses it for the UI
  and quiet stars. While the own alarm tone plays, the controller ignores
  readings completely (no gauge, timeline or star update).
- Mia: `MonitorState.kittyAway` is set when the alarm of a confirmed red phase
  fires and cleared on *settled* green, stop, reset or error. A confirmed
  change is settled; an adopted zone (after the reset that follows the alarm
  tone, or after a gap) settles once a usable release window shows it as the
  highest holding zone. A single green sample after the tone cannot bring Mia
  back.

## Expected behaviour (covered by tests)

Times assume the default alarm delay of 10 s; the delay is configurable
(3–60 s, owner decision 2026-10-04, see ADR 0003) and shifts the alarm times
accordingly.

| Pattern | Result |
| --- | --- |
| Steady green → red | red after 0.5 s; alarm 10.0 s after first red sample |
| Steady red → green or yellow | changes after about 2.5 s |
| Red 1.2/0.8 s, 1/1 s, 0.6/1.4 s, 40 % at 1.25 s | red, at most 2 changes per minute, alarm 10 s after the first burst |
| Red 0.8 s / green 0.2 s | red, alarm 10 s after the red run start |
| Green/yellow alternating per sample | yellow; yellow alarm |
| Confirmed yellow, 7 green : 1 red | green after about 2.8 s, never red |
| Red, 0.9 s green, steady yellow from 2.9 s | alarm not before 12.9 s |
| Yellow/red flicker from green | red |
| Confirmed red, yellow/red flicker | stays red, one alarm at 10 s |
| Confirmed yellow, 1 red : 2 yellow | stays yellow, yellow alarm at 10 s |
| 0.6 s stall + one red sample | stays green |
| Red phase, 0.8 s stall + one green sample | red phase continues |
| Red 8 s, then silence | no alarm; phase time frozen at 8 s; green after 2.5 s |
| Red 3 s, then 1 in 6 clicks | stays red; alarm on the first click at or after 10 s |
| 0.5 s shouts every 3 s from green | red; alarm on a shout sample (15.1 s) |
| Red until 5 s, then green every 1 s | no alarm; green once treated as a gap |

## Consequences

- Entering a zone is visible after about 0.5 s; cooling down takes about 2.5 s
  of quiet. A pause of up to ~2.4 s inside a loud phase does not reset it and
  counts once loud samples resume, so the alarm means "the configured delay
  (default 10 s) of a loud room", not that long of strictly loud samples; it can fire as soon as a loud sample
  follows such a pause.
- With sparse samples (stalled recorder) no alarm fires at all.
- The first sample after start, reset or a gap holds its zone for 1 s even if
  the room changes immediately (accepted).
- A fast rise can step green → yellow → red within about 0.2 s, because yellow
  reaches 50 % slightly before red does (accepted, cosmetic).
- The alarm delay can no longer be configured below the attack window. The
  user-selectable range (3–60 s) starts well above it.
