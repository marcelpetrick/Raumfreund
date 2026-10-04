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
- [ ] README shows design mockups instead of real screenshots (fix below).
- [ ] Five parked agent worktrees under `.claude/worktrees/` hold superseded
  pre-integration work; remove them after owner confirmation.

## Current work packages (2026-10-04)

Each package has an exclusive file area and its own worktree; the coordinator
integrates, bumps the version, runs the full pipeline and commits.

| ID | Package | Agent tier | Status |
| --- | --- | --- | --- |
| A | 1 s zone hysteresis in the alarm machine, confirmed zone for UI/stars, "Mia away" latch, ADR 0004 | Opus (critical logic) | in progress |
| B | Scared Mia in red, runs away after the alarm, walks back when green | Sonnet | in progress |
| C | Stable status-panel height across zones and text scales | Sonnet | in progress |
| D | `tool/release_debug.sh`: one-command debug release with checks | Sonnet | in progress |
| E | Author email on the About page | Haiku | in progress |
| T | 10-minute timeline, 10 s buckets, attack/release envelope, calmer gauge | Opus | in progress |
| S | Configurable alarm delay in Settings (after A) | Opus | waiting for A |
| R | Independent review of A, S and T | Opus | waiting |
| P | README with real screenshots, vision/docs sync, changelog | Coordinator | waiting |
| Q | Publish the next debug release with `tool/release_debug.sh` | Coordinator | waiting |

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
