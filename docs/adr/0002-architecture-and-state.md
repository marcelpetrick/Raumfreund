# ADR 0002 – Architecture and state handling

- Status: accepted
- Date: 2026-10-03

## Context

The vision (§6) requires a small architecture separating presentation,
application control, pure domain logic and infrastructure, a zone/alarm state
machine that is testable without widgets, microphone or a real clock, explicit
session states, idempotent cleanup and session ids against stale events.

## Decision

- Feature folders `lib/features/{monitor,settings,about}` with the layers
  `domain/` (pure Dart, no Flutter imports), `application/` (controllers,
  ports), `infrastructure/` (platform channel adapters, persistence) and
  `presentation/` (widgets). `lib/app/` composes everything (composition root);
  `lib/core/` holds cross-cutting basics such as `MonotonicClock`.
- State management with plain `ChangeNotifier` controllers and immutable state
  objects – no state-management package. The app is small; fewer dependencies
  mean fewer license and maintenance risks.
- All platform access goes through narrow ports
  (`lib/features/monitor/application/ports.dart`). Tests use fakes; production
  uses method/event channel adapters following `docs/platform-channels.md`.
- Time is injected (`MonotonicClock`); domain functions receive timestamps.
- Every measurement session gets an increasing id; events of other sessions
  are discarded.
- Settings persistence uses `shared_preferences` (BSD-3-Clause, maintained by
  the Flutter team) with a schema version and per-field validation.

## Consequences

- Domain and application logic reach high coverage with fast unit tests.
- Widgets receive plain view data and callbacks, which makes golden tests and
  layout tests deterministic.
- Adding a platform (out of scope for v1) would only need new adapters.
