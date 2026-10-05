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
import '../features/monitor/application/ports.dart';
import '../features/monitor/infrastructure/platform_monitor_ports.dart';
import '../features/monitor/presentation/monitor_page.dart';
import '../features/monitor/presentation/monitor_view_data.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/infrastructure/shared_preferences_settings_repository.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shop/application/shop_controller.dart';
import '../features/shop/domain/shop_repository.dart';
import '../features/shop/infrastructure/shared_preferences_shop_repository.dart';
import '../features/shop/presentation/shop_page.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';

/// Production composition root of Raumfreund.
class RaumfreundApp extends StatefulWidget {
  /// Creates the application.
  ///
  /// Optional controllers are test seams. The app takes ownership and disposes
  /// every injected dependency just like its production dependencies.
  const RaumfreundApp({
    this.settingsController,
    this.monitorController,
    this.appInfoPort,
    this.shopRepository,
    this.monitorFactory,
    super.key,
  });

  /// Settings controller override used by integration and widget tests.
  final SettingsController? settingsController;

  /// Monitor controller override used by integration and widget tests.
  final MonitorController? monitorController;

  /// App-information source override used by integration and widget tests.
  final AppInfoPort? appInfoPort;

  /// Builds the monitor controller from the app's star sink; lets tests use
  /// fake ports while the star-to-wallet wiring stays the production one.
  /// Ignored when [monitorController] is set.
  final MonitorController Function(StarEarnedSink onStarEarned)? monitorFactory;

  /// Star wallet storage override used by integration and widget tests.
  final ShopRepository? shopRepository;

  @override
  State<RaumfreundApp> createState() => _RaumfreundAppState();
}

class _RaumfreundAppState extends State<RaumfreundApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SettingsController _settings;
  late final MonitorController _monitor;
  late final ShopController _shop;
  late final AppInfoPort _appInfoPort;
  AppInfo _appInfo = const AppInfo(
    versionName: '–',
    buildNumber: 0,
    gitCommit: 'unknown',
  );
  bool _initialSettingsReady = false;
  bool _navigationInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final platform = PlatformMonitorPorts();
    _settings =
        widget.settingsController ??
        SettingsController(SharedPreferencesSettingsRepository());
    _shop = ShopController(
      widget.shopRepository ?? SharedPreferencesShopRepository(),
    );
    _monitor =
        widget.monitorController ??
        (widget.monitorFactory ?? _createMonitor(platform))(_onStarEarned);
    _appInfoPort = widget.appInfoPort ?? PlatformAppInfoPort();
    unawaited(_loadInitialState());
  }

  void _onStarEarned() => _shop.earn(1);

  MonitorController Function(StarEarnedSink) _createMonitor(
    PlatformMonitorPorts platform,
  ) =>
      (onStarEarned) => MonitorController(
        permission: platform,
        levelSource: platform,
        alarmOutput: platform,
        screenAwake: platform,
        clock: StopwatchClock(),
        settings: AppSettings.defaults,
        onStarEarned: onStarEarned,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _monitor.onLifecycleChanged(state);
    // A failed load or save of the wallet may have been transient.
    if (state == AppLifecycleState.resumed) unawaited(_shop.retryPending());
  }

  /// Teacher reset: clears the wallet and reports whether it was stored.
  Future<StarResetResult> _resetStars() async {
    if (!_shop.resetAll()) return StarResetResult.notReady;
    await _shop.flush();
    return _shop.saveFailed ? StarResetResult.saveFailed : StarResetResult.done;
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
      animation: Listenable.merge([_monitor, _settings, _shop]),
      builder: (context, _) => MonitorPage(
        data: _viewData(_monitor.state, _shop),
        onToggleMeasurement: _initialSettingsReady
            ? () => unawaited(_monitor.toggle())
            : null,
        onRetry: _initialSettingsReady
            ? () => unawaited(_monitor.start())
            : null,
        onOpenAndroidSettings: () => unawaited(_monitor.openAppSettings()),
        onOpenSettings: _openSettings,
        onOpenAbout: _openAbout,
        onOpenShop: _openShop,
      ),
    ),
  );

  Future<void> _loadInitialState() async {
    unawaited(_shop.load());
    await _settings.load();
    await _monitor.applySettings(_settings.settings);
    if (!mounted) return;
    setState(() => _initialSettingsReady = true);
    try {
      final info = await _appInfoPort.load();
      if (mounted) setState(() => _appInfo = info);
    } on Exception {
      // About remains available with explicit unknown build information.
    }
  }

  Future<void> _openSettings() => _navigate((navigator) async {
    await _settings.load();
    if (!mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          initialSettings: _settings.settings,
          onSave: _saveSettings,
          onResetStars: _resetStars,
        ),
      ),
    );
  });

  Future<void> _openAbout() => _navigate((navigator) async {
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => AboutPage(info: _appInfo)),
    );
  });

  Future<void> _openShop() => _navigate((navigator) async {
    // A failed first load may be transient; retry (shared with a running one).
    unawaited(_shop.retryPending());
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => ShopPage(controller: _shop)),
    );
  });

  Future<bool> _saveSettings(AppSettings edited) async {
    final saved = await _settings.save(edited);
    if (!saved || !mounted) return false;
    await _monitor.applySettings(edited);
    return mounted;
  }

  Future<void> _navigate(
    Future<void> Function(NavigatorState navigator) open,
  ) async {
    if (_navigationInProgress || !mounted) return;
    _navigationInProgress = true;
    try {
      await _monitor.stop();
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator != null) await open(navigator);
    } finally {
      _navigationInProgress = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor.dispose();
    _settings.dispose();
    _shop.dispose();
    super.dispose();
  }
}

MonitorViewData _viewData(MonitorState state, ShopController shop) =>
    MonitorViewData(
      phase: _phase(state.status),
      thresholds: state.thresholds,
      levelDb: state.displayLevelDb,
      zone: state.zone,
      history: state.history,
      alarmSecondsRemaining: _seconds(state.remainingUntilAlarm),
      alarmFired: state.alarmFiredInPhase,
      alarmPlaying: state.alarmPlaying,
      alarmOutputFailed: state.alarmOutputFailed,
      signalThin: state.signalThin,
      kittyWalkedAway: state.kittyAway,
      kittyAccessories: shop.wallet.equipped,
      stars: state.stars,
      // Before a successful load the wallet only holds this session's stars, so
      // showing it as the total would be misleading.
      walletStars: shop.isLoading || shop.loadFailed
          ? null
          : shop.wallet.balance,
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
