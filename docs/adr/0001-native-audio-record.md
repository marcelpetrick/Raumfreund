<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0001 – Native Android AudioRecord implementation

- Status: accepted; implemented
- Date: 2026-10-03

## Context

Raumfreund needs a continuous stream of short microphone-level windows, strict
lifecycle cleanup and a stable session identifier. It must process samples only
in RAM, distinguish permission failures from recorder failures, and avoid a
third-party plugin becoming the owner of concurrency or lifecycle behavior.

Available Flutter microphone plugins primarily target recording or media files.
They add a larger dependency and permission surface, and their lifecycle and raw
window semantics are not necessarily the ones required by the alarm rules.

## Decision

Implement the Android measurement boundary as a small first-party Kotlin module
using `android.media.AudioRecord`.

- Capture mono PCM 16-bit audio on a dedicated worker, never the main thread.
- Aggregate approximately 100 ms of samples, calculate RMS and dBFS natively,
  emit only `{sessionId, dbfs}`, then discard the PCM buffer contents.
- Prefer a supported microphone source and sample rate discovered at runtime;
  failure to obtain a valid initialized recorder is reported as unavailable or
  microphone busy, not hidden behind fabricated samples.
- Keep permission, recording and alarm output in separate focused classes.
  `MainActivity` only binds them to the documented method/event channels.
- Start and stop commands are serialized. Stop is idempotent and joins or
  otherwise proves termination of the recording worker before completing.
- A new session id stops an existing recorder before starting another one.
- The native host stops recording on genuine activity stop/destruction and
  does so silently because expected backgrounding is not a recording error.
- Unexpected read failures and channel termination remain errors and converge
  on the same complete cleanup path in the Dart controller.
- No audio file, byte stream, debug dump or PCM log is permitted.

The exact channel messages are defined in `docs/platform-channels.md`. RMS,
calibration and accuracy limits are defined in `docs/measurement.md`.

## Alternatives considered

### General-purpose Flutter recording plugin

Rejected for version 1. It would reduce Kotlin code but add a dependency whose
file-oriented API, threading, lifecycle and error taxonomy still require an
adapter and extensive native verification.

### Dart-side PCM processing

Rejected. Sending raw audio through an event channel increases copying, makes
privacy review harder and couples timing-sensitive capture to Dart scheduling.

### Android decibel or speech APIs

Rejected. Android exposes digital samples, not a device-independent calibrated
dB-SPL sensor. Speech-recognition APIs would also violate the offline,
minimal-permission design.

## Consequences

The repository owns more Kotlin code and must test it with JVM, instrumented,
emulator and real-device scenarios. In return, buffer lifetime, errors, session
identity and cleanup are explicit and auditable. The module remains Android-only,
which matches the product scope.
