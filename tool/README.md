<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# tool/ – development scripts and pinned tooling

All scripts run from any working directory, are documented in their header
comment (purpose, usage, exit codes) and pass ShellCheck and `shfmt -d`.
Downloaded tools live in `.toolchain/` (git-ignored); nothing is installed
globally. Supported platform for downloads: **Linux x86_64** only.

## Scripts

| Script | Purpose | Exit codes |
| --- | --- | --- |
| `flutter.sh` | Runs the Flutter SDK pinned in `.flutter-version` (downloaded to `.toolchain/flutter`; `RAUMFREUND_FLUTTER_ROOT` reuses an existing SDK of exactly that version). `--ensure` only installs and prints the SDK path. | exit code of `flutter`; 2 on version mismatch or download error |
| `install_tools.sh` | Installs the pinned lint/security tools (table below) into `.toolchain/bin`, the Python venv into `.toolchain/venv` and markdownlint-cli into `tool/node/node_modules`. Idempotent; prints a version table. `--check` only verifies. | 0 ok; 1 `--check` found a missing/wrong version; 2 usage, platform, download or checksum error |
| `check_function_length.sh` | Enforces max. 100 physical lines per function (`--max N` to override) with both parser-based checkers over `lib/`, `test/`, `integration_test/`, `tool/`, `android/app/src/` and every `*.sh`. | 0 ok; 1 violations; 2 usage, setup or parse error |
| `check_secrets.sh` | Scans Git history and the source worktree with gitleaks without copying ignored SDK/build caches. | gitleaks status; 2 if the pinned tool is absent |
| `kotlin_lint.sh` | Runs pinned ktlint and detekt over the Android Kotlin sources. | tool status; 2 if a tool is absent |
| `check_privacy.sh` | Privacy gate: release APK permissions against an allowlist (`aapt2 dump badging`), forbidden audio-persisting/network APIs in Kotlin and Dart, network/analytics dependencies in `pubspec.yaml`. `--source-only`, `--apk-only`, `--apk FILE`. Pipeline step `privacy`. | 0 ok; 1 violation; 2 usage/missing APK or aapt2 |
| `build_apk.sh` | Builds named release-mode APK/AAB artifacts, checksums and version metadata in `dist/`; unsigned local builds are explicitly `-debugsigned`. | 0 success; 1 build failure; 2 usage |
| `release_debug.sh` | One-command public debug APK release: preconditions, local build with this machine's debug keystore (CI keystores differ per run and could not update installs), verification, notes, tag and `gh release create --latest`; `--dry-run` skips tag/push/publish. | 0 success; 1 precondition/build/verification failure; 2 usage/tool missing |
| `write_signing_config.sh` | Materializes/removes ignored Android signing files from CI secrets. | 0 success; 1 missing/invalid secret |
| `check_release_version.sh` | Checks tag, pubspec, changelog and monotonic build consistency. | 0 valid; 1 inconsistent; 2 usage |
| `write_release_notes.sh` | Renders concise notes for a verified artifact directory. | 0 success; 1 missing artifacts; 2 usage |
| `publish_release.sh` | Creates one GitHub Release from verified notes and artifacts. | `gh` status; 1 missing files; 2 usage/tool missing |
| `docker_check.sh` | Builds/starts the APK server and verifies health, version, download, checksum and APK structure. | 0 success; 1 failed check; 2 usage/Docker missing |

Typical first run:

```sh
tool/flutter.sh --ensure
tool/install_tools.sh
tool/check_function_length.sh
```

`lib/android_sdk.sh` is a sourced helper (not executable) that finds the newest
Android build-tools; `release_debug.sh` and `check_privacy.sh` share it.

## Pinned binary tools

`install_tools.sh` downloads each artifact, verifies its SHA-256 and refuses
to install on mismatch. The pinned sums were taken from the sources listed
here and cross-checked against the downloaded files.

| Tool | Version | Artifact | Checksum source |
| --- | --- | --- | --- |
| shfmt | 3.14.1 | GitHub release `mvdan/sh` `shfmt_v3.14.1_linux_amd64` | GitHub release asset digest (the project publishes no sums file) |
| actionlint | 1.7.12 | GitHub release `rhysd/actionlint` `actionlint_1.7.12_linux_amd64.tar.gz` | `actionlint_1.7.12_checksums.txt` (matches asset digest) |
| gitleaks | 8.30.1 | GitHub release `gitleaks/gitleaks` `gitleaks_8.30.1_linux_x64.tar.gz` | `gitleaks_8.30.1_checksums.txt` (matches asset digest) |
| osv-scanner | 2.6.0 | GitHub release `google/osv-scanner` `osv-scanner_linux_amd64` | `osv-scanner_SHA256SUMS` (matches asset digest) |
| ktlint | 1.8.0 | GitHub release `ktlint/ktlint` `ktlint` (self-executing jar) | GitHub release asset digest |
| detekt-cli | 1.23.8 | Maven Central `io.gitlab.arturbosch.detekt:detekt-cli:1.23.8:all` | Maven Central `.sha256` file |

detekt is taken from Maven Central because its GitHub release (published
before GitHub computed asset digests) has no checksum, and that jar differs
byte-wise from the Maven Central one. `.toolchain/bin/detekt` is a generated
wrapper (`java -jar …`). ktlint and detekt need `java` on `PATH`.

To update a tool: change version, URL and SHA-256 in the `tools` array of
`install_tools.sh`, taking the sum from the project's published checksum file
(`gh api repos/<owner>/<repo>/releases/tags/<tag>` also lists asset digests).

## Python tooling

- `requirements-dev.in` – direct tools at exact versions: ruff, mypy, pytest,
  pytest-cov, yamllint, tree-sitter, tree-sitter-kotlin, tree-sitter-bash.
- `requirements-dev.txt` – generated, hash-locked closure; installed with
  `uv pip sync --require-hashes`. Regenerate after editing the `.in` file:

  ```sh
  uv pip compile --python-version 3.13 --generate-hashes --universal \
    tool/requirements-dev.in -o tool/requirements-dev.txt
  ```

- `pyproject.toml` – ruff (curated rule set), mypy `--strict` and pytest
  (coverage floor 95 % for `fnlen.py`) configuration.

```sh
.toolchain/venv/bin/ruff check tool
.toolchain/venv/bin/ruff format --check tool
.toolchain/venv/bin/mypy --config-file tool/pyproject.toml tool/function_length
.toolchain/venv/bin/pytest -c tool/pyproject.toml
```

## Node tooling

`node/package.json` and `node/package-lock.json` pin markdownlint-cli 0.49.1
(lock file carries integrity hashes; requires Node.js ≥ 22). Configuration:
`/.markdownlint.jsonc` and `/.markdownlintignore`.

```sh
tool/node/node_modules/.bin/markdownlint "**/*.md"
.toolchain/venv/bin/yamllint --strict .
```

## Function-length checkers (`function_length/`)

Both checkers count **physical lines** from the first line of the signature
(annotations, decorators and doc comments before it are not counted) to the
closing brace inclusive, so blank lines and comments count. Nested functions
are reported on their own and also count towards the enclosing function.
Output format: `path:line: <name> has N lines (max M)`; exit codes 0 = ok,
1 = violations, 2 = usage, missing path or parse error. Both are parser-based;
no regular expressions decide what a function is.

| Checker | Languages | Parser | Measured constructs |
| --- | --- | --- | --- |
| `function_length/dart/` (`dart run bin/check.dart --max 100 <paths…>`) | Dart | `package:analyzer` 14.4.0 AST | functions, methods, constructors (incl. factory and primary constructor bodies), getters, setters, local functions, closures (e.g. in widget `build`) |
| `function_length/fnlen.py` (`fnlen.py --max 100 <paths…>`) | Kotlin, Bash, Python | tree-sitter-kotlin 1.1.0, tree-sitter-bash 0.25.1, stdlib `ast` | Kotlin: `fun` (incl. local), lambdas, anonymous functions, `init` blocks, secondary constructors, property accessors; Bash: function definitions; Python: `def`/`async def`, lambdas |

Excluded: `*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/**` and the
directories `.dart_tool`, `.toolchain`, `build`, `node_modules` (plus
`.git`, `.gradle`, `.venv` and Python caches for `fnlen.py`). Python bodies
end on their last statement because Python has no closing brace.

Tests generate their 99/100/101-line and nested fixtures at runtime so that
the repository's own check never sees intentionally oversized functions:

```sh
dart="$(tool/flutter.sh --ensure)/bin/dart"
(cd tool/function_length/dart && "${dart}" pub get --enforce-lockfile && "${dart}" test)
.toolchain/venv/bin/pytest -c tool/pyproject.toml
```

Known limitation: the tree-sitter Kotlin grammar rejects some valid Kotlin,
e.g. class bodies with members on a single line (`class A { fun f() {} }`).
Such files make `fnlen.py` exit with 2 (parse error) instead of passing
silently; format the code across lines (ktlint does this) to resolve it.
