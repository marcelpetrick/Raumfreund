// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/clock.dart';
import '../features/about/domain/app_info.dart';
import '../features/about/infrastructure/platform_app_info.dart';
import '../features/about/presentation/about_page.dart';
import '../features/monitor/application/monitor_controller.dart';
import '../features/monitor/application/monitor_state.dart';
import '../features/monitor/domain/zone.dart';
import '../features/monitor/infrastructure/platform_monitor_ports.dart';
import '../features/monitor/presentation/monitor_page.dart';
import '../features/monitor/presentation/monitor_view_data.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/infrastructure/shared_preferences_settings_repository.dart';
import '../features/settings/presentation/settings_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

/// Production composition root of Raumfreund.
class RaumfreundApp extends StatefulWidget {
  /// Creates the application.
  const RaumfreundApp({super.key});

  @override
  State<RaumfreundApp> createState() => _RaumfreundAppState();
}

class _RaumfreundAppState extends State<RaumfreundApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SettingsController _settings;
  late final MonitorController _monitor;
  late final AppInfoPort _appInfoPort;
  AppInfo _appInfo = const AppInfo(
    versionName: '–',
    buildNumber: 0,
    gitCommit: 'unknown',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final platform = PlatformMonitorPorts();
    _settings = SettingsController(SharedPreferencesSettingsRepository());
    _monitor = MonitorController(
      permission: platform,
      levelSource: platform,
      alarmOutput: platform,
      screenAwake: platform,
      clock: StopwatchClock(),
      settings: AppSettings.defaults,
    );
    _appInfoPort = PlatformAppInfoPort();
    unawaited(_loadInitialState());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _monitor.onLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'Raumfreund',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AnimatedBuilder(
      animation: _monitor,
      builder: (context, _) => MonitorPage(
        data: _viewData(_monitor.state),
        onToggleMeasurement: () => unawaited(_monitor.toggle()),
        onRetry: () => unawaited(_monitor.start()),
        onOpenAndroidSettings: () => unawaited(_monitor.openAppSettings()),
        onOpenSettings: _openSettings,
        onOpenAbout: _openAbout,
      ),
    ),
  );

  Future<void> _loadInitialState() async {
    await _settings.load();
    await _monitor.applySettings(_settings.settings);
    try {
      final info = await _appInfoPort.load();
      if (mounted) setState(() => _appInfo = info);
    } on Exception {
      // About remains available with explicit unknown build information.
    }
  }

  Future<void> _openSettings() async {
    await _monitor.stop();
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    final edited = await navigator.push<AppSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(initialSettings: _settings.settings),
      ),
    );
    if (edited == null) return;
    final saved = await _settings.save(edited);
    if (saved) await _monitor.applySettings(edited);
  }

  Future<void> _openAbout() async {
    await _monitor.stop();
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => AboutPage(info: _appInfo)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor.dispose();
    _settings.dispose();
    super.dispose();
  }
}

MonitorViewData _viewData(MonitorState state) => MonitorViewData(
  phase: _phase(state.status),
  thresholds: state.thresholds,
  levelDb: state.displayLevelDb,
  zone: state.zone,
  history: state.history,
  alarmSecondsRemaining: _seconds(state.remainingUntilAlarm),
  alarmFired: state.alarmFiredInPhase,
  alarmPlaying: state.alarmPlaying,
  kittyWalkedAway: state.zone == Zone.red && state.alarmFiredInPhase,
  stars: state.stars,
  starProgress: state.starProgress,
  starJustEarned: state.starJustEarned,
  error: _error(state.failure),
);

MonitorPhase _phase(MonitorStatus status) => switch (status) {
  MonitorStatus.stopped => MonitorPhase.idle,
  MonitorStatus.permissionPending ||
  MonitorStatus.starting => MonitorPhase.starting,
  MonitorStatus.measuring => MonitorPhase.measuring,
  MonitorStatus.stopping => MonitorPhase.stopping,
  MonitorStatus.error => MonitorPhase.error,
};

MonitorErrorKind? _error(MonitorFailure? failure) => switch (failure) {
  null => null,
  MonitorFailure.permissionDenied => MonitorErrorKind.permissionDenied,
  MonitorFailure.permissionPermanentlyDenied =>
    MonitorErrorKind.permanentlyDenied,
  MonitorFailure.microphoneBusy => MonitorErrorKind.microphoneBusy,
  MonitorFailure.recordingAborted => MonitorErrorKind.recordingAborted,
  MonitorFailure.unavailable => MonitorErrorKind.unavailable,
};

int? _seconds(Duration? duration) => duration == null
    ? null
    : (duration.inMilliseconds / Duration.millisecondsPerSecond).ceil();
