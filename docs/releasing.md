<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Releasing

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
debug-signed artifact as a public release.

Rollback means marking the affected release as a prerelease, documenting the
problem, fixing forward with a new version/build number and publishing a new
tag. Published Android version codes are never reused.
