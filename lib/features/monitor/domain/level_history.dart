// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:collection';

import 'level_history_point.dart';
import 'peak_envelope.dart';
import 'thresholds.dart';
import 'zone.dart';

/// RAM-only timeline of estimated levels for the "heartbeat" chart.
///
/// Every raw level first passes a [PeakEnvelope] (instant attack, slow
/// [envelopeRelease]): a peak lifts the curve at once, but it cools down
/// over several seconds instead of following every quiet sample. This
/// hysteresis is what keeps the chart calm.
///
/// The envelope is aggregated into 10-second buckets; a bucket's point is
/// the *mean* envelope value of the bucket, stamped with the bucket start
/// (multiples of [bucket] on the monotonic clock). Short peaks still raise
/// their bucket noticeably, and the cool-down is visible over the following
/// buckets. The still-open bucket is exposed as a live last point whose
/// value is refreshed at most every [liveInterval], so the chart moves at
/// 1 Hz instead of 10 Hz.
///
/// Only values are stored – never audio – and nothing is persisted.
/// Buckets without samples (stop, background) simply have no point;
/// [segments] splits the points where the chart must draw a break.
final class LevelHistory {
  /// Creates an empty history covering [window].
  LevelHistory({this.window = defaultWindow});

  /// Default visible time span: ten minutes are enough to see whether the
  /// room calmed down, while each 10 s bucket still has visible width.
  static const Duration defaultWindow = Duration(minutes: 10);

  /// Length of one aggregation bucket (one committed chart point).
  static const Duration bucket = Duration(seconds: 10);

  /// Minimum time between two updates of the live (open-bucket) point.
  static const Duration liveInterval = Duration(seconds: 1);

  /// Release time constant of the timeline envelope. With 4 s a drop has
  /// cooled down by ~63 % after 4 s and by ~95 % after 12 s, i.e. a single
  /// peak visibly lifts about two buckets.
  static const Duration envelopeRelease = Duration(seconds: 4);

  /// A pause between two samples longer than this (stop/start, background)
  /// restarts the envelope, so an old peak never leaks into a new session.
  /// Readings normally arrive every ~100 ms.
  static const Duration envelopeResetGap = Duration(seconds: 1);

  /// Two neighbouring points farther apart than this belong to different
  /// segments (1.5 buckets: tolerates jitter, detects a missing bucket).
  static const Duration breakDistance = Duration(seconds: 15);

  /// Time span kept relative to the latest bucket.
  final Duration window;

  final ListQueue<LevelHistoryPoint> _committed =
      ListQueue<LevelHistoryPoint>();
  final PeakEnvelope _envelope = PeakEnvelope(
    attack: Duration.zero,
    release: envelopeRelease,
  );
  _OpenBucket? _open;
  Duration? _lastSampleAt;
  List<LevelHistoryPoint>? _cached;

  /// Chronological, unmodifiable list of bucket means, including the live
  /// point of the open bucket. The same instance is returned until the
  /// chart content changes, so listeners can compare by identity.
  List<LevelHistoryPoint> get points => _cached ??= List.unmodifiable([
    ..._committed,
    if (_open case final open?) open.livePoint,
  ]);

  /// Whether no point is stored.
  bool get isEmpty => _committed.isEmpty && _open == null;

  /// Adds a raw level sample. Samples older than the previous one and
  /// non-finite levels are ignored (the clock is monotonic, so this only
  /// guards against misuse).
  void add({required Duration timestamp, required double levelDb}) {
    if (!levelDb.isFinite) return;
    final last = _lastSampleAt;
    if (last != null && timestamp < last) return;
    if (last != null && timestamp - last > envelopeResetGap) {
      _envelope.reset();
    }
    _lastSampleAt = timestamp;
    final value = _envelope.add(timestamp: timestamp, levelDb: levelDb)!;
    final start = _bucketStart(timestamp);
    final open = _open;
    if (open != null && open.start == start) {
      if (open.add(timestamp, value)) _cached = null;
      return;
    }
    if (open != null) _committed.addLast(open.finalPoint);
    _open = _OpenBucket(start: start, timestamp: timestamp, value: value);
    _evict(start);
    _cached = null;
  }

  /// Removes all points and forgets the envelope.
  void clear() {
    _committed.clear();
    _open = null;
    _lastSampleAt = null;
    _envelope.reset();
    _cached = null;
  }

  /// Splits [points] into runs without breaks (neighbours at most
  /// [breakDistance] apart). Each run is unmodifiable.
  List<List<LevelHistoryPoint>> segments() {
    final result = <List<LevelHistoryPoint>>[];
    var current = <LevelHistoryPoint>[];
    for (final point in points) {
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

  /// Summary of the chart points for accessibility texts; null when empty.
  /// The open bucket counts as one full bucket.
  ///
  /// Zones are classified from the smoothed bucket means, so the shares
  /// describe the chart, not the alarm's confirmed zone (which uses raw
  /// levels and hold times).
  LevelHistorySummary? summarize(Thresholds thresholds) {
    final all = points;
    if (all.isEmpty) return null;
    var max = double.negativeInfinity;
    var sum = 0.0;
    final counts = {for (final zone in Zone.values) zone: 0};
    for (final point in all) {
      if (point.levelDb > max) max = point.levelDb;
      sum += point.levelDb;
      final zone = thresholds.classify(point.levelDb);
      counts[zone] = counts[zone]! + 1;
    }
    final total = all.length;
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

  /// Keeps only buckets that start after `latest - window`, i.e. at most
  /// `window / bucket` points including the open one.
  void _evict(Duration latest) {
    final oldest = latest - window;
    while (_committed.isNotEmpty && _committed.first.timestamp <= oldest) {
      _committed.removeFirst();
    }
  }
}

/// Running mean of the envelope inside the not yet finished bucket.
final class _OpenBucket {
  _OpenBucket({
    required this.start,
    required Duration timestamp,
    required double value,
  }) : _sum = value,
       _count = 1,
       _publishedAt = timestamp,
       livePoint = LevelHistoryPoint(timestamp: start, levelDb: value);

  final Duration start;
  double _sum;
  int _count;
  Duration _publishedAt;

  /// Last published (throttled) value of this bucket.
  LevelHistoryPoint livePoint;

  /// Mean over every sample of the bucket, used once the bucket closes.
  /// Samples arrive at a steady rate, so the sample mean equals the time
  /// mean closely enough and avoids storing per-sample durations.
  LevelHistoryPoint get finalPoint =>
      LevelHistoryPoint(timestamp: start, levelDb: _sum / _count);

  /// Adds [value]; returns whether [livePoint] was refreshed.
  bool add(Duration timestamp, double value) {
    _sum += value;
    _count++;
    if (timestamp - _publishedAt < LevelHistory.liveInterval) return false;
    _publishedAt = timestamp;
    livePoint = finalPoint;
    return true;
  }
}

/// Aggregated numbers of a [LevelHistory] (bucket means).
final class LevelHistorySummary {
  /// Creates a summary.
  const LevelHistorySummary({
    required this.maxDb,
    required this.averageDb,
    required this.zoneShare,
    required this.coveredDuration,
  });

  /// Highest bucket mean.
  final double maxDb;

  /// Mean of the bucket means.
  final double averageDb;

  /// Share (0..1) of chart points (bucket means) per zone; sums to 1.
  final Map<Zone, double> zoneShare;

  /// Measured time (number of buckets × [LevelHistory.bucket]), excluding
  /// gaps.
  final Duration coveredDuration;
}
