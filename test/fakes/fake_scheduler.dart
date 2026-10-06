// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:raumfreund/core/scheduler.dart';

import 'fake_clock.dart';

/// [TimerScheduler] driven by a [FakeClock].
///
/// Callbacks are due at `clock.now + delay` and run only from [elapse] or
/// [runDue], in due order, so tests decide exactly when time passes.
final class FakeScheduler implements TimerScheduler {
  /// Creates a scheduler on [clock].
  FakeScheduler(this.clock);

  /// Clock that defines when callbacks are due.
  final FakeClock clock;

  final List<_FakeCallback> _pending = [];

  /// Number of scheduled callbacks that neither ran nor were cancelled.
  int get pendingCount => _pending.length;

  /// Due time of the earliest pending callback, or null.
  Duration? get nextDue => _pending.isEmpty
      ? null
      : _pending.map((c) => c.due).reduce((a, b) => a < b ? a : b);

  @override
  ScheduledCallback schedule(Duration delay, void Function() callback) {
    final scheduled = _FakeCallback(clock.now + delay, callback, _pending);
    _pending.add(scheduled);
    return scheduled;
  }

  /// Advances the clock by [delta] and runs every callback due by then.
  void elapse(Duration delta) {
    clock.advance(delta);
    runDue();
  }

  /// Advances the clock by [milliseconds] (see [elapse]).
  void elapseMs(int milliseconds) =>
      elapse(Duration(milliseconds: milliseconds));

  /// Runs every callback due at the current clock time, earliest first.
  /// Callbacks scheduled while running are honoured if they are due too.
  void runDue() {
    while (true) {
      final due = _pending.where((c) => c.due <= clock.now).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      if (due.isEmpty) return;
      final next = due.first;
      _pending.remove(next);
      next.callback();
    }
  }
}

final class _FakeCallback implements ScheduledCallback {
  _FakeCallback(this.due, this.callback, this._owner);

  final Duration due;
  final void Function() callback;
  final List<_FakeCallback> _owner;

  @override
  void cancel() => _owner.remove(this);
}
