// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glow.dart';
import '../../../app/theme/zone_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/thresholds.dart';
import '../domain/zone.dart';

/// Neon semicircular gauge for the estimated 0–130 dB value.
class LevelGauge extends StatelessWidget {
  /// Creates the gauge.
  const LevelGauge({
    required this.levelDb,
    required this.zone,
    required this.thresholds,
    super.key,
  });

  /// Smoothed value shown to the user, or null before the first sample.
  final double? levelDb;

  /// Alarm decision zone shown with icon and text.
  final Zone? zone;

  /// Current zone boundaries.
  final Thresholds thresholds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rounded = levelDb?.round().clamp(Thresholds.minDb, Thresholds.maxDb);
    final value = rounded == null
        ? l10n.gaugeSemanticsNoValue
        : l10n.gaugeSemanticsValue(rounded, _zoneLabel(l10n));
    return Semantics(
      container: true,
      label: l10n.gaugeSemanticsLabel,
      value: value,
      readOnly: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(double.infinity, 210),
                painter: LevelGaugePainter(
                  levelDb: levelDb,
                  thresholds: thresholds,
                  color: ZonePalette.colorOf(zone),
                ),
              ),
              Positioned(bottom: 26, child: _GaugeValue(value: rounded)),
            ],
          ),
        ),
      ),
    );
  }

  String _zoneLabel(AppLocalizations l10n) =>
      zone == null ? l10n.statusIdle : ZonePalette.of(zone!).label(l10n);
}

class _GaugeValue extends StatelessWidget {
  const _GaugeValue({required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value == null ? l10n.gaugeNoValue : l10n.gaugeValue(value!),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        Text(l10n.gaugeEstimated, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Painter for [LevelGauge].
class LevelGaugePainter extends CustomPainter {
  /// Creates the painter.
  const LevelGaugePainter({
    required this.levelDb,
    required this.thresholds,
    required this.color,
  });

  /// Display value, or null.
  final double? levelDb;

  /// Zone boundaries.
  final Thresholds thresholds;

  /// Active neon color.
  final Color color;

  static const double _start = math.pi * 0.8;
  static const double _sweep = math.pi * 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.78),
      width: math.min(size.width - 28, 330),
      height: math.min(size.width - 28, 330),
    );
    _drawTrack(canvas, rect);
    _drawThreshold(canvas, rect, thresholds.yellowDb, AppColors.yellow);
    _drawThreshold(canvas, rect, thresholds.redDb, AppColors.red);
    if (levelDb != null) _drawValue(canvas, rect);
  }

  void _drawTrack(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    canvas.drawArc(rect, _start, _sweep, false, paint);
  }

  void _drawThreshold(Canvas canvas, Rect rect, int value, Color tickColor) {
    final angle = _start + _sweep * value / Thresholds.maxDb;
    final center = rect.center;
    final outer = Offset(
      center.dx + math.cos(angle) * rect.width / 2,
      center.dy + math.sin(angle) * rect.height / 2,
    );
    final inner = Offset.lerp(center, outer, 0.83)!;
    canvas.drawLine(inner, outer, Glow.stroke(tickColor, 4));
  }

  void _drawValue(Canvas canvas, Rect rect) {
    final clamped = levelDb!.clamp(Thresholds.minDb, Thresholds.maxDb);
    final progress = clamped / Thresholds.maxDb;
    final halo = Glow.haloStroke(color, 22, sigma: 11);
    final stroke = Glow.stroke(color, 13);
    canvas
      ..drawArc(rect, _start, _sweep * progress, false, halo)
      ..drawArc(rect, _start, _sweep * progress, false, stroke);
  }

  @override
  bool shouldRepaint(LevelGaugePainter oldDelegate) =>
      oldDelegate.levelDb != levelDb ||
      oldDelegate.thresholds != thresholds ||
      oldDelegate.color != color;
}
