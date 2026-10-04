<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Google Play readiness

The app targets Android API 36, supports Android 7.0+, builds an AAB in the
release workflow and has no Internet permission, tracking or stored audio.

Owner-controlled work remains before Play publication: create the Play Console
application, finish developer verification, supply store text/screenshots and
a public privacy-policy URL, complete Data Safety/content-rating/target-audience
forms, configure app signing and run the closed-test/device acceptance plan.

Play upload is intentionally not automated until those credentials and policy
decisions exist. The GitHub release APK remains a separate direct-download
channel.
