<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Current-state review – 2026-11-07

Baseline: `7241b914c4c1120a7542b3e3bc42583f3fcae8b0` (`main`,
`0.11.1+106`). Scope: the current Android app, Dart domain and UI, native
platform integration, tooling, CI, documents and architecture. This is not
limited to a branch diff. Findings are ranked by impact and refer to the
baseline; the list is not padded to twenty. Device-only behaviour remains open.

## Findings

1. **MEDIUM · Code · Settings load failure can overwrite existing settings** —
   `lib/features/settings/infrastructure/shared_preferences_settings_repository.dart:129`.
   A store-open failure returns defaults as a successful load, which the
   controller caches; after recovery, saving those defaults can replace the
   unread settings. Preserve the failed-load state and recover without writing
   over unknown data. **Status: fixed, independently reviewed and locally gated.**
2. **MEDIUM · Architecture · Newer settings schema can be overwritten** —
   `lib/features/settings/infrastructure/shared_preferences_settings_repository.dart:140`.
   An older app treats a newer schema as defaults and can write its own snapshot
   over it, discarding newer fields. Refuse writes until the schema can be read.
   **Status: fixed, independently reviewed and locally gated.**
3. **MEDIUM · Code · Failed preference write can pollute the process cache** —
   `lib/features/settings/infrastructure/preferences_store.dart:50`. The pinned
   `shared_preferences` implementation updates its shared cache before the
   platform write completes and does not revert it on failure. A later read in
   the same process can therefore report an unsaved value as durable, while a
   restart restores the old value; verify failed-write recovery against the
   real plugin contract, including the shared wallet. **Status: open.**
4. **MEDIUM · Code · Concurrent stop does not wait for teardown** —
   `lib/features/monitor/application/monitor_controller.dart:159`. Once a
   background stop clears the active session, a second `stop()` returns while
   the first is still cancelling the stream or stopping the recorder. Navigation
   expects that future to mean cleanup is complete; share the teardown future.
   Native `onStop` is a separate safety net, not proof of the Dart contract.
   **Status: open.**
5. **MEDIUM · Code · Sparse readings can earn quiet stars** —
   `lib/features/monitor/application/monitor_controller.dart:409`. With one
   green sample every 800 ms, the alarm marks the signal too sparse and never
   settles the zone, yet the star counter awards a star at 60 seconds. Require
   enough evidence of green and test recovery in normal and quick-star modes.
   **Status: open.**
6. **MEDIUM · Code · Container download is presented as an ordinary APK** —
   `docker/index.html.template:40`. CI publishes images without a signing key,
   so their APKs use fresh debug keys and may not update earlier installs; the
   page does not identify the debug signature or this limitation. Show the
   actual signing type and update guidance, including for images built on `v*`
   tags. **Status: fixed and independently reviewed; full local gate passed.**
7. **MEDIUM · Code · Debug release accepts a different signing key** —
   `tool/release_debug.sh:124`. Checking only `CN=Android Debug` accepts a
   regenerated keystore with a different fingerprint, although Android then
   rejects updates over the previous debug release. Compare the certificate to
   a trusted previous release before publication. **Status: open.**
8. **MEDIUM · Code · Prerelease tags can become normal releases** —
   `tool/check_release_version.sh:36` and `tool/publish_release.sh:30`. The
   version checker accepts beta/RC tags but publication does not mark them as
   prereleases, so they may appear as the latest stable release. Apply a
   consistent prerelease policy and test it. **Status: open.**
9. **MEDIUM · Architecture · Release instructions omit committing the version** —
   `docs/releasing.md:14`. Following the instructions tags the old commit after
   editing the version and changelog, so the release checks the wrong source or
   rejects the tag. Commit, push and verify the exact versioned commit before
   tagging. **Status: fixed in the documentation; full local gate passed.**
10. **MEDIUM · Architecture · Docker installs floating Android SDK components** —
   `docker/Dockerfile:44`. The current Docker gate log shows Gradle installing
   platform-tools and Android Platform 35 during the build, although the
   toolchain page claims platform-tools is not installed. Pin or otherwise
   control the required components and correct the documentation.
   **Status: documented accurately; SDK pinning remains open.**
11. **MEDIUM · Code · Threshold slider semantics lack context** —
   `lib/features/settings/presentation/settings_page.dart:528`. A semantics
   probe found the yellow slider exposes `129 dB` and `99%` without identifying
   the yellow threshold. Give both sliders localized names and dB values.
   **Status: open.**
12. **LOW · Code · Failed debug tag push leaves a blocking local tag** —
   `tool/release_debug.sh:205`. A failed push exits after creating the local
   tag; the next attempt refuses the existing tag. Recover safely and test the
   failed-push path. **Status: open.**
13. **LOW · Code · Release creation failure is treated as atomic** —
    `tool/release_debug.sh:207`. `gh release create` can fail after creating a
    draft or after an ambiguous network response; unconditional tag deletion
    can leave a release without the intended tag, and ignored cleanup errors
    are reported as success. Inspect remote state and report safe recovery.
    **Status: open.**
14. **LOW · Code · Debug release uses the caller's GitHub repository** —
    `tool/release_debug.sh:207`. Git uses `-C` for the script's checkout, but
    `gh release create` resolves its repository from the caller's directory.
    Running the script from elsewhere can fail after pushing a tag or target a
    different repository. Bind `gh` to the checkout and test this invocation.
    **Status: open.**
15. **LOW · Code · Timeline's now marker can show old data as current** —
    `lib/features/monitor/presentation/level_timeline.dart:180`. The chart
    anchors its window to its last bucket even after measurement stops, so
    old points remain under “now” and in the summary. Advance or label the
    time reference correctly. **Status: open.**
16. **LOW · Code · Timeline can draw across a measurement gap** —
    `lib/features/monitor/domain/level_history.dart:88`. Samples at 0 and
    19.9 seconds enter adjacent 10-second buckets and are rendered as one
    continuous segment despite a nearly 20-second gap. Preserve a break in
    the history rather than inferring it solely from bucket timestamps.
    **Status: open.**
17. **LOW · Code · Interrupted permission request may look permanent** —
    `android/app/src/main/kotlin/it/marcelpetrick/raumfreund/MicrophonePermission.kt:51`.
    The result array is discarded; an interrupted first request with no grant
    and no rationale is reported as permanently denied even if retryable.
    Preserve cancellation information and test the callback. Android's
    inference remains inherently ambiguous; real-device verification is open.
    **Status: open.**
18. **LOW · Code · Mia's away label names invisible accessories** —
    `lib/features/monitor/presentation/kitty/kitty_character.dart:175`. The
    semantics label includes all equipped items after Mia leaves although only
    the mouse stays visible. Describe only visible items, as for Flocke.
    **Status: open.**
19. **LOW · Code · Threshold stepper endpoints remain enabled** —
    `lib/features/settings/presentation/settings_page.dart:503`. Red minus at
    1 dB and yellow plus at 129 dB remain enabled but setters clamp the result.
    Match controls and semantics to their actual ranges. **Status: open.**

20. **LOW · Architecture · Local build provenance omits dirty state** —
    `tool/build_apk.sh:34`. Local builds can embed the HEAD commit while
    uncommitted source changes are included, so About and Docker artifacts
    appear tied to a commit that does not fully describe their source.
    Mark dirty builds or require clean source when claiming a commit identity.
    **Status: open.**

### Additional documentation findings

- `README.md:78` described the microphone as not recording; it now explains
  that PCM is processed in RAM and never saved or transmitted.

- `docs/toTheMoonAkaPlaystore.md:113` asked the phone-only screenshot renderer
  for tablet assets. The checklist now leaves real tablet captures open.
- `docs/building.md:8` omitted prerequisites for the full gate. The supported
  host, Node/npm, Python and Docker requirements are now listed.

## Evidence and limits

The review followed application state, channel and native call paths and
inspected the corresponding tests, CI and release scripts. Disposable probes
reproduced the sparse-star and timeline-gap cases, and a widget semantics probe
confirmed the threshold description. The native permission policy test passed
with Gradle reporting it up to date; no device or emulator test was performed.
The prior baseline's local gate passed 713 tests at 99.86% line coverage and
its GitHub CI and Docker workflows passed. This is evidence for those checks,
not proof that every platform path was exercised.
