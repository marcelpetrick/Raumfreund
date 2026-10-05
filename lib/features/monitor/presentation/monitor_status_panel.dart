// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/zone_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/zone.dart';
import 'monitor_view_data.dart';
import 'stable_text.dart';

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
          // The error body and the warnings (alarm output failed, readings
          // too sparse) stay height-variable on purpose: they only occur in
          // rare states, where a layout change is expected and a permanently
          // reserved slot would waste space.
          if (data.phase != MonitorPhase.error) ...[
            const SizedBox(height: 10),
            _alarmSlot(l10n),
          ],
          if (data.alarmOutputFailed) ...[
            const SizedBox(height: 10),
            _PanelWarning(
              icon: Icons.volume_off_rounded,
              message: l10n.alarmOutputFailed,
            ),
          ],
          if (data.isActive && data.signalThin) ...[
            const SizedBox(height: 10),
            _PanelWarning(
              icon: Icons.warning_amber_rounded,
              message: l10n.signalThin,
            ),
          ],
          const SizedBox(height: 12),
          _QuietStars(data: data),
          const SizedBox(height: 16),
          _action(l10n),
        ],
      ),
    );
  }

  /// Always reserved outside the error phase so that the zone change into
  /// yellow/red does not push the content below down.
  Widget _alarmSlot(AppLocalizations l10n) {
    final remaining = data.alarmSecondsRemaining;
    final counting =
        !data.alarmPlaying && !data.alarmFired && remaining != null;
    return StableText(
      text: _alarmText(l10n),
      // The longest configurable delay; fewer digits are never wider.
      variants: [
        l10n.alarmCountdown(AppSettings.maxAlarmDelaySeconds),
        l10n.alarmImminent,
        l10n.alarmFired,
        l10n.alarmPlaying,
      ],
      textAlign: TextAlign.center,
      // Screen readers say "Sekunden" instead of the abbreviated "s".
      semanticsLabel: counting && remaining > 0
          ? l10n.alarmCountdownSemantics(remaining)
          : null,
    );
  }

  String _alarmText(AppLocalizations l10n) {
    if (data.alarmPlaying) return l10n.alarmPlaying;
    if (data.alarmFired) return l10n.alarmFired;
    final remaining = data.alarmSecondsRemaining;
    if (remaining == null) return '';
    // The delay can be reached during a short pause; the alarm then fires
    // with the next loud reading, so "0 s" would look stuck.
    return remaining > 0 ? l10n.alarmCountdown(remaining) : l10n.alarmImminent;
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

/// Non-fatal hint with an icon, announced by TalkBack when it appears.
class _PanelWarning extends StatelessWidget {
  const _PanelWarning({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      children: [
        Icon(icon, color: AppColors.yellow),
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
              // Flexible so large text scales wrap instead of overflowing.
              Flexible(
                child: StableText(
                  text: data.starJustEarned
                      ? l10n.starsJustEarned
                      : l10n.starsCount(data.stars),
                  variants: [l10n.starsJustEarned, l10n.starsCount(data.stars)],
                  textAlign: TextAlign.center,
                ),
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
          child: StableText(
            text: _status(l10n),
            variants: [
              l10n.statusIdle,
              l10n.statusStarting,
              l10n.statusStopping,
              l10n.statusGreen,
              l10n.statusYellow,
              l10n.statusRed,
              l10n.statusError,
            ],
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
