<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Building

Linux needs Bash, Git, curl, xz, JDK 21 and Android SDK API 36. The repository
downloads the pinned Flutter SDK and auxiliary tools into ignored `.toolchain/`
directories.

```sh
./localPipeline.sh
tool/build_apk.sh --commit "$(git rev-parse --short=12 HEAD)"
```

The second command writes a release-mode APK, checksum and version into
`dist/`. Without `android/key.properties` its name includes `-debugsigned`.
That artifact can be installed directly for testing but is not a public
production release.

Run `docker build -t raumfreund .` to create the nginx download image, or
`tool/docker_check.sh` to build and exercise its health page, APK and checksum.
The Docker route is the portable choice on hosts without a local Android SDK.
