# AGENTS.md – Working rules for Raumfreund

These rules are binding for every human or AI agent working in this repository.
They merge section 8 of [`docs/vision.md`](docs/vision.md) (the product
specification) with the project owner's workflow rules. Where both define the same
thing, the stricter rule applies.

## 1. Orientation before changing anything

- Read `docs/vision.md`, `README.md`, `docs/architecture.md` and the ADRs in
  `docs/adr/` before making changes. The vision is the source of truth for scope.
- Scope is **one Android app** (phones and tablets) built with Flutter/Dart.
  iOS, desktop and web are out of scope. Document every necessary assumption in
  the relevant `docs/` page or an ADR.
- `docs/prototype/raumfreund-source.zip` is an unvalidated prototype. Nothing from it is taken over
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
- Keep `docs/plan.md` restart-safe and update it with every commit: record the
  objective, package owners and status, completed evidence, next steps, open
  decisions and external blockers. Before each commit, reconcile the plan
  with that commit's changes; after a restart verify Git and remote state
  before repeating actions. Record post-commit checks in the next plan update
  without inventing results or creating a commit solely to report success.
- If sub-agents are not available, do the work yourself and state that limitation.
- Assign GitHub issues and pull requests to the repository owner
  (`marcelpetrick`) when working on them. Request that owner as reviewer when
  GitHub permits it; GitHub cannot request the pull request's author as its
  own reviewer. Report any platform limitation instead of leaving it implicit.

### Issue workflow

For issue-driven work, use these gates in order and give the owner a short
progress report at each one. Scale the detail to the change; record the plan,
package owners and status in `docs/plan.md` before implementation.

1. **Understand.** Read the issue, comments, linked issues and pull requests,
   and inspect existing branches so existing work is continued. Check relevant
   code and CI on `main` and inspect the environment read-only. Record evidence,
   unknowns and the issue's actual scope. Preserve existing issue metadata;
   change assignment, status, estimates or time only when authorized.
2. **Plan.** State the verdict and rationale first, followed by environment,
   decisions, open questions, target design and intended atomic commits. List
   checks with expected results and stop criteria, rollback and remaining risks.
   Ask the owner only about decisions that cannot be made within the authorized
   scope, and record the answers. Work directly on `main` unless the owner
   requests a pull request; use isolated worktrees for parallel sub-agents.
3. **Challenge.** Have an independent agent review material assumptions,
   failure modes and effects on other work where agents are available. Resolve
   real high- and medium-severity findings and repeat review as needed. If an
   independent review is unavailable, report that limitation. Proceed when the
   plan is sound and the work is authorized.
4. **Implement and review.** Make atomic Conventional Commits referencing the
   issue, with the version bump in each commit and the full local gate before
   each commit. Cover behavior changes with appropriate tests; where useful,
   verify regression tests fail against the defect. Independently review critical
   logic as required above, fix in-scope high and medium findings and inexpensive
   low findings, and verify claims made by sub-agents.
5. **Verify remote checks.** Push each green commit and monitor the corresponding
   GitHub Actions runs. Investigate failures and address relevant review or bot
   findings. If a pull request is explicitly requested, use a draft while work is
   ongoing, follow the repository's PR conventions, and keep it current and
   green. Do not create throwaway PRs or post comments without authorization.
6. **Hand over.** Report the result, commit and check links, unresolved risks,
   skipped checks and real-device checks still open. For an authorized PR, report
   what remains for human review and merge. Never merge a PR, edit or close the
   issue, alter server or runner settings, or send review pings unless explicitly
   instructed. Provide a URL for any authorized comment posted.

## 3. Git workflow

- Work directly on `main` unless the owner requests a pull request or a
  sub-agent needs an isolated worktree. Do not merge a pull request without
  explicit authorization.
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
- UI languages are German (default), English, Croatian and Simplified
  Chinese (ADR 0006); all user-visible strings live in the localization
  files, and every new string gets an entry in all four ARB files.
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
  This waives the emulator integration tests of `docs/vision.md`
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
