<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Releasing

Raumfreund has two deliberately separate release types: production releases
for stores or long-lived distribution, and debug releases for immediate device
testing.

## Production release

1. Start from a clean, reviewed `main` commit and run `./localPipeline.sh`.
2. Bump with `tool/bump_version.sh`, update the changelog and rerun the gate.
3. Create and push the matching signed tag `vX.Y.Z`.
4. The Release workflow checks tag/version/changelog consistency, reruns the
   gate, materializes signing data, builds APK/AAB, generates checksums and an
   SPDX SBOM, attests artifacts and publishes through the `release`
   environment.

Required GitHub secrets are `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.
The keystore and `android/key.properties` are ignored and removed after the
build. Missing secrets deliberately fail the workflow. Never upload a
debug-signed artifact as a production release.

Repository settings (set 2026-10-08): `main` rejects force-pushes and
deletion and requires a linear history, also for administrators; pull
requests are not required because work happens directly on `main`. The
`release` environment accepts deployments only from `v*` tags, so the signing
secrets, once stored there, are available to tagged releases only.

The license inventory required for every production release starts from
[`docs/third-party-licenses.md`](third-party-licenses.md); refresh it when
dependencies change.

## Debug APK release

A debug release follows the AndroidCatEars precedent and needs no production
keystore. It is an installable APK for sideloading and testing, not a Play Store
artifact. One command does the whole flow:

```sh
tool/release_debug.sh --dry-run   # checks, build, verification, prints the notes
tool/release_debug.sh             # same, then tags debug-vX.Y.Z-buildN and publishes
```

1. Start from a `main` commit for which `./localPipeline.sh` passed, bumped
   with `tool/bump_version.sh`, committed and pushed.
2. The script refuses to continue unless it is on `main`, the tree is clean,
   `HEAD` equals `origin/main`, `gh` is authenticated, the tag
   `debug-vX.Y.Z-buildN` exists neither locally nor on `origin`, and
   `android/key.properties` is absent (that would be a production-signed build).
3. It builds with `tool/build_apk.sh --commit <12-char sha>`, then verifies
   `SHA256SUMS`, the package name, `versionName`/`versionCode` against
   `pubspec.yaml`, the absence of `android.permission.INTERNET` (`aapt2`) and the
   `CN=Android Debug` signature (`apksigner`). The tools come from
   `$ANDROID_HOME`, `$ANDROID_SDK_ROOT` or
   `~/Android/Sdk/build-tools/36.0.0`.
4. It renders release notes (debug warning, installation, commit, version,
   API levels, certificate and APK SHA-256, permissions, the `CHANGELOG.md`
   entry), creates and pushes the annotated tag and runs `gh release create
   --latest` with the APK, `SHA256SUMS` and `VERSION`. The release is not a
   prerelease because the README download badge follows `/releases/latest`.

### Why debug releases are built locally

Android only installs an update over an existing app when the signing
certificate matches. GitHub runners generate a fresh debug keystore for every
run, so a CI-built debug APK could never update an earlier one. Debug releases
are therefore signed with this machine's `~/.android/debug.keystore`
(certificate SHA-256 `C5:55:29:41:…:4F:49`); the digest is printed in every
release's notes. **Risk:** if that keystore is lost, testers must uninstall
Raumfreund once before they can install a new debug release. Back it up like a
key, but never commit it.

The tag must not match the production `v*` trigger. The title, artifact name and
notes must say **debug**; the release must not be presented as Google Play or
production signed. It may be the latest GitHub release so the README download
link remains useful. No Android signing secrets are required for this path.

Rollback means marking the affected release as a prerelease, documenting the
problem, fixing forward with a new version/build number and publishing a new
tag. Published Android version codes are never reused.
