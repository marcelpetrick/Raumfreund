<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# Architecture

This document describes the implemented architecture. The product scope is one offline Flutter/Dart application
for Android phones and tablets. The vision remains the source of truth.

## Status and principles

The domain, controllers, native adapters, persistence and presentation are
implemented. Physical-device acceptance and public signing remain release
activities rather than architecture work.

The design follows these rules:

- Domain decisions are pure Dart and do not import Flutter or Android APIs.
- Application controllers own sessions and orchestration, not widgets.
- Platform and persistence access happens only through narrow ports.
- Time relevant to alarm continuity comes from an injected monotonic clock.
- Immutable state moves toward the UI; callbacks and commands move inward.
- Cleanup is idempotent, and late events are rejected by session id.
- Audio samples are transient input, never application data.

ADR 0002 records the layer and state-management choice. ADR 0001 chooses the
native recorder, and ADR 0003 fixes lifecycle and alarm semantics.

## Layers and dependency direction

```text
presentation (Flutter widgets, German localized strings)
       |
       v
application (controller, immutable view state, ports)
       |
       v
domain (thresholds, zones, alarm/history rules)

infrastructure implements application ports
  |- Dart MethodChannel/EventChannel adapters
  |- shared_preferences repository
  `- Android Kotlin recorder/permission/alarm services

lib/app is the composition root; lib/core contains cross-cutting primitives.
```

Presentation may depend on application and domain view types. Application may
depend on domain and port abstractions. Domain depends on neither Flutter nor
infrastructure. Infrastructure depends inward to implement ports; domain code
must never import it.

## Repository map

| Area | Responsibility | Current state |
| --- | --- | --- |
| `lib/core/` | Monotonic-clock abstraction | Foundation implemented |
| `lib/features/monitor/domain/` | Zones, validated thresholds, history and alarm rules | Implemented and unit-tested |
| `lib/features/monitor/application/` | Permission/start/stop/session controller and platform ports | Implemented and unit-tested |
| `lib/features/monitor/infrastructure/` | Channel adapters | Implemented with protocol tests |
| `lib/features/monitor/presentation/` | Main monitor, gauge, Mia and timeline | Implemented for phone/tablet layouts |
| `lib/features/settings/` | Valid settings, persistence and Settings view | Implemented with schema validation |
| `lib/features/about/` | App information and About view | Implemented |
| `lib/l10n/` | All user-visible German strings | Implemented in ARB/generated files |
| `android/app/src/main/kotlin/` | Recorder, permission, alarm and channel host | Implemented with JVM tests |

## Measurement data flow

```text
Android AudioRecord
  -> approximately 100 ms PCM window
  -> RMS and dBFS on a native worker
  -> EventChannel {sessionId, dbfs}
  -> session-id filter
  -> calibration and zone classification
  -> alarm state machine (raw decision value)
  -> independent display smoothing/history
  -> immutable monitor state
  -> Flutter widgets
```

The raw PCM window is released immediately after its level is calculated. Only
numeric levels may cross the platform channel. Display smoothing must never
feed back into the alarm timer. Exact measurement semantics live in
[`measurement.md`](measurement.md); the wire contract lives in
[`platform-channels.md`](platform-channels.md).

## Measurement session lifecycle

The application controller exposes explicit states equivalent to stopped,
permission pending, starting, measuring, stopping and error. One increasing
session id is allocated for each start attempt that reaches native recording.
Events whose id differs from the active id are ignored.

A start command is serialized so rapid taps cannot create parallel recorders.
Stop is safe in every state and awaits native cleanup. Backgrounding, navigating
to Settings or About, stream failure and disposal all converge on the same
idempotent stop path. Returning to the foreground or monitor never starts a new
session without a fresh user action.

Android temporarily pauses the activity while its own permission dialog is
visible. The controller records that a permission request is active and does
not treat that pause as a genuine background stop. After the result, recording
starts only if permission is granted, the request is still current and the app
is foregrounded. ADR 0003 defines the race-resolution rules.

## Alarm ownership

The pure domain state machine owns zone phases and elapsed monotonic time. The
application controller owns the asynchronous alarm output. A phase starts on
its first valid sample; yellow/red changes start a new phase; green, gaps over
one second and session termination reset continuity. Each phase can fire once.

While the app's own tone/vibration is active, alarm evaluation is suspended.
Completion resets continuity, and a new phase can begin only on a later valid
sample. This keeps the alarm from retriggering on its own sound.

## Settings and persistence

`AppSettings` is always valid in memory. Infrastructure must validate every
persisted field independently, carry a schema version and fall back safely for
missing or invalid values. Future migrations are explicit and tested.

The Settings view edits a draft. Save validates and writes atomically; cancel
does not mutate active or persisted settings. Threshold changes never affect a
running session because navigation stops measurement first.

## Composition and test seams

The composition root constructs production clocks, repositories and adapters,
then injects them into controllers. Tests replace each port with a deterministic
fake. Widgets receive plain immutable state and callbacks so layout and golden
tests do not need a microphone or real clock.

Critical state-machine, controller and permission-flow changes require an
independent review in addition to automated tests.

## Privacy boundaries

The release application has no account, analytics, advertising or tracking.
No component may retain PCM data, add audio to logs or introduce a network
permission without a new ADR and privacy-document update. Numeric history is
RAM-only and is cleared when the process exits. See [`privacy.md`](privacy.md).
