// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:collection';

import 'level_history_point.dart';
import 'thresholds.dart';
import 'zone.dart';

/// RAM-only timeline of estimated levels for the "heartbeat" chart.
///
/// Samples are aggregated into 1-second buckets that keep the *maximum*
/// level of the bucket, so short peaks stay visible. A bucket's point is
/// stamped with the bucket start (whole seconds of the monotonic clock).
/// Only values are stored – never audio – and nothing is persisted.
///
/// Seconds without samples simply have no bucket; [segments] splits the
/// points where the chart must draw a break.
final class LevelHistory {
  /// Creates an empty history covering [window].
  LevelHistory({this.window = defaultWindow});

  /// Default visible time span.
  static const Duration defaultWindow = Duration(minutes: 30);

  /// Length of one aggregation bucket.
  static const Duration bucket = Duration(seconds: 1);

  /// Two neighbouring points farther apart than this belong to different
  /// segments (1.5 buckets: tolerates jitter, detects a missing bucket).
  static const Duration breakDistance = Duration(milliseconds: 1500);

  /// Time span kept relative to the latest bucket.
  final Duration window;

  final ListQueue<LevelHistoryPoint> _points = ListQueue<LevelHistoryPoint>();
  List<LevelHistoryPoint>? _cached;

  /// Chronological, unmodifiable list of bucket maxima.
  List<LevelHistoryPoint> get points =>
      _cached ??= List<LevelHistoryPoint>.unmodifiable(_points);

  /// Whether no point is stored.
  bool get isEmpty => _points.isEmpty;

  /// Adds a sample. Samples older than the latest bucket are ignored
  /// (the clock is monotonic, so this only guards against misuse).
  void add({required Duration timestamp, required double levelDb}) {
    if (!levelDb.isFinite) return;
    final start = _bucketStart(timestamp);
    final last = _points.isEmpty ? null : _points.last;
    if (last != null && start < last.timestamp) return;
    if (last != null && start == last.timestamp) {
      if (levelDb <= last.levelDb) return;
      _points.removeLast();
    }
    _points.addLast(LevelHistoryPoint(timestamp: start, levelDb: levelDb));
    _evict(start);
    _cached = null;
  }

  /// Removes all points.
  void clear() {
    _points.clear();
    _cached = null;
  }

  /// Splits [points] into runs without breaks (neighbours at most
  /// [breakDistance] apart). Each run is unmodifiable.
  List<List<LevelHistoryPoint>> segments() {
    final result = <List<LevelHistoryPoint>>[];
    var current = <LevelHistoryPoint>[];
    for (final point in _points) {
      if (current.isNotEmpty &&
          point.timestamp - current.last.timestamp > breakDistance) {
        result.add(List.unmodifiable(current));
        current = <LevelHistoryPoint>[];
      }
      current.add(point);
    }
    if (current.isNotEmpty) result.add(List.unmodifiable(current));
    return List.unmodifiable(result);
  }

  /// Summary for accessibility texts; null when empty.
  LevelHistorySummary? summarize(Thresholds thresholds) {
    if (_points.isEmpty) return null;
    var max = double.negativeInfinity;
    var sum = 0.0;
    final counts = {for (final zone in Zone.values) zone: 0};
    for (final point in _points) {
      if (point.levelDb > max) max = point.levelDb;
      sum += point.levelDb;
      final zone = thresholds.classify(point.levelDb);
      counts[zone] = counts[zone]! + 1;
    }
    final total = _points.length;
    return LevelHistorySummary(
      maxDb: max,
      averageDb: sum / total,
      zoneShare: Map.unmodifiable({
        for (final entry in counts.entries) entry.key: entry.value / total,
      }),
      coveredDuration: bucket * total,
    );
  }

  static Duration _bucketStart(Duration timestamp) {
    final micros = bucket.inMicroseconds;
    final index = (timestamp.inMicroseconds / micros).floor();
    return Duration(microseconds: index * micros);
  }

  void _evict(Duration latest) {
    final oldest = latest - window;
    while (_points.first.timestamp < oldest) {
      _points.removeFirst();
    }
  }
}

/// Aggregated numbers of a [LevelHistory] (bucket maxima).
final class LevelHistorySummary {
  /// Creates a summary.
  const LevelHistorySummary({
    required this.maxDb,
    required this.averageDb,
    required this.zoneShare,
    required this.coveredDuration,
  });

  /// Highest bucket maximum.
  final double maxDb;

  /// Mean of the bucket maxima.
  final double averageDb;

  /// Share (0..1) of measured seconds per zone; sums to 1.
  final Map<Zone, double> zoneShare;

  /// Measured time (number of buckets × 1 s), excluding gaps.
  final Duration coveredDuration;
}
