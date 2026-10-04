// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/zone_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../domain/zone.dart';
import 'monitor_view_data.dart';

/// Status, alarm detail, error recovery and primary measurement action.
class MonitorStatusPanel extends StatelessWidget {
  /// Creates the panel.
  const MonitorStatusPanel({
    required this.data,
    required this.onToggleMeasurement,
    required this.onRetry,
    required this.onOpenAndroidSettings,
    super.key,
  });

  /// Current monitor snapshot.
  final MonitorViewData data;

  /// Starts or stops measurement according to [MonitorViewData.phase].
  final VoidCallback? onToggleMeasurement;

  /// Retries the last failed start.
  final VoidCallback? onRetry;

  /// Opens Android's app settings for a permanently denied permission.
  final VoidCallback? onOpenAndroidSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = ZonePalette.colorOf(data.zone);
    return GlowPanel(
      color: data.phase == MonitorPhase.error ? AppColors.red : color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusHeadline(data: data),
          if (data.phase == MonitorPhase.error) ...[
            const SizedBox(height: 12),
            _ErrorBody(error: data.error),
          ],
          if (_alarmText(l10n) case final alarm?) ...[
            const SizedBox(height: 10),
            Text(alarm, textAlign: TextAlign.center),
          ],
          if (data.alarmOutputFailed) ...[
            const SizedBox(height: 10),
            _AlarmOutputWarning(message: l10n.alarmOutputFailed),
          ],
          const SizedBox(height: 12),
          _QuietStars(data: data),
          const SizedBox(height: 16),
          _action(l10n),
        ],
      ),
    );
  }

  String? _alarmText(AppLocalizations l10n) {
    if (data.alarmPlaying) return l10n.alarmPlaying;
    if (data.alarmFired) return l10n.alarmFired;
    final remaining = data.alarmSecondsRemaining;
    return remaining == null ? null : l10n.alarmCountdown(remaining);
  }

  Widget _action(AppLocalizations l10n) {
    if (data.phase == MonitorPhase.error) {
      final permanentlyDenied =
          data.error == MonitorErrorKind.permanentlyDenied;
      return FilledButton.icon(
        onPressed: permanentlyDenied ? onOpenAndroidSettings : onRetry,
        icon: Icon(
          permanentlyDenied ? Icons.settings_rounded : Icons.refresh_rounded,
        ),
        label: Text(
          permanentlyDenied ? l10n.errorOpenSettings : l10n.errorRetry,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: data.isBusy ? null : onToggleMeasurement,
      icon: Icon(data.isActive ? Icons.stop_rounded : Icons.mic_rounded),
      label: Text(_measurementAction(l10n)),
    );
  }

  String _measurementAction(AppLocalizations l10n) {
    if (data.isBusy) return l10n.measureBusy;
    return data.isActive ? l10n.measureStop : l10n.measureStart;
  }
}

class _AlarmOutputWarning extends StatelessWidget {
  const _AlarmOutputWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      children: [
        const Icon(Icons.volume_off_rounded, color: AppColors.yellow),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _QuietStars extends StatelessWidget {
  const _QuietStars({required this.data});

  final MonitorViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (data.starProgress * 100).round();
    return Semantics(
      label: '${l10n.starsCount(data.stars)}. ${l10n.starsProgress(percent)}',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.yellow),
              const SizedBox(width: 6),
              Text(
                data.starJustEarned
                    ? l10n.starsJustEarned
                    : l10n.starsCount(data.stars),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: data.starProgress),
          const SizedBox(height: 4),
          Text(l10n.starsHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({required this.data});

  final MonitorViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = data.zone == null ? null : ZonePalette.of(data.zone!);
    return Row(
      children: [
        Icon(
          style?.icon ?? _phaseIcon(),
          color: style?.color ?? ZonePalette.colorOf(data.zone),
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _status(l10n),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }

  IconData _phaseIcon() => switch (data.phase) {
    MonitorPhase.starting ||
    MonitorPhase.stopping => Icons.hourglass_top_rounded,
    MonitorPhase.error => Icons.error_outline_rounded,
    MonitorPhase.idle || MonitorPhase.measuring => Icons.pets_rounded,
  };

  String _status(AppLocalizations l10n) => switch (data.phase) {
    MonitorPhase.idle => l10n.statusIdle,
    MonitorPhase.starting => l10n.statusStarting,
    MonitorPhase.stopping => l10n.statusStopping,
    MonitorPhase.error => l10n.statusError,
    MonitorPhase.measuring => switch (data.zone) {
      null => l10n.statusStarting,
      Zone.green => l10n.statusGreen,
      Zone.yellow => l10n.statusYellow,
      Zone.red => l10n.statusRed,
    },
  };
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final MonitorErrorKind? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (error) {
      MonitorErrorKind.permissionDenied => l10n.errorPermissionDeniedBody,
      MonitorErrorKind.permanentlyDenied => l10n.errorPermanentlyDeniedBody,
      MonitorErrorKind.microphoneBusy => l10n.errorMicrophoneBusyBody,
      MonitorErrorKind.recordingAborted => l10n.errorRecordingAbortedBody,
      MonitorErrorKind.unavailable || null => l10n.errorUnavailableBody,
    };
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}
