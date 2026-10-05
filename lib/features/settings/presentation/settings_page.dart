// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../../../shared/widgets/night_sky_background.dart';
import '../../monitor/domain/thresholds.dart';
import '../domain/app_settings.dart';

/// Editable settings page.
///
/// Outcome of the teacher's star reset, reported to the settings page.
enum StarResetResult {
  /// Cleared and stored.
  done,

  /// Not possible yet (data still loading).
  notReady,

  /// Cleared on screen, but writing to storage failed (retried later).
  saveFailed,
}

/// Save awaits application-layer persistence and closes only after success.
/// Cancel always discards the independent draft.
class SettingsPage extends StatefulWidget {
  /// Creates the page with an independent editable draft.
  const SettingsPage({
    required this.initialSettings,
    required this.onSave,
    this.onResetStars,
    super.key,
  });

  /// Settings copied into the draft when the page opens.
  final AppSettings initialSettings;

  /// Validates and persists the draft, returning whether it was saved.
  final Future<bool> Function(AppSettings settings) onSave;

  /// Teacher reset of stars and shop items; completes with the outcome after
  /// the change has been stored. The section is hidden when null.
  ///
  /// Deliberately outside the Save/Cancel draft: it acts immediately on
  /// another store, so Cancel could not undo it.
  final Future<StarResetResult> Function()? onResetStars;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _draft = widget.initialSettings;
  bool _defaultsApplied = false;
  bool _isSaving = false;
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isSaving,
      child: NightSkyBackground(
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: SafeArea(
            top: false,
            child: AbsorbPointer(
              absorbing: _isSaving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _thresholdsSection(l10n),
                        const SizedBox(height: 16),
                        _calibrationSection(l10n),
                        const SizedBox(height: 16),
                        _alarmSection(l10n),
                        if (widget.onResetStars != null) ...[
                          const SizedBox(height: 16),
                          _StarResetSection(onReset: widget.onResetStars!),
                        ],
                        const SizedBox(height: 20),
                        if (_defaultsApplied) _defaultsHint(l10n),
                        if (_saveFailed) _saveError(l10n),
                        _actions(l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thresholdsSection(AppLocalizations l10n) => _SettingsSection(
    title: l10n.settingsThresholdsHeading,
    icon: Icons.traffic_rounded,
    color: AppColors.yellow,
    children: [
      _ThresholdControl(
        name: l10n.settingsYellowLabel,
        value: _draft.thresholds.yellowDb,
        color: AppColors.yellow,
        onChanged: _setYellow,
      ),
      _ThresholdControl(
        name: l10n.settingsRedLabel,
        value: _draft.thresholds.redDb,
        color: AppColors.red,
        onChanged: _setRed,
      ),
      Text(l10n.settingsThresholdsHint),
    ],
  );

  Widget _calibrationSection(AppLocalizations l10n) {
    final value = _draft.calibrationCorrectionDb;
    final signed = value > 0 ? '+$value' : '$value';
    return _SettingsSection(
      title: l10n.settingsCalibrationHeading,
      icon: Icons.tune_rounded,
      color: AppColors.lavender,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.settingsCalibrationLabel)),
            Text(l10n.settingsCalibrationValue(signed)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: AppSettings.minCalibrationDb.toDouble(),
          max: AppSettings.maxCalibrationDb.toDouble(),
          divisions:
              AppSettings.maxCalibrationDb - AppSettings.minCalibrationDb,
          label: l10n.settingsCalibrationValue(signed),
          onChanged: (next) =>
              _update(_draft.copyWith(calibrationCorrectionDb: next.round())),
        ),
        Text(l10n.settingsCalibrationExplanation),
      ],
    );
  }

  Widget _alarmSection(AppLocalizations l10n) => _SettingsSection(
    title: l10n.settingsAlarmHeading,
    icon: Icons.notifications_active_rounded,
    color: AppColors.green,
    children: [
      _AlarmDelayControl(
        value: _draft.alarmDelaySeconds,
        onChanged: (value) =>
            _update(_draft.copyWith(alarmDelaySeconds: value)),
      ),
      Text(
        l10n.settingsAlarmDelayRule(
          _draft.alarmDelaySeconds,
          AppSettings.minAlarmDelaySeconds,
          AppSettings.maxAlarmDelaySeconds,
          AppSettings.defaultAlarmDelaySeconds,
        ),
      ),
      const SizedBox(height: 8),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.settingsAlarmSound),
        subtitle: Text(l10n.settingsAlarmSoundHint),
        value: _draft.alarmSoundEnabled,
        onChanged: (value) =>
            _update(_draft.copyWith(alarmSoundEnabled: value)),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.settingsVibration),
        subtitle: Text(l10n.settingsVibrationHint),
        value: _draft.vibrationEnabled,
        onChanged: (value) => _update(_draft.copyWith(vibrationEnabled: value)),
      ),
    ],
  );

  Widget _defaultsHint(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(l10n.settingsDefaultsApplied, textAlign: TextAlign.center),
  );

  Widget _saveError(AppLocalizations l10n) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        l10n.settingsSaveError,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.red),
      ),
    ),
  );

  Widget _actions(AppLocalizations l10n) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      TextButton.icon(
        onPressed: _isSaving ? null : _restoreDefaults,
        icon: const Icon(Icons.restore_rounded),
        label: Text(l10n.settingsDefaults),
      ),
      OutlinedButton(
        onPressed: _isSaving ? null : () => Navigator.pop(context),
        child: Text(l10n.settingsCancel),
      ),
      FilledButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: Icon(_saveFailed ? Icons.refresh_rounded : Icons.save_rounded),
        label: Text(_saveFailed ? l10n.settingsRetrySave : l10n.settingsSave),
      ),
    ],
  );

  void _setYellow(int value) {
    final yellow = value.clamp(Thresholds.minDb, Thresholds.maxDb - 1);
    final red = yellow >= _draft.thresholds.redDb
        ? yellow + 1
        : _draft.thresholds.redDb;
    _update(
      _draft.copyWith(
        thresholds: Thresholds(yellowDb: yellow, redDb: red),
      ),
    );
  }

  void _setRed(int value) {
    final red = value.clamp(Thresholds.minDb + 1, Thresholds.maxDb);
    final yellow = red <= _draft.thresholds.yellowDb
        ? red - 1
        : _draft.thresholds.yellowDb;
    _update(
      _draft.copyWith(
        thresholds: Thresholds(yellowDb: yellow, redDb: red),
      ),
    );
  }

  void _restoreDefaults() {
    setState(() {
      _draft = AppSettings.defaults;
      _defaultsApplied = true;
      _saveFailed = false;
    });
  }

  void _update(AppSettings settings) {
    setState(() {
      _draft = settings;
      _defaultsApplied = false;
      _saveFailed = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    var saved = false;
    try {
      saved = await widget.onSave(_draft);
    } on Exception {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, _draft);
      return;
    }
    setState(() {
      _isSaving = false;
      _saveFailed = true;
    });
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GlowPanel(
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

/// Teacher reset of the star shop, separated from the editable draft.
class _StarResetSection extends StatelessWidget {
  const _StarResetSection({required this.onReset});

  final Future<StarResetResult> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingsSection(
      title: l10n.settingsResetHeading,
      icon: Icons.star_outline_rounded,
      color: AppColors.red,
      children: [
        Text(l10n.settingsResetBody),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _confirmAndReset(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(l10n.settingsResetButton),
        ),
      ],
    );
  }

  Future<void> _confirmAndReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetConfirmTitle),
        content: Text(l10n.settingsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.shopConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsResetConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final result = await onReset();
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          StarResetResult.done => l10n.settingsResetDone,
          StarResetResult.notReady => l10n.settingsResetNotReady,
          StarResetResult.saveFailed => l10n.settingsResetSaveFailed,
        }),
      ),
    );
  }
}

class _ThresholdControl extends StatelessWidget {
  const _ThresholdControl({
    required this.name,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String name;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              onPressed: value <= Thresholds.minDb
                  ? null
                  : () => onChanged(value - 1),
              tooltip: l10n.settingsDecrease(name),
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 72,
              child: Text(
                l10n.settingsDbValue(value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color),
              ),
            ),
            IconButton(
              onPressed: value >= Thresholds.maxDb
                  ? null
                  : () => onChanged(value + 1),
              tooltip: l10n.settingsIncrease(name),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: Thresholds.minDb.toDouble(),
          max: Thresholds.maxDb.toDouble(),
          divisions: Thresholds.maxDb,
          activeColor: color,
          label: l10n.settingsDbValue(value),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

/// Alarm delay stepper: minus/plus buttons around a 1 s slider.
///
/// Unlike the threshold rows the value sits above the slider in a [Wrap],
/// because "60 Sekunden" is too wide for a fixed slot next to the buttons at
/// large text scales.
class _AlarmDelayControl extends StatelessWidget {
  const _AlarmDelayControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final valueText = l10n.settingsSecondsValue(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.settingsAlarmDelayLabel, style: textTheme.titleMedium),
            Text(
              valueText,
              style: textTheme.titleMedium?.copyWith(color: AppColors.green),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: value <= AppSettings.minAlarmDelaySeconds
                  ? null
                  : () => onChanged(value - 1),
              tooltip: l10n.settingsAlarmDelayDecrease,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(child: _slider(l10n, valueText)),
            IconButton(
              onPressed: value >= AppSettings.maxAlarmDelaySeconds
                  ? null
                  : () => onChanged(value + 1),
              tooltip: l10n.settingsAlarmDelayIncrease,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }

  // Merged so screen readers announce name and value as one slider.
  Widget _slider(AppLocalizations l10n, String valueText) => MergeSemantics(
    child: Semantics(
      label: l10n.settingsAlarmDelayLabel,
      child: Slider(
        value: value.toDouble(),
        min: AppSettings.minAlarmDelaySeconds.toDouble(),
        max: AppSettings.maxAlarmDelaySeconds.toDouble(),
        divisions:
            AppSettings.maxAlarmDelaySeconds - AppSettings.minAlarmDelaySeconds,
        activeColor: AppColors.green,
        label: valueText,
        semanticFormatterCallback: (next) =>
            l10n.settingsSecondsValue(next.round()),
        onChanged: (next) => onChanged(next.round()),
      ),
    ),
  );
}
