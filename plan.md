<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Raumfreund – execution plan

This is the restart-safe implementation plan for the complete Android app.
The product specification is [`Raumfreund-VISION.md`](Raumfreund-VISION.md),
and the binding workflow is [`AGENTS.md`](AGENTS.md). Every completed package
must be integrated as an atomic Conventional Commit, versioned with
`tool/bump_version.sh`, and pass `./localPipeline.sh` before it is committed.

## Product direction

- Raumfreund is one offline Flutter/Dart Android app for phones and tablets.
- It processes microphone samples in RAM and never stores or transmits audio.
- The main character is **Mia the kitty**: happy in green, sad in yellow,
  crying/walking away in red, and returning only after the room is quiet.
- State is never communicated by colour alone; expression, icon and German
  text always accompany the green/yellow/red presentation.
- The main view contains an estimated 0–130 dB gauge, start/stop controls,
  alarm countdown/status, a 30-minute in-memory heartbeat timeline and quiet
  stars. It follows reduced-motion, large-text and TalkBack settings.
- The app bar has two always-visible actions: **Settings** and **About**.
  Opening either stops an active measurement and never auto-restarts it.
- Settings provide validated yellow/red thresholds, calibration, tone,
  vibration, Save, Cancel and Restore Defaults.
- About shows name, version/build/commit, author, project link, privacy and
  open-source licences.
- Native microphone measurement uses a small Kotlin `AudioRecord` module;
  settings use `shared_preferences`.
- Distribution includes a downloadable APK, optional AAB, a reproducible
  Docker APK server, GitHub Releases and an optional GHCR image.

## Verified baseline (2026-10-03)

- [x] Read every Markdown file and audit the repository and dirty Git state.
- [x] Verify the official stable pin: Flutter 3.47.6, bundled Dart 3.13.5,
  official Linux archive SHA-256, JDK 21, Gradle 9.3.1 and Android API 36.
- [x] Confirm committed `main` is a foundation, not a working product:
  value objects/ports exist, but the screen is still a static placeholder.
- [x] Confirm the pinned baseline passes Flutter analysis, 17 tests, the
  current 95% coverage gate (64/64 measured lines) and debug APK build.
- [x] Inventory the unfinished staged/untracked tooling, Docker and release
  changes without discarding them.
- [x] Inventory recoverable agent worktrees containing domain/controller,
  theme/localization, monitor presentation and native Android work.
- [ ] Make the expanded local pipeline fully green. Current failures are a
  parser crash, one YAML lint error, an over-broad secret scan and one npm
  vulnerability finding.
- [ ] Run and pass the Docker image verification after its scripts are fixed.

## Integration status (2026-10-04)

P0 through P4 and the repository-owned parts of P6/P7 are integrated: the
expanded pipeline, domain/controller, native recorder, channel adapters,
localized phone/tablet UI, Settings and About views, documentation, badges,
CI, Docker and signed-release automation are present. Automated Dart coverage
is 97.60%; the 225-test and Android native/lint gates pass locally.

Remaining acceptance is deliberately external: two-manufacturer device tests,
the five-day release-candidate soak, owner-created signing secrets and Play
Console work. A local `-debugsigned` APK can be produced without those secrets;
a public production release cannot truthfully be created until they exist.

## Integration rules for recovered work

- Treat parked worktree code as untrusted until reviewed, rebased onto current
  `main`, formatted, tested and checked against the vision.
- Integrate in dependency order: tooling → architecture/domain → Android and
  Dart infrastructure → UI/composition → integration tests → distribution.
- Do not merge old worktree version numbers. The coordinator performs one new
  monotonic version bump for every integrated atomic commit.
- Do not discard the current dirty work. Turn it into coherent green packages.
- Critical alarm, permission and session-lifecycle logic receives independent
  review after integration and again before release.

## P0 – Stabilise the repository and single pipeline

- [ ] Fix the Kotlin/Bash/Python function-length checker crash and retain
  parser-based 99/100/101-line plus nested-function tests.
- [ ] Make both checkers reject parse/setup errors cleanly without segfaults or
  silent exclusions, including Kotlin Gradle scripts.
- [ ] Fix YAML/action lint failures and cover all workflow/action files.
- [ ] Restrict the working-tree secret scan to repository sources; exclude
  `.git`, SDKs, caches, builds, reports and agent worktrees while still
  scanning history and staged/untracked source files.
- [ ] Resolve or narrowly document the `braces` npm dev-only OSV finding;
  never suppress unrelated vulnerabilities.
- [ ] Ensure `tools` runs before every step that consumes pinned tools.
- [ ] Make CI run every non-Docker local gate and add Kotlin format/static
  analysis plus Android lint when native code is integrated.
- [ ] Keep logs/artifacts redacted, bounded, useful and ignored by Git.
- [ ] Run `./localPipeline.sh --skip docker`, then the Docker step, and record
  only results actually observed.
- [ ] Commit the green tooling package with a patch/build bump and changelog.

## P1 – Architecture and pure domain

- [ ] Add `docs/architecture.md`, already required by `AGENTS.md`.
- [ ] Add ADR 0001 for native `AudioRecord` and why no mic plugin is used.
- [ ] Add an alarm/lifecycle ADR resolving self-alarm interruption, expected
  versus unexpected stops, operation tokens and concurrency.
- [ ] Document dBFS conversion, RMS window, smoothing, calibration, device
  effects and non-professional measurement accuracy.
- [ ] Integrate/review calibration with finite-value validation and clamping.
- [ ] Integrate display smoothing, the 30-minute RAM ring buffer and quiet
  stars with explicit reset/pause semantics.
- [ ] Integrate the pure alarm phase state machine using monotonic timestamps.
- [ ] Test exact thresholds, NaN/infinity, 9.9/10/10.1 seconds, first-sample
  start, green reset, yellow↔red reset, >1-second gaps, one alarm per phase and
  self-alarm quarantine/restart.
- [ ] Keep domain code independent of Flutter, platform channels and wall time.
- [ ] Commit the domain package with a minor/build bump and changelog.

## P2 – Application controllers and persistence

- [ ] Integrate immutable states: stopped, permission pending, starting,
  measuring, alarming, stopping and error.
- [ ] Serialize rapid start/stop/navigation/lifecycle operations.
- [ ] Use increasing session IDs plus operation generations; discard stale
  samples, errors and async completions.
- [ ] Distinguish permission-dialog lifecycle changes from real backgrounding;
  start after grant only while foregrounded.
- [ ] Make cleanup idempotent: cancel subscription, stop native recording,
  release keep-screen-on and reset alarm continuity exactly once.
- [ ] Guard alarm completion so stop/background cannot restart or mutate a
  newer measurement session.
- [ ] Integrate Settings controller Save/Cancel/Defaults semantics.
- [ ] Integrate schema-versioned `shared_preferences` persistence with
  migration and per-field fallback for corrupt/invalid data.
- [ ] Add controller/persistence tests for races, failures and migrations.
- [ ] Commit controllers/persistence with a minor/build bump and changelog.

## P3 – Native Android and platform adapters

- [ ] Recover/review the parked Kotlin implementation; keep recorder, RMS,
  permission, session, alarm, app-info and bridge responsibilities separate.
- [ ] Add only required release permissions (`RECORD_AUDIO`, optional
  vibration); keep `INTERNET` out of the release manifest.
- [ ] Record ~100 ms PCM windows, compute RMS/dBFS, emit numeric levels and
  discard buffers immediately.
- [ ] Detect unavailable/busy/silenced/aborted recording paths and map them to
  the documented protocol.
- [ ] Make start/stop synchronized and idempotent; suppress expected-stop late
  `recordingAborted` events.
- [ ] Stop on real background/destruction and clean recorder/thread/channels.
- [ ] Implement tone/optional vibration, keep-screen-on, settings intent and
  app version/build information.
- [ ] Add JVM tests for RMS, sessions, permissions, channel validation,
  silence policy and alarm duration.
- [ ] Implement defensive Dart channel adapters with finite payload checks,
  typed errors and mocked-channel contract tests.
- [ ] Verify both sides against `docs/platform-channels.md` in one commit.
- [ ] Commit native/platform infrastructure with minor/build bump/changelog.

## P4 – Product UI, Settings and About

- [ ] Integrate German localization; all visible strings live in ARB files.
- [ ] Integrate Material 3 night theme and reusable glow widgets without
  making animation/glow necessary to understand state.
- [ ] Build the monitor page with Mia, estimated gauge, status text/icon,
  countdown, heartbeat timeline, quiet stars and large start/stop action.
- [ ] Add a Settings button to the app bar and a complete Settings view with
  threshold validation, calibration explanation, alarm toggles, Save, Cancel
  and Restore Defaults.
- [ ] Add an About button to the app bar and a complete About view with
  app/build/commit, Marcel Petrick, project URL, privacy, GPL-3.0-only and the
  Flutter/open-source licence page.
- [ ] Stop measurement before opening Settings/About; returning stays stopped.
- [ ] Compose real ports/controllers/repositories in `lib/app/`; replace the
  placeholder `main.dart`.
- [ ] Add app icon/splash consistent with approved Mia mockups.
- [ ] Add semantics, focus order, 48 dp targets, accessible contrast, reduced
  motion and no colour-only information.
- [ ] Test small phone, tablet, landscape and large text without clipping.
- [ ] Add widget/golden tests for zones, permissions/errors, countdown,
  navigation, Settings and About.
- [ ] Commit UI/composition with a minor/build bump and changelog.

## P5 – Integration and device-quality evidence

- [ ] Add emulator tests for grant/deny/permanent deny, settings redirect,
  dialog lifecycle, background start/measure, rapid start/stop, stale events,
  stream failures, persistence and no-vibrator behavior.
- [ ] Add native instrumented/UiAutomator coverage where Flutter tests cannot
  prove Android permission/lifecycle behavior.
- [ ] Test occupied/silenced microphone and interrupted recording.
- [ ] Prove alarm output cannot recursively retrigger from its own sound.
- [ ] Prove no audio files/logs, analytics, network permission or personal
  data are produced.
- [ ] Run a 30-minute emulator soak and inspect crashes/resource cleanup.
- [ ] Keep two-manufacturer real-device and thermal/endurance tests open until
  the owner executes them; emulators are not replacements.

## P6 – Documentation, badges and repository presentation

- [ ] Expand README with status, screenshot/mockup, install/use/build,
  privacy/accuracy caveats, pipeline and release instructions.
- [ ] Add badges in the Cullendula/myLastFmPlayer style: CI, Docker, latest
  release, GPL-3.0-only, Flutter/Dart/Android and measured coverage. They must
  point to real Raumfreund workflows or checked-in configuration.
- [ ] Add `docs/measurement.md`, `privacy.md`, `testing.md`, `building.md`,
  `releasing.md` and `play-store.md`.
- [ ] Add CONTRIBUTING, SECURITY, issue/PR templates and update templates.
- [ ] Add dependency/native licence inventory and ensure the in-app licence
  view covers Flutter/transitive dependencies.
- [ ] Keep changelog, behavior, docs and version synchronized.
- [ ] Run Markdown/link/YAML checks and a fresh-checkout build rehearsal.
- [ ] Optionally apply a proven GitHub About description/topics after owner
  review and authenticated access.

## P7 – Docker, signing and release automation

- [ ] Fix Gradle release signing to read `android/key.properties`; never label
  or publish a debug-signed artifact as a signed release.
- [ ] Test signing config create/remove without printing secrets and fail
  release builds when secrets are missing.
- [ ] Implement/test the release-note and publish scripts currently referenced
  but missing from the untracked workflow.
- [ ] Support SemVer prerelease tags (`alpha`, `beta`, `rc`) and test
  tag/version/changelog/build-number consistency.
- [ ] Build APK/AAB from the exact verified tag with checksums, licences,
  SPDX SBOM and provenance.
- [ ] Make Docker serve one verified APK/download page/checksum/health endpoint
  and pass `tool/docker_check.sh` end to end.
- [ ] Keep PR Docker verification read-only; package/provenance writes exist
  only in guarded publish jobs, and publish the exact verified image.
- [ ] Add weekly maintenance/Dependabot workflows with reviewed updates.
- [ ] Add Play metadata, privacy content and store artwork; keep upload disabled
  until owner credentials exist.

## P8 – Final independent acceptance

- [ ] Independently review alarm timing, lifecycle, permissions, native
  concurrency, privacy and signing; resolve every critical/high finding.
- [ ] Run the complete local pipeline including Docker.
- [ ] Confirm GitHub Actions green on the exact commit and inspect artifacts.
- [ ] Confirm supported Android/API/ABI matrix and limitations in docs.
- [ ] Produce an RC only after automated gates, signing, licences and owner
  device evidence are complete; soak it five working days before `v1.0.0`.

## Owner/external blockers

These cannot be truthfully completed by repository automation alone:

- two physical Android devices from different manufacturers;
- real-device microphone/thermal/endurance testing and five-day RC soak;
- creation/backup of the release keystore and GitHub signing secrets;
- GitHub environment/branch protection configuration if API access is absent;
- Play Console app, developer verification, service account, questionnaires,
  content rating and final production approval;
- public privacy-policy URL and the final decision to publish through Play.

Until those are supplied, the repository may be code-complete and produce a
verified debug-signed internal artifact, but it must not claim a public signed
release or completed device certification.
