<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Contributing

Read `AGENTS.md`, `Raumfreund-VISION.md`, `docs/architecture.md` and the ADRs
before changing code. Work on `main`, keep commits atomic and use Conventional
Commit messages. Every commit needs a version/build bump through
`tool/bump_version.sh` and a green `./localPipeline.sh` run.

Public APIs and non-obvious decisions need documentation. All visible text is
German and belongs in the localization files. Hand-written source files need
the project SPDX/copyright header; functions must stay within 100 physical
lines. Never add audio retention, telemetry, secrets or a release Internet
permission.

Tests should prove behavior at the narrowest layer and preserve at least 95%
measured Dart line coverage. State what was actually run and leave physical
device checks explicitly open when they were not performed.
