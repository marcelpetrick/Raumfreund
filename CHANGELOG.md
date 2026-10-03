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
