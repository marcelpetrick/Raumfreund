// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/night_sky_background.dart';
import '../domain/zone.dart';
import 'kitty/kitty_character.dart';
import 'level_gauge.dart';
import 'level_timeline.dart';
import 'monitor_status_panel.dart';
import 'monitor_view_data.dart';

/// Callback that stops active measurement before opening a secondary page.
typedef MonitorNavigationCallback = Future<void> Function();

/// Responsive main page of the volume monitor.
class MonitorPage extends StatelessWidget {
  /// Creates the monitor page.
  const MonitorPage({
    required this.data,
    required this.onToggleMeasurement,
    required this.onOpenSettings,
    required this.onOpenAbout,
    required this.onOpenShop,
    this.onRetry,
    this.onOpenAndroidSettings,
    super.key,
  });

  /// Current presentation snapshot.
  final MonitorViewData data;

  /// Starts or stops measurement.
  final VoidCallback? onToggleMeasurement;

  /// Stops measurement if needed, then opens Settings.
  final MonitorNavigationCallback onOpenSettings;

  /// Stops measurement if needed, then opens About.
  final MonitorNavigationCallback onOpenAbout;

  /// Stops measurement if needed, then opens the star shop.
  final MonitorNavigationCallback onOpenShop;

  /// Retries a failed start.
  final VoidCallback? onRetry;

  /// Opens Android app settings.
  final VoidCallback? onOpenAndroidSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NightSkyBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              onPressed: () => unawaited(onOpenShop()),
              tooltip: l10n.actionShop,
              icon: const Icon(Icons.storefront_rounded),
            ),
            IconButton(
              onPressed: () => unawaited(onOpenSettings()),
              tooltip: l10n.actionSettings,
              icon: const Icon(Icons.settings_rounded),
            ),
            IconButton(
              onPressed: () => unawaited(onOpenAbout()),
              tooltip: l10n.actionAbout,
              icon: const Icon(Icons.info_outline_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: _buildResponsive),
        ),
      ),
    );
  }

  Widget _buildResponsive(BuildContext context, BoxConstraints constraints) {
    final wide = constraints.maxWidth >= 760;
    final content = wide ? _wideContent(context) : _narrowContent(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: content,
        ),
      ),
    );
  }

  Widget _narrowContent(BuildContext context) => Column(
    children: [
      LevelGauge(
        levelDb: data.levelDb,
        zone: data.zone,
        thresholds: data.thresholds,
      ),
      SizedBox(
        height: 230,
        child: KittyCharacter(
          mood: _kittyMood,
          walkedAway: data.kittyWalkedAway,
          accessories: data.kittyAccessories,
          reduceMotion: MediaQuery.disableAnimationsOf(context),
        ),
      ),
      const SizedBox(height: 12),
      _statusPanel,
      const SizedBox(height: 16),
      LevelTimeline(points: data.history, thresholds: data.thresholds),
    ],
  );

  Widget _wideContent(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          children: [
            LevelGauge(
              levelDb: data.levelDb,
              zone: data.zone,
              thresholds: data.thresholds,
            ),
            SizedBox(
              height: 250,
              child: KittyCharacter(
                mood: _kittyMood,
                walkedAway: data.kittyWalkedAway,
                accessories: data.kittyAccessories,
                reduceMotion: MediaQuery.disableAnimationsOf(context),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          children: [
            _statusPanel,
            const SizedBox(height: 16),
            LevelTimeline(points: data.history, thresholds: data.thresholds),
          ],
        ),
      ),
    ],
  );

  Widget get _statusPanel => MonitorStatusPanel(
    data: data,
    onToggleMeasurement: onToggleMeasurement,
    onRetry: onRetry,
    onOpenAndroidSettings: onOpenAndroidSettings,
  );

  KittyMood get _kittyMood => switch (data.zone) {
    Zone.green => KittyMood.happy,
    Zone.yellow => KittyMood.uneasy,
    Zone.red => KittyMood.scared,
    null => KittyMood.idle,
  };
}
