// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glow.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../domain/level_history.dart';
import '../domain/level_history_point.dart';
import '../domain/thresholds.dart';

/// Ten-minute, RAM-only level history styled like a heartbeat monitor.
///
/// Shows one point per 10-second bucket of the peak envelope (see
/// [LevelHistory]); the last point is the live, still-open bucket.
class LevelTimeline extends StatelessWidget {
  /// Creates the timeline.
  const LevelTimeline({
    required this.points,
    required this.thresholds,
    super.key,
  });

  /// Ordered level points from the application ring buffer.
  final List<LevelHistoryPoint> points;

  /// Current zone boundaries.
  final Thresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = _summary(l10n);
    return Semantics(
      container: true,
      label: l10n.timelineTitle,
      value: summary,
      readOnly: true,
      child: ExcludeSemantics(
        child: GlowPanel(
          color: AppColors.green,
          glowStrength: 0.18,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.timelineTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 126,
                child: CustomPaint(
                  painter: LevelTimelinePainter(
                    points: points,
                    thresholds: thresholds,
                  ),
                ),
              ),
              _TimelineAxis(l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Describes the chart points (smoothed 10 s means); deliberately not
  /// the alarm zone, which the status panel announces.
  String _summary(AppLocalizations l10n) {
    if (points.isEmpty) return l10n.timelineEmpty;
    final levels = points.map((point) => point.levelDb);
    final max = levels.reduce(math.max).round();
    final average = (levels.reduce((a, b) => a + b) / points.length).round();
    final green = points
        .where((point) => point.levelDb < thresholds.yellowDb)
        .length;
    return l10n.timelineSummary(
      max,
      average,
      (green * 100 / points.length).round(),
    );
  }
}

class _TimelineAxis extends StatelessWidget {
  const _TimelineAxis({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l10n.timelineMinus10),
      Text(l10n.timelineMinus5),
      Text(l10n.timelineNow),
    ],
  );
}

/// Painter for [LevelTimeline].
class LevelTimelinePainter extends CustomPainter {
  /// Creates the painter.
  const LevelTimelinePainter({required this.points, required this.thresholds});

  /// Ordered history points.
  final List<LevelHistoryPoint> points;

  /// Zone boundaries.
  final Thresholds thresholds;

  static const Duration _window = LevelHistory.defaultWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
      Paint()..color = AppColors.monitorScreen,
    );
    _drawBands(canvas, bounds);
    _drawGrid(canvas, bounds);
    if (points.isNotEmpty) _drawTrace(canvas, bounds);
  }

  void _drawBands(Canvas canvas, Rect bounds) {
    final yellowY = _y(bounds, thresholds.yellowDb.toDouble());
    final redY = _y(bounds, thresholds.redDb.toDouble());
    canvas
      ..drawRect(
        Rect.fromLTRB(bounds.left, bounds.top, bounds.right, redY),
        Paint()..color = AppColors.red.withValues(alpha: 0.1),
      )
      ..drawRect(
        Rect.fromLTRB(bounds.left, redY, bounds.right, yellowY),
        Paint()..color = AppColors.yellow.withValues(alpha: 0.08),
      )
      ..drawLine(
        Offset(0, yellowY),
        Offset(bounds.right, yellowY),
        Glow.stroke(AppColors.yellow, 1),
      )
      ..drawLine(
        Offset(0, redY),
        Offset(bounds.right, redY),
        Glow.stroke(AppColors.red, 1),
      );
  }

  void _drawGrid(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = bounds.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, bounds.height), paint);
    }
    for (var i = 1; i < 4; i++) {
      final y = bounds.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(bounds.width, y), paint);
    }
  }

  void _drawTrace(Canvas canvas, Rect bounds) {
    final latest = points.last.timestamp;
    final oldest = latest - _window;
    final segments = splitTimelinePoints(points, oldest: oldest);
    if (segments.isEmpty) return;
    final path = Path();
    final dots = <Offset>[];
    for (final segment in segments) {
      final offsets = [
        for (final point in segment) _offset(bounds, oldest, point),
      ];
      // A lone bucket (just after a start or gap) has no line to draw.
      if (offsets.length == 1) dots.add(offsets.single);
      addSmoothTimelinePath(path, offsets);
    }
    // The live point always gets a dot; skip it if it already has one as
    // a lone bucket, so it is not drawn twice.
    final live = _offset(bounds, oldest, points.last);
    if (dots.isEmpty || dots.last != live) dots.add(live);
    canvas
      ..drawPath(path, Glow.haloStroke(AppColors.green, 7, sigma: 5))
      ..drawPath(path, Glow.stroke(AppColors.green, 2.2));
    for (final dot in dots) {
      canvas
        ..drawCircle(dot, 4, Glow.halo(AppColors.green, sigma: 4))
        ..drawCircle(dot, 2.4, Paint()..color = AppColors.green);
    }
  }

  Offset _offset(Rect bounds, Duration oldest, LevelHistoryPoint point) {
    final elapsed = point.timestamp - oldest;
    final x = bounds.width * elapsed.inMicroseconds / _window.inMicroseconds;
    return Offset(x.clamp(0, bounds.width), _y(bounds, point.levelDb));
  }

  double _y(Rect bounds, double level) =>
      bounds.bottom -
      bounds.height * level.clamp(0, Thresholds.maxDb) / Thresholds.maxDb;

  @override
  bool shouldRepaint(LevelTimelinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.thresholds != thresholds;
}

/// Splits visible chart points at gaps defined by [LevelHistory].
@visibleForTesting
List<List<LevelHistoryPoint>> splitTimelinePoints(
  List<LevelHistoryPoint> points, {
  required Duration oldest,
}) {
  final segments = <List<LevelHistoryPoint>>[];
  var current = <LevelHistoryPoint>[];
  for (final point in points.where((point) => point.timestamp >= oldest)) {
    if (current.isNotEmpty &&
        point.timestamp - current.last.timestamp > LevelHistory.breakDistance) {
      segments.add(List.unmodifiable(current));
      current = <LevelHistoryPoint>[];
    }
    current.add(point);
  }
  if (current.isNotEmpty) segments.add(List.unmodifiable(current));
  return List.unmodifiable(segments);
}

/// Appends [offsets] (strictly increasing x) to [path] as a smooth curve.
///
/// Uses a monotone cubic Hermite spline (Fritsch–Carlson): the curve passes
/// through every bucket point and never overshoots between two of them, so
/// a red bucket is drawn exactly at its level and the curve cannot suggest
/// a peak or dip that was not measured.
@visibleForTesting
void addSmoothTimelinePath(Path path, List<Offset> offsets) {
  if (offsets.isEmpty) return;
  path.moveTo(offsets.first.dx, offsets.first.dy);
  final tangents = monotoneTimelineTangents(offsets);
  for (var i = 0; i < offsets.length - 1; i++) {
    final a = offsets[i];
    final b = offsets[i + 1];
    final third = (b.dx - a.dx) / 3;
    path.cubicTo(
      a.dx + third,
      a.dy + tangents[i] * third,
      b.dx - third,
      b.dy - tangents[i + 1] * third,
      b.dx,
      b.dy,
    );
  }
}

/// Fritsch–Carlson tangents (dy/dx) for [offsets].
///
/// Interior tangents are zero at local extrema (secant slopes change sign)
/// and otherwise the mean of both secants; afterwards every pair is scaled
/// so that `alpha² + beta² <= 9`, the sufficient condition for a monotone
/// cubic on each interval.
@visibleForTesting
List<double> monotoneTimelineTangents(List<Offset> offsets) {
  final n = offsets.length;
  if (n < 2) return List<double>.filled(n, 0);
  final secants = [
    for (var i = 0; i < n - 1; i++) _secant(offsets[i], offsets[i + 1]),
  ];
  final tangents = [
    secants.first,
    for (var i = 1; i < n - 1; i++)
      secants[i - 1] * secants[i] <= 0
          ? 0.0
          : (secants[i - 1] + secants[i]) / 2,
    secants.last,
  ];
  for (var i = 0; i < n - 1; i++) {
    final secant = secants[i];
    if (secant == 0) {
      tangents[i] = 0;
      tangents[i + 1] = 0;
      continue;
    }
    final alpha = tangents[i] / secant;
    final beta = tangents[i + 1] / secant;
    final norm = alpha * alpha + beta * beta;
    if (norm <= 9) continue;
    final scale = 3 / math.sqrt(norm);
    tangents[i] = scale * alpha * secant;
    tangents[i + 1] = scale * beta * secant;
  }
  return tangents;
}

double _secant(Offset a, Offset b) {
  final dx = b.dx - a.dx;
  // Clamping at the left edge could collapse two points; treat as flat.
  return dx <= 0 ? 0 : (b.dy - a.dy) / dx;
}
