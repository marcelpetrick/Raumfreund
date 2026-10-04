# Changelog

One line per version, newest at the bottom. Release notes are generated from
these lines (see docs/releasing.md).

* v0.0.1 adds the pinned Flutter 3.47.6 toolchain wrapper, the Android project skeleton, GPL-3.0 license and strict analysis options
* v0.0.2 adds tool/bump_version.sh for SemVer + monotonic build numbers with tests
* v0.0.3 adds localPipeline.sh (format, analyze, shellcheck, tool tests, flutter tests, 95 % coverage gate, debug APK)
* v0.0.4 adds shared interfaces: monotonic clock, zones/thresholds, platform ports, settings model, app info, channel protocol
* v0.0.5 untracks local agent worktrees accidentally recorded as gitlink
* v0.0.6 extends plan.md with work packages, mockups and Google Play readiness tasks
* v0.0.7 adds GitHub Actions CI mirroring localPipeline.sh (static, tests+coverage, Android build) with SHA-pinned actions
* v0.0.8 documents the verified toolchain (docs/toolchain.md) and the architecture decision (ADR 0002)
* v0.0.9 fixes nondeterministic coverage of const constructors in CI
* v0.0.10 verifies the downloaded Flutter archive against a pinned SHA-256
* v0.0.11 adds three neon artwork mockups with Mia the kitty (happy, walking out when too loud, peeking back in)
* v0.1.0 ships the offline Android monitor, Mia UI, Settings/About, native audio, tests, CI, Docker and signed-release automation
* v0.1.1 closes final review findings in settings persistence, startup/navigation, feedback, charts and release gating
* v0.1.2 documents verified debug APK prereleases alongside signed production releases
* v0.1.3 updates pinned CI and Docker build tooling
* v0.1.4 regroups plan.md around the verified state and current packages; AGENTS.md adds model tiers, worktree toolchain and commit-body rules
* v0.1.5 shows the author email `mail@marcelpetrick.it` on the About page
* v0.1.6 regenerates the coverage import test before analysis so a stale copy cannot fail the analyze step
* v0.1.7 keeps the status panel height stable across zone, alarm and star text changes
* v0.1.8 adds tool/release_debug.sh, a checked one-command debug APK release with notes covering every change since the previous one
* v0.2.0 shows the last 10 minutes as smoothed 10 s points with fast-attack, slow-release peaks and a calmer gauge
