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

## Verified state (2026-10-04, `0.1.3+15`, commit `c40ec1a`)

- [x] Domain, controller, native `AudioRecord` recorder, platform channels,
  localized UI, Settings, About, persistence, docs and ADRs 0001–0003 exist.
- [x] GitHub Actions CI and Docker workflows are green on `c40ec1a`.
- [x] Dependabot PRs #1–#3 are closed; the pinned tooling was updated by hand.
- [x] Debug release `debug-v0.1.2-build14` is GitHub's latest release. Its APK
  checksum matches, the signature is Android Debug
  (`C5:55:29:…:4F:49`, this machine's debug keystore), it requests only
  `RECORD_AUDIO` and `VIBRATE`, and it installs and launches without crashes
  on an Android 16 (API 36) emulator.
- [x] README badges resolve (HTTP 200) and CI/Docker badges show passing.
- [ ] README shows design mockups instead of real screenshots (package P).
- [ ] Five parked agent worktrees under `.claude/worktrees/` hold superseded
  pre-integration work; remove them after owner confirmation.

## Current work packages (status 2026-10-04 evening, `0.2.1+22`)

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
| S | Configurable alarm delay in Settings (minimum 3 s, needs A) | Opus | not started |
| R | Independent review of A (4 rounds) and T | Opus | done; no blocking findings |
| P | README with real screenshots, vision/docs sync | Coordinator | open |
| Q | Publish the next debug release with `tool/release_debug.sh` | Coordinator | open |
| — | Run `/reviewBranch` over all changes since `c40ec1a` and fix findings | Coordinator | open |

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
  recorder normally delivers every 100 ms). A "measurement disturbed" hint is
  a possible follow-up.
- Pauses of up to about 2.5 s inside a loud phase count towards the delay.
- The countdown may wait just above zero until the next loud sample.

## Open: automated quality evidence

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

- **Star shop for Mia.** Quiet-minute stars become a persistent local balance
  (device-only, no account, no money, no ads). Kids spend stars on cosmetic
  items for Mia: bow, hat, scarf, cushion, toy mouse, stage lights. Concept:
  a pure `StarWallet` domain object with schema-versioned persistence, a
  fixed local catalog with prices, an "owned/equipped" inventory, and painter
  layers in the kitty renderer for each item. Open questions: should stars
  survive app restarts and days, can a teacher reset them, and is spending
  allowed during measurement? Needs an owner decision before planning.
