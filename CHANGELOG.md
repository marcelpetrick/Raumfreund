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
* v0.2.1 makes Mia visibly scared in red and lets her run away after the red alarm, walking back calmly when it is quiet again
* v0.2.2 records the package status, the hysteresis decisions and the open steps in plan.md
* v0.2.3 fixes the minimum Android API in debug release notes (aapt2 reports minSdkVersion)
* v0.3.0 adds zone hysteresis (fast attack, slow release) so the light no longer flickers and loud rooms still alarm after the delay; Mia stays away after the red alarm until green is settled (ADR 0004)
* v0.3.1 shows real screenshots in the README, documents the release command and records the emulator smoke test
* v0.4.0 makes the alarm delay configurable in Settings (3–60 s, default 10 s); settings schema v2 migrates older data to 10 s, and older app versions reading v2 data fall back to defaults
* v0.4.1 brings docs/architecture.md in line with the zone hysteresis, envelope and configurable delay
* v0.4.2 keeps the reserved status text height correct with Android's bold text setting
* v0.4.3 shows "Alarm gleich" instead of a stuck "0 s", speaks the countdown in full words and explains that short pauses count towards the alarm delay
* v0.4.4 removes the pushed tag again when creating the GitHub release fails, so the release command can simply be retried
* v0.4.5 updates the Docker base images (Temurin 21 JDK, unprivileged nginx) to their current digests
* v0.4.6 records the 0.4.5 debug release, its smoke test and the finished review and dependency steps in plan.md
* v0.4.7 adds a privacy gate to the pipeline and CI: the release APK may only request microphone and vibration, and app code may not use audio-writing or network APIs
* v0.4.8 shows "Messung gestört" when readings arrive too sparsely to judge, with its own hysteresis so stalls and irregular rates do not make it flicker
* v0.4.9 adds the KittyAccessory catalog contract and the star-shop plan
* v0.4.10 draws Mia's shop accessories (bow, scarf, party hat, cushion, toy mouse) in every mood and mentions them to screen readers
* v0.4.11 adds the persistent star wallet and shop logic: quiet-minute stars are kept on the device, items can be bought once and worn for free, and a failed load never overwrites stored stars
* v0.5.0 adds the star shop: kids spend quiet-minute stars on a bow, scarf, party hat, cushion or toy mouse for Mia, and teachers can reset all stars in Settings
* v0.5.1 documents the emulator smoke tests and the emulator crash seen on the development host
* v0.5.2 shows the Sternenladen total next to today's stars on the monitor
* v0.5.3 never overwrites stored stars after a failed or newer-version load, retries failed saves on resume and when the shop opens, and confirms the teacher reset only after it was saved
* v0.5.4 updates shared_preferences and pinned Node transitive dependencies, repairs the Gradle 9.3.1 wrapper with checksum validation, and pins the CI JDK and Android build tools
* v0.5.5 keeps ignoring microphone readings while an earlier alarm tone still plays, even after a quick stop and restart
* v0.6.0 adds an off-by-default Schneller Stern-Testmodus in Settings (one star after 5 s of green instead of 60 s), keeps earned stars across mode changes, and disables shop purchases until stored stars have loaded
* v0.6.1 adds a third-party license inventory of everything that ships in the APK
* v0.6.2 lists the Android libraries (Apache-2.0) and the Material Icons font (CC-BY-4.0) on the open-source licence page
* v0.6.3 ends a measurement with a clear message when the microphone delivers no values (5 s without a first, 3 s without a further reading)
* v0.6.4 records the 0.6.3 emulator smoke test and the repeated emulator crash at microphone start
* v0.6.5 treats an all-silent (muted) microphone as no measurement, so it ends with a clear message instead of a calm green room that earns stars, and names the Android microphone toggle in the error texts
* v0.6.6 shows on the monitor when the Stern-Testmodus is on
* v0.6.7 bounds the wait for the alarm output to 2 s so a lost answer can never freeze later measurements
* v0.6.8 fixes the JDK pin of the GitHub CI setup, which had kept CI red since 0.5.4
* v0.6.9 uses the exact Adoptium version string for the pinned CI JDK
* v0.6.10 records the debug-v0.6.9-build54 release check and the completed acceptance-pass packages
* v0.6.11 adds the pipeline step licenses, which fails when the license inventory drifts from pubspec.lock or the Flutter pin
* v0.6.12 names the cause in the headline of every measurement error, for example Mikrofon belegt or Keine Messwerte
* v0.6.13 adds a demo entry point with scripted noise levels for screen recordings (never part of a release)
* v0.6.14 adds the scripts that record and cut the demo video
* v0.6.15 checks the Android libraries of the license inventory against the release build
* v0.6.16 records the 30-minute emulator soak and the end-to-end check of the muted-microphone error
