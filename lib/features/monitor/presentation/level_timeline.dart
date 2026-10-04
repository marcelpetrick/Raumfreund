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

/// Thirty-minute, RAM-only level history styled like a heartbeat monitor.
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
      Text(l10n.timelineMinus30),
      Text(l10n.timelineMinus15),
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

  static const Duration _window = Duration(minutes: 30);

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
    final path = Path();
    final segments = splitTimelinePoints(points, oldest: oldest);
    for (final segment in segments) {
      for (var index = 0; index < segment.length; index++) {
        final point = segment[index];
        final elapsed = point.timestamp - oldest;
        final x =
            bounds.width * elapsed.inMicroseconds / _window.inMicroseconds;
        final offset = Offset(
          x.clamp(0, bounds.width),
          _y(bounds, point.levelDb),
        );
        index == 0
            ? path.moveTo(offset.dx, offset.dy)
            : path.lineTo(offset.dx, offset.dy);
      }
    }
    if (segments.isEmpty) return;
    canvas
      ..drawPath(path, Glow.haloStroke(AppColors.green, 7, sigma: 5))
      ..drawPath(path, Glow.stroke(AppColors.green, 2.2));
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
