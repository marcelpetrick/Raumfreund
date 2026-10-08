# AGENTS.md – Working rules for Raumfreund

These rules are binding for every human or AI agent working in this repository.
They merge section 8 of [`Raumfreund-VISION.md`](Raumfreund-VISION.md) (the product
specification) with the project owner's workflow rules. Where both define the same
thing, the stricter rule applies.

## 1. Orientation before changing anything

- Read `Raumfreund-VISION.md`, `README.md`, `docs/architecture.md` and the ADRs in
  `docs/adr/` before making changes. The vision is the source of truth for scope.
- Scope is **one Android app** (phones and tablets) built with Flutter/Dart.
  iOS, desktop and web are out of scope. Document every necessary assumption in
  the relevant `docs/` page or an ADR.
- `raumfreund-source.zip` is an unvalidated prototype. Nothing from it is taken over
  without review; lifecycle, permission, concurrency and alarm handling must be
  re-done properly.

## 2. Planning and sub-agents

- Write a work plan before implementing. Split independent packages (domain,
  UI, native Android, CI/docs) and hand them to sub-agents when the environment
  supports it.
- The coordinator owns integration, shared configuration, architecture and final
  acceptance. Every sub-agent gets an exclusive file area or its own
  branch/worktree; no two agents edit the same files concurrently.
- Sub-agents report: changes, tests, commands run, results, risks, open points.
- Critical logic (alarm state machine, measurement session lifecycle, permission
  flow) is reviewed independently by another agent.
- Pick the smallest model tier that can do a package well: Haiku for small,
  mechanical edits; Sonnet for well-specified UI, tooling and docs work; Opus
  for critical logic (alarm, lifecycle, permissions, signal processing),
  cross-cutting design and independent reviews.
- Agent worktrees do not contain the git-ignored `.toolchain/`; link it with
  `ln -s <main checkout>/.toolchain .toolchain` instead of downloading again.
  Agents commit only on their own worktree branch, without version bumps or
  changelog edits; the coordinator integrates.
- Track the work packages, their owners and status in `plan.md`.
- If sub-agents are not available, do the work yourself and state that limitation.

## 3. Git workflow

- Work directly on `main`. No feature branches unless a sub-agent needs an
  isolated worktree; those are merged back promptly.
- **Atomic commits** with **Conventional Commits** messages
  (`feat:`, `fix:`, `test:`, `docs:`, `ci:`, `build:`, `refactor:`, `chore:`).
  One logical change per commit. Commit bodies use real line breaks (pass
  several `-m` options or a message file), never literal `\n` sequences.
- **Semantic versioning** in `pubspec.yaml` (`X.Y.Z+N`):
  - every commit bumps at least the patch version (`Z`),
  - major features bump the minor version (`Y`, patch reset to 0),
  - the build number `N` (Android `versionCode`) increases by one with every
    commit and never decreases.
  - Use `tool/bump_version.sh` instead of editing versions by hand.
- **Every commit must be green**: run `./localPipeline.sh` before committing.
  Never commit or push a red state. Push continuously after each green commit.
- Never commit secrets, keystores, signing passwords or audio data.
- Keep the working tree clean; generated build output stays ignored.

## 4. Toolchain

- Verify the newest **stable** Flutter release from official sources and use its
  bundled Dart. No beta/dev channels. Do not update Flutter and Dart separately.
- Pin the exact Flutter version for local development, CI and Docker
  (`.flutter-version`), commit `pubspec.lock` and the Gradle wrapper.
- JDK, Kotlin, AGP and Gradle follow the officially supported combination; justify
  deviations from the newest single release in `docs/toolchain.md`.
- Release builds use pinned versions only, never an uncontrolled `latest`.

## 5. Code quality

- **Maximum 100 physical lines per hand-written function/method/closure**,
  including signature, blank lines and comments up to the closing brace. Aim for
  20–40 lines. This applies to widget `build` methods too. No circumventing via
  minification or artificially joined lines. CI enforces this with a
  parser-based checker (`tool/function_length/`).
- Keep domain logic independent of Flutter widgets, native APIs and the real clock;
  test its edge cases with fake clocks.
- No global mutable state, hidden side effects, empty catch blocks or blanket
  lint suppression. No blanket `ignore` directives, disabled checks or coverage
  exclusions to make numbers look better. Any exception must be specific,
  narrow, justified in a comment and reviewable.
- Document public APIs and non-obvious domain decisions; comments explain *why*.
- UI is German; all user-visible strings live in the localization files.
- Every hand-written source file carries an SPDX header:
  `SPDX-License-Identifier: GPL-3.0-only` plus a copyright line.

## 6. Testing and pipeline

- `./localPipeline.sh` is the single local quality gate: formatting, linting,
  static/type checks, function-length check, unit/widget/golden tests,
  coverage, Android builds, license and privacy checks, and Docker checks. GitHub Actions mirror this pipeline and must stay green.
- **Line coverage must stay at or above 95 %** for the measurable own Dart code.
- Use unit, widget, golden and app-level widget tests where appropriate.
- Run formatting, analysis, tests and builds relevant to every change. Fix
  failures; name skipped checks explicitly.
- A test script in the repository is not proof of a successful test run. Only
  claim results that were actually executed.
- Platform/device tests that were not executed are marked as **open**.
- **No emulator testing** (owner decision 2026-10-08): the prototype runs and
  works, so no time goes into emulator acceptance runs, emulator matrices,
  soaks or emulator/instrumented (UiAutomator, `integration_test`) suites.
  This waives the emulator integration tests of `Raumfreund-VISION.md`
  section 10. Behaviour that unit, widget and app tests cannot prove is
  checked by the owner on real devices; agents document such checks as open
  for the owner instead of automating them. The emulator is used only to
  record demo media with `tool/demo/`.

## 7. Privacy and safety

- Never store or transmit audio. Samples are processed in RAM and discarded.
- No analytics, accounts, ads or tracking. No `INTERNET` permission in release
  builds unless technically required and documented.
- Logs contain no audio content and no personal data.

## 8. Documentation and releases

- Change documentation, license notices and `CHANGELOG.md` together with
  behaviour.
- Scripts are small, reusable and documented (header comment with purpose,
  usage and exit codes; overview in `tool/README.md`).
- Production releases only come from a verified commit with a matching
  `vX.Y.Z` tag, release-signed APK/AAB artifacts, checksums and release notes.
  Missing access rights or production-signing secrets are named as blockers,
  never simulated.
- Debug APKs may be published as GitHub releases for direct device testing
  without a production keystore. They use a non-production tag such as
  `debug-vX.Y.Z-buildN`, retain the `-debugsigned.apk` suffix, include a SHA-256
  checksum and source commit, and state prominently that they use Android's
  debug certificate and are not Google Play or production builds. They may be
  the repository's latest GitHub release, but must never be described as a
  production release.
- Trigger a debug release only with `tool/release_debug.sh` (preview with
  `--dry-run`). It builds locally on purpose: every debug release must carry
  the same debug certificate, otherwise Android refuses to update an
  installed earlier release.
