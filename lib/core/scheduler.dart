// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

/// Handle of a callback scheduled with [TimerScheduler.schedule].
abstract interface class ScheduledCallback {
  /// Prevents the callback from running. Idempotent; a no-op after it ran.
  void cancel();
}

/// Source of one-shot delayed callbacks.
///
/// Application logic that must react to the *absence* of events (e.g. a
/// recorder that delivers no samples) uses this interface instead of
/// creating `Timer`s itself, so tests can drive it together with a fake
/// `MonotonicClock` and no real time passes.
abstract interface class TimerScheduler {
  /// Runs [callback] once after [delay] unless the returned handle is
  /// cancelled first.
  ScheduledCallback schedule(Duration delay, void Function() callback);
}

/// [TimerScheduler] backed by `dart:async` [Timer]s.
final class DartTimerScheduler implements TimerScheduler {
  /// Creates the scheduler.
  const DartTimerScheduler();

  @override
  ScheduledCallback schedule(Duration delay, void Function() callback) =>
      _TimerCallback(Timer(delay, callback));
}

final class _TimerCallback implements ScheduledCallback {
  _TimerCallback(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}
