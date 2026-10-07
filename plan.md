<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Raumfreund – execution plan

This is the restart-safe plan for the Android app. The product specification
is [`Raumfreund-VISION.md`](Raumfreund-VISION.md); the binding workflow is
[`AGENTS.md`](AGENTS.md). Every package lands as an atomic Conventional Commit,
versioned with `tool/bump_version.sh`, after a green `./localPipeline.sh`.

## Product direction (first release)

- One offline Flutter/Dart Android app for phones and tablets. Microphone
  samples are processed in RAM and never stored or transmitted.
- **Mia the kitty** shows the room's state: happy in green, uneasy in yellow,
  **scared** in red (trembling, wide eyes, whimpering). If it stays red until
  the alarm fires, Mia **runs away**; she comes back only once the room is
  confirmed green again.
- **Hysteresis is the key concept** against flicker: zone changes are confirmed
  only after the new zone has held for 1 s; the alarm phase is measured from
  the first sample of the confirmed zone, so the alarm delay stays exact.
- The alarm delay ("how long it may be too loud", default 10 s) is
  configurable in Settings.
- The timeline shows the **last 10 minutes** as one point per 10 s. A
  fast-attack/slow-release envelope lifts peaks immediately and lets them cool
  down slowly; the open point refreshes at most once per second.
- The status panel keeps a stable height, so text does not jump on zone change.
- State is never communicated by colour alone; text, icon and Mia's expression
  always accompany the colour. Reduced motion, large text and TalkBack work.
- App bar actions **Settings** and **About**; opening either stops measurement
  without auto-restart. About lists author, email `mail@marcelpetrick.it`,
  version/build/commit, project link, privacy and licences.

## Verified state (2026-10-07, `0.6.10+55`)

- [x] Domain, controller, native `AudioRecord` recorder, platform channels,
  localized UI, Settings, About, persistence, docs and ADRs 0001–0003 exist.
- [x] GitHub Actions CI and Docker workflows are green on `4755d27` (CI was
  red from `16e84b9` to `0f7529b` because of the JDK pin, fixed in CI1).
- [x] Dependabot PRs #1–#3 are closed; the pinned tooling was updated by hand.
- [x] Debug release `debug-v0.1.2-build14` is GitHub's latest release. Its APK
  checksum matches, the signature is Android Debug
  (`C5:55:29:…:4F:49`, this machine's debug keystore), it requests only
  `RECORD_AUDIO` and `VIBRATE`, and it installs and launches without crashes
  on an Android 16 (API 36) emulator.
- [x] README badges resolve (HTTP 200) and CI/Docker badges show passing.
- [x] README shows real screenshots (`docs/screenshots/`); green is an
  emulator capture, the loud states are rendered from the real widgets.
- [x] Debug release `debug-v0.3.0-build25` (commit `fa5ad56`) is published as
  latest via `tool/release_debug.sh`; checksum verified after download. On an
  Android 16 emulator it updates over 0.2.x in place, starts a measurement and
  shows the confirmed green zone. The emulator process itself crashed
  (SIGSEGV) twice around microphone start/stop, once with `-no-audio` and
  once with audio; a guest app cannot do that, so it is treated as an
  emulator audio-backend defect. Real-device microphone tests remain open.
- [x] All parked agent worktrees, their branches and the old stash are removed
  (W1); the repository has only `main`.

## Completed feature packages

Each package has an exclusive file area and its own worktree; the coordinator
integrates, bumps the version, runs the full pipeline and commits.

| ID | Package | Agent tier | Status |
| --- | --- | --- | --- |
| E | Author email on the About page | Haiku | done, `2056f27` |
| — | Regenerate coverage imports before analysis | Coordinator | done, `0078143` |
| C | Stable status-panel height across zones and text scales | Sonnet | done, `f674e87` |
| D | `tool/release_debug.sh`: one-command debug release with checks | Sonnet | done, `2b726f0` (not yet used for a real release) |
| T | 10-minute timeline, 10 s buckets, attack/release envelope, calmer gauge | Opus | done, `1e54efa` (reviewed) |
| B | Scared Mia in red, runs away after the alarm, walks back when green | Sonnet | done, `9338322` |
| A | Zone hysteresis (fast attack, slow release), "Mia away" latch, ADR 0004 | Opus | done in `0.3.0`, four independent review rounds, judged releasable |
| S | Configurable alarm delay in Settings (3–60 s, default 10 s) | Opus | done in `0.4.0` |
| R | Independent review of A (4 rounds) and T | Opus | done; no blocking findings |
| P | README with real screenshots, vision/docs sync | Coordinator | done in `0.3.1` |
| Q | Publish the next debug release with `tool/release_debug.sh` | Coordinator | done: `debug-v0.4.5-build32` is the latest release |
| — | Run `/reviewBranch` over all changes since `c40ec1a` and fix findings | Coordinator | done: 3 findings plus 4 reviewer notes fixed (`9a490b9`, `cf5e1f0`, `b386f3c`, `605e688`) |
| — | `/updateDependencies` | Coordinator | done: Docker base digests updated (`e7b4533`); everything else current or held on purpose |

### Hysteresis decisions (package A)

Four review rounds with probe tests shaped the rule; details are in
[ADR 0004](docs/adr/0004-zone-hysteresis.md):

- A zone is entered when at least 50 % of the last 1 s is at or above it, and
  left only when it falls below 15 % of the last 3 s (and below 50 % of the
  last 1 s): peaks rise fast and cool down slowly.
- The alarm phase starts at the first sample of the loud run that led to the
  zone, counts dips inside the phase, but not a quiet tail after the last loud
  sample; it fires only on a loud sample, never before the delay.
- Repeated shouts (for example 0.5 s every 3 s) hold red and alarm; sparse
  clicks of 14 % or less do not.
- Sample weights are capped at 200 ms; windows covered less than half decide
  nothing, and a long thin stretch counts as a gap.
- Readings during the app's own alarm tone are ignored entirely.
- Mia leaves after the red alarm and returns only on settled green.

### Accepted hysteresis behaviour (review round 4)

- Readings slower than one per 0.5 s never alarm (stalled recorder; the
  recorder normally delivers every 100 ms). The implemented "measurement
  disturbed" hint makes sparse input visible.
- Pauses of up to about 2.5 s inside a loud phase count towards the delay.
- The countdown may wait just above zero until the next loud sample.

### Latest release check (2026-10-07)

`debug-v0.6.9-build54` (commit `4755d27`) is GitHub's latest release,
published with `tool/release_debug.sh` after green local pipeline, CI and
Docker runs for that exact commit. The downloaded APK matches the local build
and `SHA256SUMS`. It contains A1, S1, N1, L1, L2 and the review fixes F1–F5.
Device tests of these changes are still open (see `docs/testing.md`).

## Star shop (implemented 2026-10-05)

The implemented first-release behaviour is:

- Quiet-minute stars are still earned only while measuring (one per minute
  of confirmed green). Earned stars also go into a **persistent wallet** on
  the device (schema-versioned `shared_preferences`, no account, no network,
  no money, no ads).
- A **shop page** (app bar action, stops measurement like Settings/About)
  lists five cosmetic items from `KittyAccessory`: bow 3, scarf 5, hat 8,
  cushion 10, toy mouse 12 stars. Buying is one-time; owned items can be put
  on and taken off for free. Items never affect zones or alarms.
- Settings gets **"Sterne zurücksetzen"** with a confirmation dialog for the
  teacher; it clears the wallet and the owned items.
- Mia draws one painter layer per equipped item in every mood, including
  while running away.

| ID | Package | Agent tier | Status |
| --- | --- | --- | --- |
| W | Wallet, inventory, persistence, shop controller, star wiring from the monitor | Sonnet | done, `9d73eb9` |
| K1 | Accessory painter layers for Mia | Sonnet | done, `7da90e8` |
| K2 | Shop page, Settings reset, app composition (after W and K1) | Sonnet | done in `0.5.0` |

## Open: automated quality evidence

Work packages for the current acceptance pass (re-planned 2026-10-06 after a
session restart; the earlier A1/N1/I1 agents had stopped):

| ID | Package | Owner | Status |
| --- | --- | --- | --- |
| G | Finish pinned dependency/toolchain update | Coordinator | done, `16e84b9`; local pipeline green, GitHub CI red until CI1 |
| A1 | Suppress readings across alarm-output/session boundaries | Coordinator (finished the stopped agent's diff) | done in `0.5.5` |
| S1 | Owner-confirmed quick-star test mode (5 s) from the parked stash | Coordinator | done in `0.6.0` |
| N1 | Detect a recorder that produces no samples | Opus sub-agent, own worktree | done in `0.6.3`; ends the session with "Messung nicht möglich" after 5 s without a first or 3 s without a further reading |
| L1 | Complete third-party dependency/license inventory | Sonnet sub-agent, docs only | done in `0.6.1`, `docs/third-party-licenses.md` |
| L2 | Show Android library and Material Icons notices in the app licence page (gap found by L1) | Coordinator | done in `0.6.2` |
| R1 | Independent review of A1, S1, N1 and L2 | Opus reviewer (read-only) | done: no blocking finding, 1 major and 4 minor findings (F1–F5) |
| F1 | Major: an all-zero (digitally silenced) microphone reads as calm green and earns stars | Coordinator | done in `0.6.5`: windows at the -100 dBFS floor are invalid, so a muted microphone trips the no-reading watchdog |
| F2/F3 | Error texts name the wrong cause; unused "Keine Messwerte" title vs. docs | Coordinator | done in `0.6.5`: texts name the privacy toggle, docs name the shown headline; error titles stay unused like the existing ones |
| F4 | Quick-star mode is not visible on the monitor | Coordinator | done in `0.6.6`: the star hint reads "Stern-Testmodus: alle 5 ruhigen Sekunden ein Stern" |
| F5 | Dart-side safety timeout for an alarm output that never completes | Coordinator | done in `0.6.7`: 2 s timeout, then the output counts as failed |
| CI1 | GitHub CI red since `16e84b9`: `setup-java` rejects the JDK pin `21.0.12.1+1` (the local pipeline does not run `setup-java`) | Coordinator | done in `0.6.9`: pinned as `21.0.12+101.0.LTS`; CI green on `4755d27` |
| Q2 | Publish the next debug release with `tool/release_debug.sh` | Coordinator | done: `debug-v0.6.9-build54`, checksum verified after download |
| I1/E1 | Emulator acceptance harness, matrix and 30-minute soak | Coordinator | blocked on this host: on 2026-10-06 the emulator again died at microphone start (see `docs/testing.md`); needs another host or real devices |
| D1 | Reconcile plan, testing evidence and release readiness | Coordinator | done in `0.6.10` |
| L3 | Pipeline check: license inventory vs. `pubspec.lock` and `.flutter-version` | Coordinator | done in `0.6.11`: pipeline step `licenses` |
| U1 | Error headline names the cause ("Mikrofon belegt", "Keine Messwerte", …) instead of the generic "Messung nicht möglich"; uses the so far unused error titles | Coordinator | done in `0.6.12` |
| V1 | LinkedIn demo video (owner request 2026-10-07): two 4:5 candidates, max. 30 s, from the emulator with scripted (fake) noise input; Settings, measuring, stars, alarm, shop purchase, rerun with accessory, graph, About | Coordinator | done: `tool/demo/demo_main.dart` (scripted levels, never released); candidates A "Story" (29.9 s) and B "Hook" (28.0 s), 1080x1350, 30 fps, delivered outside the repository; recorded with the emulator's host GPU, which stayed stable where the software renderer crashed |
| W1 | Remove all parked agent worktrees and their branches (owner request 2026-10-07), after archiving their unmerged work | Coordinator | done: 19 worktrees and 20 local branches removed; only `main` remains locally and on GitHub |

- [ ] Emulator tests for grant/deny/permanent deny, settings redirect, dialog
  lifecycle, background stop, rapid start/stop, stale events, stream failures,
  persistence and missing vibrator.
- [ ] Native instrumented/UiAutomator coverage where Flutter tests cannot
  prove Android permission/lifecycle behaviour.
- [ ] Occupied/silenced microphone and interrupted recording on an emulator.
- [ ] Proof that the alarm tone cannot retrigger itself, and that no audio
  files, logs, analytics or network access are produced.
- [ ] 30-minute emulator soak with crash and resource-cleanup inspection.

## Open: owner/external blockers

These cannot be truthfully completed by repository automation alone:

- two physical Android devices from different manufacturers; real-device
  microphone, thermal and endurance tests; five-day RC soak before `v1.0.0`;
- creation and backup of the production keystore and GitHub signing secrets
  (debug releases do not need them);
- GitHub environment/branch protection configuration;
- Play Console app, developer verification, questionnaires, content rating,
  public privacy-policy URL and the decision to publish through Play.

Until then the repository may publish clearly labelled debug APK releases but
must not claim a production-signed release or completed device certification.

## Later ideas (not in the first release)

- No later feature is committed to the first release. New product ideas require
  a separate owner decision and plan entry.
