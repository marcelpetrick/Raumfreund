// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Zone hysteresis: fast attack, slow release (ADR 0004).
///
/// A level hovering around a threshold makes the raw zone flicker several
/// times per second, and loud rooms have pauses (bursts of shouting). Driving
/// the UI and the alarm phase from the raw zone lets the traffic light flicker
/// and can postpone the alarm forever. The debouncer therefore decides from
/// the *time share* of recent raw samples at or above each zone, judged over
/// two windows: noise peaks are entered quickly, but the room needs time to
/// cool down.
///
/// Definitions (all times are sample timestamps, no real clock):
///
/// * Each sample covers the interval since the previous sample of its run
///   (the recorder's level describes the window ending at the sample),
///   capped at [ZoneDebouncer.maxSampleWeight] (2× the nominal 100 ms), so
///   a delayed sample cannot stand for a whole stall.
/// * `share_W(L)` is the time share of the covered part of window W that
///   samples with raw zone `>= L` cover. A window is *usable* once at least
///   half of it is covered.
/// * Attack window A = the last [ZoneDebouncer.holdTime] (1 s); release
///   window R = the last [ZoneDebouncer.releaseTime] (3 s). Only R's samples
///   are kept in memory.
/// * A *run* is a sequence of samples without a gap; the first sample after
///   construction, [ZoneDebouncer.reset] or a gap (more than
///   [ZoneDebouncer.maxGap], or a timestamp going backwards) starts one. It
///   is adopted immediately as confirmed zone, but not yet *settled*, and is
///   held for at least `holdTime` (no decisions before). Samples that stay
///   too sparse to make the release window usable for longer than
///   `releaseTime` (e.g. one per second) are treated like a gap as well.
/// * A zone L *holds* if `share_R(L) >= leaveShare` or
///   `share_A(L) >= enterShare`; green always holds.
///
/// Rules for the confirmed zone C:
///
/// * Up (fast, A usable): let Z be the highest zone above C with
///   `share_A(Z) >= enterShare` (50 %). Z is confirmed with the next sample
///   whose raw zone is `>= Z`.
/// * Down (slow, R usable): if C does not hold, the target is the highest
///   lower zone that holds. Yellow is confirmed with the next yellow sample;
///   green at once.
/// * Otherwise C is kept, and its phase continues.
///
/// Phase start ([ZoneDecision.since]) of a newly confirmed zone Z is the
/// first sample of the current contiguous run of raw samples in Z's range
/// (`>= Z` going up; yellow going down from red). Because the confirming
/// sample must itself be in range, every sample between phase start and
/// confirmation is in that range, so the alarm cannot fire before
/// `alarmDelay` of such samples.
library;

import 'dart:collection';

import 'zone.dart';

/// Result of feeding one sample into a [ZoneDebouncer].
final class ZoneDecision {
  /// Creates a decision.
  const ZoneDecision({
    required this.zone,
    required this.since,
    required this.started,
    required this.settled,
    required this.usable,
  });

  /// Confirmed zone after the sample.
  final Zone zone;

  /// Phase start of the confirmed zone (see the library documentation).
  final Duration since;

  /// True if this sample began a new confirmed zone (run start or a
  /// confirmed change). Consumers restart their phase then.
  final bool started;

  /// Whether [zone] is backed by the windows: always after a confirmed
  /// change; for an immediately adopted zone only once a usable release
  /// window shows it as the highest holding zone. Used where a single
  /// sample must not count, e.g. Mia's return after the alarm tone.
  final bool settled;

  /// Whether the release window is at least half covered. While it is not,
  /// the data is too thin for an alarm decision.
  final bool usable;
}

/// One sample's weighted coverage `(start, end]` with its raw zone.
final class _Interval {
  const _Interval(this.start, this.end, this.zone);

  final Duration start;
  final Duration end;
  final Zone zone;
}

/// Covered time and time at or above each zone (by [Zone.index]) of one
/// window, in microseconds.
final class _Window {
  _Window(this.start, this.length);

  final Duration start;
  final Duration length;
  int covered = 0;
  final List<int> atLeast = [0, 0, 0];

  void add(_Interval interval) {
    final from = interval.start > start ? interval.start : start;
    final micros = (interval.end - from).inMicroseconds;
    if (micros <= 0) return;
    covered += micros;
    for (var level = 0; level <= interval.zone.index; level++) {
      atLeast[level] += micros;
    }
  }

  bool get usable => covered * 2 >= length.inMicroseconds;

  double share(Zone zone) => covered == 0 ? 0 : atLeast[zone.index] / covered;
}

/// Fast-attack, slow-release zone hysteresis. Pure Dart; see the library
/// documentation for the rules.
final class ZoneDebouncer {
  /// Creates a debouncer without a confirmed zone. Throws an
  /// [ArgumentError] for non-positive times, `releaseTime < holdTime`, or
  /// shares outside `(0, 1]`.
  ZoneDebouncer({
    this.holdTime = defaultHoldTime,
    this.releaseTime = defaultReleaseTime,
    this.maxGap = defaultMaxGap,
    this.maxSampleWeight = defaultMaxSampleWeight,
    this.enterShare = defaultEnterShare,
    this.leaveShare = defaultLeaveShare,
  }) {
    if (holdTime <= Duration.zero || maxSampleWeight <= Duration.zero) {
      throw ArgumentError('holdTime and maxSampleWeight must be positive');
    }
    if (releaseTime < holdTime) {
      throw ArgumentError('releaseTime must not be shorter than holdTime');
    }
    final sharesValid =
        0 < leaveShare && leaveShare <= 1 && 0 < enterShare && enterShare <= 1;
    if (!sharesValid) throw ArgumentError('shares must lie in (0, 1]');
  }

  /// Attack window: entering a zone needs 50 % of it.
  static const Duration defaultHoldTime = Duration(seconds: 1);

  /// Release window: leaving a zone needs it to drop below 15 % here.
  static const Duration defaultReleaseTime = Duration(seconds: 3);

  /// Largest distance between two samples that still counts as continuous;
  /// equal to the alarm machine's default.
  static const Duration defaultMaxGap = Duration(seconds: 1);

  /// Largest time one sample may stand for (2× the nominal 100 ms).
  static const Duration defaultMaxSampleWeight = Duration(milliseconds: 200);

  /// Share of the attack window needed to enter a zone.
  static const double defaultEnterShare = 0.5;

  /// Share of the release window below which a zone is left. Chosen between
  /// a quiet room with clicks (7 green : 1 red = 12.5 % must become green)
  /// and the worst 3 s alignment of 0.6 s bursts every 2 s (20 %, must stay
  /// loud).
  static const double defaultLeaveShare = 0.15;

  /// See [defaultHoldTime].
  final Duration holdTime;

  /// See [defaultReleaseTime].
  final Duration releaseTime;

  /// See [defaultMaxGap].
  final Duration maxGap;

  /// See [defaultMaxSampleWeight].
  final Duration maxSampleWeight;

  /// See [defaultEnterShare].
  final double enterShare;

  /// See [defaultLeaveShare].
  final double leaveShare;

  final Queue<_Interval> _samples = ListQueue<_Interval>();
  Zone? _confirmed;
  Duration? _since;
  bool _settled = false;
  Duration? _runStart;
  Duration? _lastSample;
  // Starts of the current contiguous raw runs (null if the last sample is
  // outside the range): raw >= yellow, raw == red, raw == yellow.
  Duration? _atLeastYellowSince;
  Duration? _redSince;
  Duration? _yellowSince;
  bool _usable = false;
  Duration? _unusableSince;

  /// Confirmed zone; null before the first sample or after [reset].
  Zone? get zone => _confirmed;

  /// Number of samples kept (bounded by one release window).
  int get windowLength => _samples.length;

  /// Feeds the raw [zone] of one valid sample at monotonic [timestamp].
  ZoneDecision onSample({required Duration timestamp, required Zone zone}) {
    final last = _lastSample;
    _lastSample = timestamp;
    final continuous =
        last != null &&
        timestamp >= last &&
        timestamp - last <= maxGap &&
        _confirmed != null;
    if (!continuous) return _adopt(zone, timestamp);
    if (timestamp > last) {
      final capped = timestamp - last > maxSampleWeight
          ? timestamp - maxSampleWeight
          : last;
      _samples.add(_Interval(capped, timestamp, zone));
    }
    _trackRuns(zone, timestamp);
    final releaseStart = timestamp - releaseTime;
    while (_samples.isNotEmpty && _samples.first.end <= releaseStart) {
      _samples.removeFirst();
    }
    final attack = _Window(timestamp - holdTime, holdTime);
    final release = _Window(releaseStart, releaseTime);
    for (final sample in _samples) {
      attack.add(sample);
      release.add(sample);
    }
    _usable = release.usable;
    if (_usable) {
      _unusableSince = null;
    } else {
      // Sparse but formally continuous samples: the windows never fill, so
      // the zone would freeze. Treat that like a gap.
      final since = _unusableSince ??= timestamp;
      if (timestamp - since > releaseTime) return _adopt(zone, timestamp);
    }
    if (timestamp - _runStart! < holdTime) return _decision(started: false);
    return _decide(zone, timestamp, attack, release);
  }

  /// Forgets the confirmed zone, the samples and all runs.
  void reset() {
    _samples.clear();
    _confirmed = null;
    _since = null;
    _settled = false;
    _runStart = null;
    _lastSample = null;
    _atLeastYellowSince = _redSince = _yellowSince = null;
    _usable = false;
    _unusableSince = null;
  }

  ZoneDecision _adopt(Zone zone, Duration timestamp) {
    reset();
    _lastSample = timestamp;
    _runStart = timestamp;
    _trackRuns(zone, timestamp);
    _confirmed = zone;
    _since = timestamp;
    return _decision(started: true);
  }

  void _trackRuns(Zone zone, Duration t) {
    _atLeastYellowSince = zone != Zone.green ? _atLeastYellowSince ?? t : null;
    _redSince = zone == Zone.red ? _redSince ?? t : null;
    _yellowSince = zone == Zone.yellow ? _yellowSince ?? t : null;
  }

  ZoneDecision _decide(Zone raw, Duration t, _Window attack, _Window release) {
    final current = _confirmed!;
    if (attack.usable) {
      for (final up in [Zone.red, Zone.yellow]) {
        if (up.index <= current.index) break;
        if (attack.share(up) < enterShare) continue;
        // Wait for a sample in range, so the phase never starts on a dip.
        if (raw.index < up.index) return _decision(started: false);
        final since = up == Zone.red ? _redSince! : _atLeastYellowSince!;
        return _confirm(up, since);
      }
    }
    if (!release.usable) return _decision(started: false);
    bool holds(Zone zone) =>
        zone == Zone.green ||
        release.share(zone) >= leaveShare ||
        (attack.usable && attack.share(zone) >= enterShare);
    final highest = Zone.values.lastWhere(holds);
    if (holds(current)) {
      _settled = _settled || highest == current;
      return _decision(started: false);
    }
    final target = Zone.values.lastWhere(
      (z) => z.index < current.index && holds(z),
    );
    if (target == Zone.green) return _confirm(Zone.green, t);
    if (raw != Zone.yellow) return _decision(started: false);
    return _confirm(Zone.yellow, _yellowSince!);
  }

  ZoneDecision _confirm(Zone zone, Duration since) {
    _confirmed = zone;
    _since = since;
    _settled = true;
    return _decision(started: true);
  }

  ZoneDecision _decision({required bool started}) => ZoneDecision(
    zone: _confirmed!,
    since: _since!,
    started: started,
    settled: _settled,
    usable: _usable,
  );
}
