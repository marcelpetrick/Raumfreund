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

## Debug APK release

A debug release follows the AndroidCatEars precedent and needs no production
keystore. It is an installable APK for sideloading and testing, not a Play Store
artifact:

1. Start from a clean `main` commit for which `./localPipeline.sh` passed.
2. Build with `tool/build_apk.sh --commit "$(git rev-parse --short=12 HEAD)"`.
3. Verify `dist/SHA256SUMS`, the package/version with `aapt`, and the APK debug
   certificate with `apksigner`.
4. Publish a GitHub release using a non-production tag such as
   `debug-vX.Y.Z-buildN`. Upload the `-debugsigned.apk` and `SHA256SUMS` files.
5. State the source commit, minimum Android version, checksum, debug-certificate
   status and sideloading purpose in the release notes.

The tag must not match the production `v*` trigger. The title, artifact name and
notes must say **debug**; the release must not be presented as Google Play or
production signed. It may be the latest GitHub release so the README download
link remains useful. No Android signing secrets are required for this path.

Rollback means marking the affected release as a prerelease, documenting the
problem, fixing forward with a new version/build number and publishing a new
tag. Published Android version codes are never reused.
