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
| `lib/features/monitor/domain/` | Zones, zone hysteresis, validated thresholds, peak envelope, history and alarm rules | Implemented and unit-tested |
| `lib/features/monitor/application/` | Permission/start/stop/session controller and platform ports | Implemented and unit-tested |
| `lib/features/monitor/infrastructure/` | Channel adapters | Implemented with protocol tests |
| `lib/features/monitor/presentation/` | Main monitor, gauge, Mia and timeline | Implemented for phone/tablet layouts |
| `lib/features/settings/` | Valid settings, persistence and Settings view | Implemented with schema validation |
| `lib/features/shop/` | Kitty accessory catalog, star wallet and inventory, persistence, shop controller and shop page | Implemented with schema validation |
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
  -> calibration (raw estimated level)
  -> alarm state machine
       -> zone hysteresis: raw zone per sample -> confirmed zone
       -> phases, countdown and the one alarm per phase
  -> peak envelope -> calmer gauge value and 10-minute timeline
  -> immutable monitor state (confirmed zone drives UI, stars and Mia)
  -> Flutter widgets
```

The raw PCM window is released immediately after its level is calculated. Only
numeric levels may cross the platform channel. Display smoothing and the
timeline envelope must never feed back into the alarm timer; the alarm works on
raw levels through the zone hysteresis only. Exact measurement semantics live in
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

The pure domain state machine owns zones, phases and elapsed monotonic time;
the application controller owns the asynchronous alarm output. The machine
first passes every raw zone through the zone hysteresis
([ADR 0004](adr/0004-zone-hysteresis.md)): a zone is entered when at least
50 % of the last second is at or above it and left only when it falls below
15 % of the last 3 s. Only this confirmed zone is exposed, so the traffic
light, quiet stars and Mia never disagree with the alarm phase.

A phase starts at the first sample of the loud run that led to its confirmed
zone. Dips inside the phase count, a quiet tail does not, and the alarm fires
only on a loud sample once the configured delay (3–60 s, default 10 s) has
passed, at most once per phase. A confirmed green zone, gaps over one second,
long stretches of too few samples and session termination reset continuity.

While the app's own tone/vibration is active, readings are dropped entirely:
they neither advance the alarm nor reach the gauge, timeline or stars.
Completion resets continuity, and a new phase can begin only on a later valid
sample. This keeps the alarm from retriggering on its own sound. Mia leaves
when a red phase alarms and returns only on a settled green zone.

## Settings and persistence

`AppSettings` is always valid in memory. Infrastructure must validate every
persisted field independently, carry a schema version and fall back safely for
missing or invalid values. Future migrations are explicit and tested.

The Settings view edits a draft. Save validates and writes atomically; cancel
does not mutate active or persisted settings. Threshold changes never affect a
running session because navigation stops measurement first. Settings schema 3
adds the off-by-default quick-star test flag; version 2 data migrates with that
flag disabled. Applying it changes the `QuietStars` interval for the next
measurement from 60 seconds to 5 seconds (or back), resets only partial
progress and keeps every already-earned session and wallet star.

## Star shop

`lib/features/shop/` follows the settings pattern: an immutable, always-valid
`StarWallet` (balance, owned and equipped items; typed `PurchaseResult`),
a `ShopRepository` port, `SharedPreferencesShopRepository` (own `shop.`
namespace, one JSON snapshot, schema version 1, per-field repair, corrupt
data loads an empty wallet) and `ShopController`, which applies
changes immediately, saves them serialized and coalesced, and reports save
failures in `saveFailed` instead of throwing. Unavailable or unreadable
storage and data of a newer schema make `load()` throw; the controller then
sets `loadFailed`, keeps earning in memory, never saves, and merges the earned
stars into the stored wallet once a later load succeeds, so stored stars are
never overwritten by a wallet that was not read. `retryPending()` (called on
app resume and when the shop opens) retries a failed load or save. The
teacher reset waits for the save and reports a failure.

Dependency direction: shop domain, application and infrastructure depend on
nothing but the shared `PreferencesStore` abstraction of settings. The only
shop type the monitor feature imports is the `KittyAccessory` contract, which
its kitty renderer draws; the shop page in turn reuses the kitty widget and
item names from the monitor presentation. Monitor domain and application
never import shop. The monitor reports every earned quiet-minute star through the
`StarEarnedSink` port (default no-op), and the composition root connects it
to `ShopController.earn(1)`. Stars of a session that run before the wallet
has loaded are added to it after loading.

`RaumfreundApp` owns the `ShopController` (injectable `shopRepository` and
`monitorFactory` seams for tests), calls `load()` at startup and maps
`wallet.equipped` into `MonitorViewData.kittyAccessories`. The monitor's
third app-bar action opens `ShopPage` through the same `_navigate` helper as
Settings and About, so measurement is stopped first and never restarted. The
teacher reset is passed to `SettingsPage` as a plain callback
(`onResetStars: _resetStars`); it acts at once, is deliberately not part of the
Save/Cancel draft, waits for the wallet save and reports storage failure. Until
the wallet has loaded successfully, shop actions are disabled even if stars
were earned in memory, so a button never offers an operation the controller
must refuse.

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
