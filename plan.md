# Raumfreund – Work plan

Living task list. **Every commit ticks off (at least) one task** so work can be
resumed immediately after a crash: pick the first unchecked box, read the
referenced files, continue. Specification: [`Raumfreund-VISION.md`](Raumfreund-VISION.md),
rules: [`AGENTS.md`](AGENTS.md).

## Product decisions (made by the coordinator, see `docs/adr/`)

- **Character "Mia" the kitty** replaces the plain face: green = happy, purring,
  tail swaying; yellow = ears flat, sad; red = crying and walking out of the
  picture (comes back when it is quiet again). Status is always also shown as
  text and face expression – never colour alone.
- **Heartbeat timeline**: last 30 minutes of levels drawn live like a heart-rate
  monitor (glowing trace, zone bands, threshold lines). Values only, RAM only,
  cleared on app exit – no audio, no persistence.
- **Glowing, "poppy" UI**: dark night-sky gradient, neon glow gauge, soft
  particles; honours "reduce animations" and large text.
- Measurement via **own small Kotlin module** (AudioRecord, no third-party mic
  plugin); settings via `shared_preferences`.
- Application id `it.marcelpetrick.raumfreund`; author Marcel Petrick.
- Docker image: reproducible build of the signed/debug APK, final image serves
  the APK over HTTP for easy side-loading (`docker run -p 8080:8080 …`),
  published to GHCR.

## M0 – Foundation

- [x] Commit vision and prototype archive
- [x] AGENTS.md with binding rules
- [x] plan.md (this file)
- [x] Pinned toolchain (`.flutter-version`, `tool/flutter.sh`), Flutter Android project skeleton, GPL-3.0 LICENSE, strict analysis options, version 0.0.1
- [x] `tool/bump_version.sh` (semver + monotonic build number) with tests
- [x] `localPipeline.sh` v1: format, analyze, test, coverage gate, debug APK
- [ ] `tool/install_tools.sh`: pinned shfmt, actionlint, gitleaks, osv-scanner, ktlint, detekt, Python/Node tooling
- [ ] GitHub Actions CI mirroring the local pipeline (SHA-pinned actions, read-only token)
- [ ] `docs/toolchain.md` with verified versions and sources
- [ ] ADR 0001 microphone implementation, ADR 0002 architecture/state handling

## M1 – Core (parallel packages after interfaces are fixed)

- [x] Shared interfaces: `Clock`, `AudioLevelSource`, `AlarmOutput`, `ScreenAwake`, `SettingsRepository`, `AppInfo`
- [ ] Domain: thresholds/zones value objects + calibration
- [ ] Domain: alarm state machine (phases, 10 s, gaps, own-alarm suppression) with full edge-case tests
- [ ] Domain: level history ring buffer (30 min) + display smoothing
- [ ] Application: measurement session controller (states, session ids, lifecycle, permission)
- [ ] Settings: model, validation, versioned persistence + migration
- [ ] Native: AudioRecord level recorder, RMS calculator (JVM tests)
- [ ] Native: permission handler (denied/permanently denied/settings intent)
- [ ] Native: alarm player (tone + optional vibration), keep-screen-on, app info
- [ ] Native: microphone busy/silenced detection, background safety stop
- [ ] Platform adapters in Dart (method/event channels) + tests with mocked channels
- [ ] Vertical slice: mic → controller → UI working on emulator

## M2 – Experience

- [ ] Theme: glowing night palette, Material 3, typography, l10n (German ARB)
- [ ] Kitty character widget (3 moods, walk-away animation, reduced-motion variant)
- [ ] Glow level gauge 0–130 dB with zone bands + estimated value
- [ ] Heartbeat timeline (30 min, live, zone bands, semantics summary)
- [ ] Monitor page: start/stop, status text, countdown, errors with actions
- [ ] Settings page: thresholds, calibration, sound/vibration, save/cancel/defaults
- [ ] About page: version/build, author, project URL, license, privacy, licenses page
- [ ] Responsive layouts: small phone, tablet, landscape, large text
- [ ] Golden tests (phone, tablet, landscape, large text)
- [ ] App icon and splash

## M3 – Quality gates

- [ ] Parser-based 100-line function checker (Dart via analyzer, Kotlin/Bash/Python via tree-sitter) with 99/100/101 + nesting tests
- [ ] Kotlin: ktlint, detekt, Android Lint in pipeline
- [ ] Shell (shellcheck, shfmt), Python (ruff, mypy, pytest), Markdown, YAML, actionlint
- [ ] Security: gitleaks, osv-scanner, license inventory + SBOM
- [ ] Coverage gate ≥ 95 % in pipeline
- [ ] Integration tests (integration_test) on emulator incl. permission grant/deny
- [ ] Native instrumented tests (UiAutomator permission dialogs, lifecycle)
- [ ] Emulator e2e job in local pipeline and GitHub Actions

## M4 – Distribution

- [ ] Release signing config (keystore from env/secrets, never committed)
- [ ] Dockerfile (pinned toolchain, build stage, APK-serving final stage) + local docker check
- [ ] GitHub Actions: docker build + publish to GHCR
- [ ] Release workflow: tag `vX.Y.Z` → gates → signed APK/AAB, checksums, SBOM, licenses, provenance, GitHub Release
- [ ] Version/tag/changelog consistency check
- [ ] Weekly maintenance workflow (Flutter/dependency update check) + Dependabot

## M5 – Documentation and finish

- [ ] README with badges, setup, testing, pipeline, docker, usage, real screenshot
- [ ] docs/{architecture,measurement,privacy,testing,releasing}.md
- [ ] CONTRIBUTING, SECURITY, CHANGELOG, issue/PR templates, `tool/README.md`
- [ ] GitHub milestones/issues/labels as described in vision §13
- [ ] Independent review of critical logic (sub-agent) + fixes
- [ ] `/reviewBranch`, fix findings
- [ ] `/githubAbout`
- [ ] First release `v0.x` via pipeline with downloadable APK
- [ ] Final check against every vision item, pipeline green, Actions green, Docker image works, tree clean

## Open points needing the owner (cannot be done by an agent)

- Tests on two real Android devices from different manufacturers (vision §11/§15),
  30-minute endurance run, RC soak of five working days.
- Backup of the release keystore created for GitHub secrets.
