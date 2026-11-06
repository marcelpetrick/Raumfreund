<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Raumfreund – execution plan

This is the restart-safe plan for the Android app. The product specification
is [`vision.md`](vision.md); the binding workflow is
[`AGENTS.md`](../AGENTS.md). Every package lands as an atomic Conventional Commit,
versioned with `tool/bump_version.sh`, after a green `./localPipeline.sh`.

## Active: Flocke redesign and public debug release (2026-11-06)

Verdict: make Flocke unmistakably a cute husky, with matching natural blue
eyes and dog-specific movements, while preserving Mia's cuddly character and
the existing measurement, alarm and sleep behavior. The owner explicitly
requested a minor feature-version bump and a public debug release. Google Play
publication remains deferred.

The owner found the first implementation too cat-like and requested new
visual ideas, their documentation as an intermediate step, a review of those
ideas, and a more suitable dance. The original issue #17 concept sheets are
references, not a constraint to keep different-coloured eyes. Siberian huskies
can naturally have blue or brown eyes; matching blue eyes are the chosen design.

| Work | Owner | Status |
| --- | --- | --- |
| Review existing artwork, dance, source and natural husky features | Coordinator and reviewers | done |
| Generate, compare and review new design ideas | Coordinator and reviewer | done; mood sheet selected, play sheet informs movement |
| Save concepts and decisions in the repository and commit | Coordinator | included in this commit |
| Implement selected appearance, dog behavior and dance with tests | Art/UI agents and coordinator | planned |
| Independent review, full gate, minor version bump, push and verify CI | Coordinator/reviewer | planned |
| Publish and verify public debug APK from the checked commit | Coordinator | planned |
| Check visual design, dance, accessibility and persistence on a real device | Owner | open after release |

Design decision after independent review: use the first sheet's broad nose,
panting smile, sturdy paws and full tail; take the second sheet's play bow and
wag as movement ideas. Avoid relying on an upright paw pose alone, which can
still look feline. The illustrations are concepts, not final raster assets.

Design criteria: clearly canine muzzle and nose, rounded puppy proportions,
upright husky ears, full tail, two matching blue eyes, matching the warm neon
visual style; make happy tail wag, alert ears and playful paws feel like a dog.
Keep the stage and toy still during Flocke's dance, respect reduced motion and
keep all accessories visible. Mia's existing behaviour remains unchanged.

Before each commit update this plan, bump the version with `tool/bump_version.sh`
and pass the complete local gate. The intermediate design commit uses a patch
bump; the implemented feature uses a minor bump. Verify GitHub checks for the
release commit, preview and publish only with `tool/release_debug.sh`, then
verify the downloaded APK, checksum, signing certificate and source commit.
Stop and fix failures. Rollback is a revert; the previous debug release remains
available. Real-device checks remain open and no production signing is implied.

## Active: post-release review and lifecycle fix (2026-11-06)

Verdict: correct the confirmed detached-during-permission race and verify the
Flocke selection flow end to end. The owner requested a review of the current
code, focused on the new Flocke work, fixes for confirmed issues, updates to this plan and AGENTS.md, and a public debug release. Issue #17
remains open. The owner also asked to verify quick-star mode for testing Flocke
on a phone.

The current `0.10.0+101` debug release is `debug-v0.10.0-build101` at
`4c93985`; local gate (696 tests, 99.75% coverage), GitHub CI and Docker passed.
Review found that `detached` is ignored while permission is pending: a later
permission grant can put the session to sleep and resume recording on return,
contrary to ADR 0005. Stop on detach even during the dialog; ordinary hidden and
paused permission-dialog transitions still keep the request alive. Reject stale
status results before opening a dialog, and share an already-pending request
with a later explicit start to avoid Android reporting a second request as busy.
Verify late results, foreground return and teardown races stay safe.

| Work | Owner | Status |
| --- | --- | --- |
| Review Flocke persistence, UI, animation and localization | Independent reviewers | done; no confirmed feature defect |
| Update review guidance and restart-safe plan | Coordinator | integrated; full gate required before commit |
| Fix detach/permission race and add regression tests | Lifecycle agent | integrated; 72 focused session and sleep tests passed |
| Test Flocke selection, stopped navigation and restart persistence together | UI test agent | integrated; focused test passed |
| Independently review critical fix and integrate | Coordinator/reviewer | independent final review found no blocking race; 73 integrated focused tests passed |
| Verify five-second quick-star mode can unlock Flocke | Test agent | passed: 50 focused tests, including 9 stars at 49.9 s and unlock at 50 s |
| Document quick phone test and prepare release | Coordinator | documented; release follows the full gate and GitHub checks |
| Full local gate, version bump, commit, push and check GitHub | Coordinator | fix committed and pushed as `1179db3`; follow-up gate required |
| Publish and verify public debug APK | Coordinator | planned after exact-commit GitHub checks |
| Real-device permissions, lifecycle and Flocke accessibility checks | Owner | open |

Stop before commit if regression tests or `./localPipeline.sh` fail. Preserve
permission-dialog handling for hidden/paused events; rollback is a revert. The
physical-device behavior and production signing remain unverified. Publish only
through `tool/release_debug.sh`, after a dry run and green local and remote
checks; verify the downloaded APK checksum, debug certificate and source tag.

## Active: Flocke the husky (issue #17, 2026-11-06)

Verdict: implement Flocke as a selectable second companion with the same
measurement, alarm, background and accessibility behavior as Mia. The owner
chose the name Flocke and approved the concept art in issue #17. The owner also requested a public debug release; Google Play publication remains deferred.

Decisions and assumptions:

- D1: Flocke unlocks for free at shared level 3 (10 earned stars); this is a
  practical initial threshold because the owner did not specify one. Earning
  stars never auto-switches pets. The shop explicitly selects Mia or Flocke.
- D2: Store the selected pet with the wallet in schema 3. Migrate schema 1/2
  to Mia without changing stars or purchases; reject newer schemas and repair
  unknown or locked selections to Mia. Reset returns to Mia. Never overwrite
  an unavailable wallet; merge stars earned before loading as before.
- D3: Recreate the approved husky design in the existing vector painter style,
  with one blue and one green eye, happy/uneasy/scared/sleeping moods, alarm
  escape, return and wake-up. Use the same controller and motion semantics as
  Mia; no microphone, alarm, or background-recording rules change.
- D4: Existing levels, earned stars and shop items are shared. Pet selection
  stops measurement like the shop already does; it never restarts implicitly.
  Text and accessibility labels must identify the selected companion in all
  four languages. Reduced motion and large text must remain usable.
- D5: This request authorizes implementation on `main` and a debug release, not a Play release;
  keep issues #9 and #17 open unless the owner explicitly requests closure.

| Package | Owner | Status |
| --- | --- | --- |
| Plan, independent challenge and coordination | Coordinator and review agent | done; integration in progress |
| Persistent pet selection, schema migration and domain tests | Domain agent / coordinator | recovered and integrated; independent review found no blocking defect |
| Flocke artwork, animation and rendering tests | Art agent | integrated; 9 focused tests and independent source review passed |
| Shop selection, monitor composition, localization and widget tests | UI agent | integrated; focused shop and delayed-load app tests passed |
| Integrate, independent review, docs and full local gate | Coordinator/reviewer | independent review done; full local gate required before commit |
| Commit with version bump, push, verify GitHub checks and publish debug APK | Coordinator | next after green local gate |
| Real-device pet, accessibility and persistence checks | Owner | open after implementation |

Expected checks: migration/reset and failed-load races; unlock boundary and
restart persistence; every pet mood, red-alarm departure and return, sleep and
wake; all languages and text sizes; no privacy or lifecycle regression. Stop
and fix any failed gate. Rollback is a revert; older app versions must refuse
to overwrite the newer wallet schema. Record each commit's work and current
status here so another agent can resume without duplicating work.

Independent review found and fixed the away-state toy accessibility label; the
first Flocke frame after a delayed wallet load is tested while away or asleep.
Real-device visual, native-language and accessibility review remain open.

Independent challenge: render all five shared accessories on Flocke and
describe only visible accessories. A saved selection can load during a
measurement, so the first Flocke frame must reflect an already-away or asleep
state without restarting the recorder. Monitor text, semantics and level-up
messages must identify the selected pet in every language.

## Previous handover and public debug release (2026-11-06)

Update: `debug-v0.9.6-build99` was published from `2acfa67` and includes
the settings fix. The next debug release is planned after Flocke is verified.
Current `main` at `c1b159f` has green CI and Docker checks. The local debug
certificate matches the previous release. Flutter 3.47.9 is the newest stable
release in the official Linux release manifest (checked 2026-11-06).

Verdict: publish the independently checked preferences fix as a public debug
APK so the owner can retest settings on a real phone. The owner explicitly
requested this release. It is not a production or Google Play release.

- Last verified main before this documentation update: `abea6bd`, version
  `0.9.5+98`; GitHub CI and Docker checks passed and the working tree was clean.
- The public debug release `debug-v0.9.1-build94` predates the settings fix.
  Its minified APK has broken preferences JNI descriptors. The updated plugin
  and release-DEX gate are in `abea6bd`; 666 tests and 99.97% coverage passed.
- PRs #15 and #16 were merged, issue #8 closed, and parent issue #9 remains
  open. Child [#17](https://github.com/marcelpetrick/Raumfreund/issues/17)
  contains the husky concepts, is assigned to the owner and remains open.
- Docker login v4.8.0 is in `7e1a792`, with green GitHub checks; superseded
  Dependabot PR #13 is closed. GitHub issues and PRs are assigned to the owner;
  GitHub cannot request an author as reviewer of their own PR.

| Work | Owner | Status |
| --- | --- | --- |
| Reconcile this plan and require an update in every commit | Coordinator | included in this commit |
| Run full local gate, commit and push plan update | Coordinator | next |
| Verify CI and Docker on the exact pushed commit | Coordinator | planned |
| Preview and publish the matching debug release using `tool/release_debug.sh` | Coordinator | planned |
| Verify release assets, checksum, signature and source commit | Coordinator | planned |
| Retest settings save and restart on a physical Android device | Owner | open after release |

Continue after a restart by checking `git status`, the current version,
GitHub checks and the latest release before repeating any action. Use
`tool/bump_version.sh` for this documentation commit, then the full local gate
and push. Stop publication if a gate, certificate, checksum or version check
fails. Do not create a production tag or use production signing. The local
debug keystore must match the previous debug release to allow in-place updates.
The plan is updated before each commit; post-commit check results are recorded
at the next legitimate change rather than by an endless chain of status commits.

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
- Leaving the app pauses a running measurement: nothing records in the
  background, Mia sleeps, and on return she wakes up while the measurement
  resumes by itself (owner request, issue #7, ADR 0005).

## Verified state (2026-10-21, `0.8.0+87`)

- [x] Domain, controller, native `AudioRecord` recorder, platform channels,
  UI in four languages, Settings, About, persistence, docs and ADRs
  0001–0006 exist.
- [x] GitHub Actions CI and Docker workflows are green on `604aee0` (CI was
  red from `16e84b9` to `0f7529b` because of the JDK pin, fixed in CI1,
  from `2384ae8` to `0ee855f` because of the venv Python, fixed in CI2, and
  on `0d6f6b2` because a markdown-it advisory appeared between the local
  run and CI, fixed in `1739d07`).
- [x] A fresh `git clone` of `9a40b8b` passes `./localPipeline.sh` as the
  README describes (2026-10-20, all 21 steps, 577 tests, 99.97 % line
  coverage, Docker check included). The clone downloaded its own Flutter
  SDK and project tools; the host's Android SDK, Gradle, pub and Docker
  caches already existed.
- [x] Dependabot PRs #1–#3 and #6 are closed; the pinned tooling was updated
  by hand.
- [x] Debug release `debug-v0.1.2-build14` is GitHub's latest release. Its APK
  checksum matches, the signature is Android Debug
  (`C5:55:29:…:4F:49`, this machine's debug keystore), it requests only
  `RECORD_AUDIO` and `VIBRATE`, and it installs and launches without crashes
  on an Android 16 (API 36) emulator.
- [x] README badges resolve (HTTP 200) and CI/Docker badges show passing.
- [x] README shows real screenshots (`docs/screenshots/`) of every monitor
  state, rendered from the real widgets by `tool/render_screenshots.sh`
  (since `0.7.1`; earlier: an emulator capture plus rendered loud states).
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
[ADR 0004](adr/0004-zone-hysteresis.md):

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

### Latest release check (2026-10-21)

`debug-v0.8.0-build87` (commit `604aee0`) is GitHub's latest release,
published with `tool/release_debug.sh` after green local pipeline, CI and
Docker runs for that exact commit; the downloaded APK matches `SHA256SUMS`.
It adds English, Croatian and Mandarin with the live language switch, the
red-teamed text corrections and the release-environment fix of the signing
job to `debug-v0.7.1-build80`. A production `v*` release stays blocked: no
production keystore and no signing secrets exist (checked 2026-10-21).

## Star shop (implemented 2026-10-05)

The implemented first-release behaviour is:

- Quiet-minute stars are still earned only while measuring (one per minute
  of confirmed green). Earned stars also go into a **persistent wallet** on
  the device (schema-versioned `shared_preferences`, no account, no network,
  no money, no ads).
- A **shop page** (app bar action, stops measurement like Settings/About)
  lists five cosmetic items from `KittyAccessory`: bow 3, scarf 5, hat 8,
  cushion 10, toy mouse 12 stars. Buying is one-time; owned items can be given
  to Mia and taken back for free. Items never affect zones or alarms.
- Settings gets **"Sterne zurücksetzen"** with a confirmation dialog for the
  teacher; it clears the wallet and the owned items.
- Mia draws one painter layer per equipped item in every mood, including
  while running away.

| ID | Package | Agent tier | Status |
| --- | --- | --- | --- |
| W | Wallet, inventory, persistence, shop controller, star wiring from the monitor | Sonnet | done, `9d73eb9` |
| K1 | Accessory painter layers for Mia | Sonnet | done, `7da90e8` |
| K2 | Shop page, Settings reset, app composition (after W and K1) | Sonnet | done in `0.5.0` |

## Languages (implemented 2026-10-21)

Owner request: German, English, Croatian and Mandarin (Simplified Chinese)
texts, switched live in Settings, persisted, German by default (ADR 0006).

| ID | Package | Owner | Status |
| --- | --- | --- | --- |
| L10N1 | `AppLanguage`, persisted language repository and controller (own key, independent of the settings snapshot), live `MaterialApp.locale` | Coordinator | done in `0.8.0` |
| L10N2 | Language section in Settings (immediate, independent of Save/Cancel like the star reset), save-failure notice | Coordinator | done in `0.8.0` |
| L10N3 | `app_en.arb`, `app_hr.arb`, `app_zh.arb`; ARB consistency test (keys, placeholders, plural forms); layout tests in every language | Coordinator | done in `0.8.0` |
| L10N4 | Red-team review of all four languages (meaning, tone for children, factual claims vs. behaviour, plurals, truncation) by an independent agent; findings fixed | Opus reviewer + coordinator | done in `0.8.0` |
| L10N5 | Docs: ADR 0006, README, architecture, AGENTS rule "UI is German", screenshots | Coordinator | done in `0.8.0` |

Red-team result (L10N4): the review found errors in the German source that
the translations had copied. All of them are fixed in every language:

- **Alarm rule:** it is not "once per phase" while sound or vibration is on;
  yellow and red time do not add up, and the alarm repeats while the room
  stays loud. With both off it is only shown, once per phase (`0.8.3`).
- **Privacy:** "nothing is recorded" contradicted Android's permission
  dialog, which asks to record audio. The text now says the sound is
  analysed briefly and never saved or sent.
- **Calibration:** the text described a live value, but the measurement is
  stopped while Settings is open.
- **Stars:** "today" was false, and "every quiet minute" is really one
  minute of green in a row.
- **Equip:** a cushion and a toy mouse are given to Mia, not worn.

Chinese now says 提醒 instead of 报警 ("call the police"); Croatian uses
"ovjereni" instead of "umjereni".

Open for the owner:

- a native-speaker read-through on a device;
- ~~whether the teacher's star reset should also clear the session's
  new-star counter~~ resolved in `0.8.3`: the star line counts a
  measurement's stars only while it runs ("2 Sterne in dieser Messung ·
  7 im Sternenladen") and otherwise shows only the Sternenladen total, so a
  reset (Settings stops the measurement) can no longer disagree with it.

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
| I1/E1 | Emulator acceptance harness, matrix and 30-minute soak | Coordinator | soak and permission/lifecycle/rotation matrix done 2026-10-07 (see `docs/testing.md`); found and fixed: no retry after a permanent denial (`0.6.17`); remaining emulator items dropped by owner decision 2026-10-08 |
| D1 | Reconcile plan, testing evidence and release readiness | Coordinator | done in `0.6.10` |
| L3 | Pipeline check: license inventory vs. `pubspec.lock` and `.flutter-version` | Coordinator | done in `0.6.11`: pipeline step `licenses` |
| U1 | Error headline names the cause ("Mikrofon belegt", "Keine Messwerte", …) instead of the generic "Messung nicht möglich"; uses the so far unused error titles | Coordinator | done in `0.6.12` |
| V1 | LinkedIn demo video (owner request 2026-10-07): two 4:5 candidates, max. 30 s, from the emulator with scripted (fake) noise input; Settings, measuring, stars, alarm, shop purchase, rerun with accessory, graph, About | Coordinator | done: `tool/demo/demo_main.dart` (scripted levels, never released); candidates A "Story" (29.9 s) and B "Hook" (28.0 s), 1080x1350, 30 fps, stored in `docs/video/` (owner request); recorded with the emulator's host GPU, which stayed stable where the software renderer crashed |
| V2 | Commit the video tooling (`tool/demo/record_demo.sh`, `tool/demo/cut_demo_video.py`) so candidates can be re-cut, e.g. in English or after owner references | Coordinator | done in `0.6.14`; reproduces both candidates from the recorded take |
| L4 | Pipeline check of the Android license rows against the release build's `sdkDependencies.txt` | Coordinator | done in `0.6.15` (step `privacy`) |
| CI2 | CI Android job red since `2384ae8`: the license check called the venv Python, which that job never creates | Coordinator | done in `0.6.19`: system `python3` (stdlib-only checker) |
| VB1 | Owner never noticed the alarm vibration: single 300 ms pulse without usage attributes | Coordinator | done in `0.6.22`: three pulses (1.14 s) with alarm usage (`VibrationAttributes` API 33+, `AudioAttributes` API 26-32); device check recipe in `docs/testing.md`; on-device confirmation open |
| D2 | `/updateDependencies` (2026-10-08) | Coordinator | done in `0.6.29`: analyzer 14.5.0, katex override 0.19.0, download-artifact v8.0.2, setup-node v7.1.0, upload-artifact v7.0.2; Flutter, Dart, pub app packages, Python tools, binaries, Docker digests and Android command-line tools already current; AGP/Kotlin/Gradle held at the Flutter 3.47.6 template and tree-sitter at 0.25.2 on purpose |
| D3 | Dependabot Kotlin 2.4.21 PR red in step `privacy`: the Kotlin Gradle plugin ships `kotlin-stdlib` of its own version, the license inventory still listed 2.4.0 | Coordinator | done in `0.6.30`: plugin 2.4.21, inventory and `docs/toolchain.md` updated (patch releases within the template line are adopted) |
| D4 | Dependabot Gradle wrapper 9.8.1 PR | Coordinator | done in `0.6.31`: wrapper JAR and distribution SHA-256 match services.gradle.org; toolchain and license docs updated |
| D5 | `/updateDependencies` (2026-10-20) and Dependabot PR #6 (`test` 1.33.0) | Coordinator | done in `0.6.32`: Flutter 3.47.7, test 1.33.0, ruff 0.17.1, osv-scanner 2.7.0, setup-java v6.1.0, Node 24.22.0, dockerfile 1.28.0, Temurin/nginx digests, js-yaml 5.5.0 and smol-toml 1.9.1 overrides; locked pub updates bring `shared_preferences_android` 2.5.1 (Pigeon JNI: `jni` builds `libdartjni.so`, CMake 3.22.1 now pinned in Docker), 16 new transitive packages (MIT `yaml` among them), DataStore 1.2.1 and kotlinx.serialization 1.7.3 in the APK; license inventory and in-app notices updated; AGP/Kotlin/Gradle unchanged (template unchanged) and tree-sitter held at 0.25.2 |
| B1 | Issue #7: pause in the background, Mia sleeps and wakes up measuring on return | Coordinator (own worktree) | done in `0.7.0`: controller status `sleeping`, automatic wake session, sleeping and wake-up animation, ADR 0005, device checks in `docs/testing.md` (open for the owner) |
| R2 | Independent review of B1 (lifecycle) | Opus reviewer (read-only) | done: 1 major (explicit stop during the sleep teardown was lost and could restart behind Settings), 4 minor (wake-up on failure, hard cut, invisible sleep phase, device cases, test gaps); all fixed or documented in `0.7.0` |
| V3 | Screenshots of every monitor state, including sleeping and waking up | Coordinator | done in `0.7.1`: `tool/render_screenshots.sh` renders them from the real widgets |
| W1 | Remove all parked agent worktrees and their branches (owner request 2026-10-07), after archiving their unmerged work | Coordinator | done: 19 worktrees and 20 local branches removed; only `main` remains locally and on GitHub |

Owner decision 2026-10-08: no further emulator work (see AGENTS.md
section 6). The prototype runs and works; the remaining emulator items are
dropped, not open:

- Dropped: further emulator tests (stale events, stream failures,
  persistence, missing vibrator). The permission, lifecycle and rotation
  matrix ran on 2026-10-07 and is recorded in `docs/testing.md`.
- Dropped: native instrumented/UiAutomator suites.
- Dropped: occupied/silenced microphone and interrupted recording on an
  emulator; the owner checks these on real devices.
- Covered without an emulator: the alarm tone cannot retrigger itself
  (controller and alarm state machine tests), and the privacy gate blocks
  network permissions, network APIs and audio-saving code in every build.
- [x] 30-minute emulator soak with crash and resource-cleanup inspection
  (2026-10-07, see `docs/testing.md`).

## Open: owner/external blockers

These cannot be truthfully completed by repository automation alone:

- two physical Android devices from different manufacturers; real-device
  microphone, thermal and endurance tests; five-day RC soak before `v1.0.0`;
- creation and backup of the production keystore and GitHub signing secrets
  (debug releases do not need them);
- Play Console app, developer verification, questionnaires, content rating,
  public privacy-policy URL and the decision to publish through Play.

GitHub branch protection and the `release` environment are configured since
2026-10-08 (see `docs/releasing.md`).

Until then the repository may publish clearly labelled debug APK releases but
must not claim a production-signed release or completed device certification.

## Later ideas (not in the first release)

- No later feature is committed to the first release. New product ideas require
  a separate owner decision and plan entry.

## Dependency refresh (2026-11-04)

Verdict: completed in `67aac6f`; local and GitHub checks passed.

| Work | Owner | State |
| --- | --- | --- |
| Python and Node tooling | Tooling agent | Updates and focused checks passed. |
| Android build toolchain | Android agent | Gradle 9.8.2 and Android checks passed. |
| Flutter, Dart and application dependencies | Coordinator | Flutter 3.47.9 and Dart 3.13.7 pass 649 tests and 99.97% coverage. |
| Integrate, run the full gate and verify CI | Coordinator | done, `67aac6f` |

The full local gate passed with Flutter 3.47.9, Gradle 9.8.2, 649 tests and
99.97% coverage; GitHub CI and Docker passed on the committed update.

## Docker login action update (2026-11-06)

Verdict: replace Dependabot PR #13's stale v4.7.0 proposal with the current
stable v4.8.0, pinned to the official tag's commit. The action is used to log
in to the container registry on non-PR Docker workflow runs.

| Work | Owner | Status |
| --- | --- | --- |
| Verify upstream release and commit | Coordinator | done |
| Update action pin and version, run local quality gate | Coordinator | done, `7e1a792` |
| Push, verify GitHub CI and Docker login, close superseded PR #13 | Coordinator | done |

If the local gate or GitHub checks fail, stop and investigate before closing
the PR. Rollback is a revert of the pinned action and its version bump.

## Issue 8: artwork clipping (2026-11-05)

Verdict: correct the clipped monitor artwork in a pull request. The dependency
refresh was committed as `67aac6f`;
its GitHub CI and Docker workflows passed.

| Work | Owner | Status |
| --- | --- | --- |
| Inspect issue, screenshot and existing work; identify clipping | Reviewer agent | done |
| Fix artwork bounds and add focused regression coverage | Coordinator | done, PR #15 merged |
| Review changes, run local pipeline, commit, push and check CI | Coordinator | done, issue #8 closed |

Verify the gauge and Mia at narrow and wide sizes, including accessories and
animation. Keep intentional clipping when Mia leaves the stage. Record any
remaining real-device checks as open. Abort a commit if the local gate fails;
revert the change if a regression cannot be resolved.

## Issue 9: Mia levels up (2026-11-05)

Verdict: make earned stars grow Mia's level, independent of spending, and
unlock a playful dance in the shop. Keep the existing cat, offline wallet and
quiet-star rules; no second pet or consumable economy is needed for this first
increment. PR #16 was merged after PR #15; issue #9 remains open for ideas.

- D1: Persist lifetime earned stars with the wallet, independent of spending.
  Migrate existing wallets from the balance plus owned item prices; items were
  bought once and could not be sold. Reset clears progress with the wallet.
- D2: One level per five earned stars, starting at level 1. Level 2 unlocks a
  replayable dance; show level and progress towards the next level in the shop.
  Respect reduced motion and localize every visible string in four languages.
- D3: Adapt the requested six-stage issue workflow to GitHub and this project's
  existing pipeline and versioning in `AGENTS.md`.
- Q1: Real-device visual and accessibility checks remain open for the owner.

| Work | Owner | Status |
| --- | --- | --- |
| Challenge level and wallet design | Review agent | done |
| Wallet level calculations and persistence | Domain agent | done |
| Shop level display, dance and localizations | UI agent | done |
| Integrate tests, docs and independent review | Coordinator | done |
| Adapt issue workflow in `AGENTS.md` | Coordinator | done |
| Run full gate, commit, push and verify checks | Coordinator | done, PR #16 merged |

Checks: prove progress survives purchases, reload and failed-load merging;
verify reset, boundaries, translations, layout and reduced motion. Stop before
commit if any gate fails. Rollback requires preserving the newer wallet schema;
an older app will refuse to overwrite it rather than lose earned progress.

## Husky concept and child issue (2026-11-06)

Verdict: propose a friendly husky as a future level-based unlock, with two
concept sheets and ten possible names. These are design references, not a
commitment to a level, price, final name, or implementation of a second pet.

| Work | Owner | Status |
| --- | --- | --- |
| Create visual concepts in Mia's style | Coordinator | done |
| Save concepts, name ideas and design assumptions in the repo | Coordinator | done, `5763a7e` |
| Create assigned GitHub child issue under #9 with the designs | Coordinator | done, #17 |
| Verify, commit and push project workflow and design documentation | Coordinator | done; image URLs returned HTTP 200 |

Verify the linked images render in the issue, and leave the parent open.
Rollback by reverting the documentation and images; no app behavior changes.

## Release settings persistence regression (2026-11-06)

Verdict: update `shared_preferences_android` to the upstream-fixed 2.5.4 and
check the minified release APK for the JNI symbols used by preferences. The
published 0.9.1 APK has an obfuscated method descriptor; this explains a
release-only save failure, but the owner's device retest remains open.

| Work | Owner | Status |
| --- | --- | --- |
| Diagnose the published APK and upstream issue | Two independent reviewers | done |
| Update plugin and add release-DEX regression gate | Settings agent | done and independently reviewed |
| Integrate, run full gate, commit and verify remote checks | Coordinator | done, `abea6bd` |

The checker must fail against the old APK and pass against the fixed release
APK. Stop on a failed gate. Rollback by reverting the plugin and verifier;
that restores the known broken release behavior and is not recommended.
