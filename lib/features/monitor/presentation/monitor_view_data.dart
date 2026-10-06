// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import '../../shop/domain/kitty_accessory.dart';
import '../domain/level_history_point.dart';
import '../domain/thresholds.dart';
import '../domain/zone.dart';

/// Lifecycle phase rendered by the monitor page.
enum MonitorPhase {
  /// No measurement is running.
  idle,

  /// A measurement is being prepared.
  starting,

  /// Samples are arriving.
  measuring,

  /// Resources are being released.
  stopping,

  /// The last start or measurement failed.
  error,
}

/// User-facing measurement error rendered by the monitor page.
enum MonitorErrorKind {
  /// The permission was denied and may be requested again.
  permissionDenied,

  /// Android no longer offers an in-app permission prompt.
  permanentlyDenied,

  /// Another app is using the microphone.
  microphoneBusy,

  /// A running recording ended unexpectedly.
  recordingAborted,

  /// The device cannot provide microphone levels.
  unavailable,

  /// The recording delivered no levels for too long.
  noReadings,
}

/// Immutable presentation input for the monitor page.
///
/// It deliberately contains no controller or platform types. The application
/// layer maps its state into this small snapshot and handles the callbacks.
final class MonitorViewData {
  /// Creates one monitor snapshot.
  const MonitorViewData({
    required this.phase,
    required this.thresholds,
    this.levelDb,
    this.zone,
    this.history = const <LevelHistoryPoint>[],
    this.alarmSecondsRemaining,
    this.alarmFired = false,
    this.alarmPlaying = false,
    this.alarmOutputFailed = false,
    this.signalThin = false,
    this.kittyWalkedAway = false,
    this.kittyAccessories = const <KittyAccessory>{},
    this.stars = 0,
    this.walletStars,
    this.starProgress = 0,
    this.starJustEarned = false,
    this.error,
  });

  /// Initial presentation before the application controller has started.
  factory MonitorViewData.idle({Thresholds? thresholds}) => MonitorViewData(
    phase: MonitorPhase.idle,
    thresholds: thresholds ?? Thresholds.defaults,
  );

  /// Current lifecycle phase.
  final MonitorPhase phase;

  /// Validated zone limits.
  final Thresholds thresholds;

  /// Smoothed display value, or null before a valid sample exists.
  final double? levelDb;

  /// Zone derived from the alarm decision value, or null while idle.
  final Zone? zone;

  /// Recent values kept in RAM by the application layer.
  final List<LevelHistoryPoint> history;

  /// Whole seconds until the current phase can alarm.
  final int? alarmSecondsRemaining;

  /// Whether the current phase has already emitted its one alarm.
  final bool alarmFired;

  /// Whether the app's own alarm output is currently active.
  final bool alarmPlaying;

  /// Whether the latest alarm output failed while measurement continued.
  final bool alarmOutputFailed;

  /// Whether readings arrive too sparsely to judge the room (no alarm can
  /// fire until they recover).
  final bool signalThin;

  /// Whether Mia completed her walk out of the scene.
  final bool kittyWalkedAway;

  /// Shop items Mia currently wears.
  final Set<KittyAccessory> kittyAccessories;

  /// Quiet minutes earned during this app session.
  final int stars;

  /// Stars in the persistent Sternenladen wallet, or null while unknown
  /// (still loading or failed to load) so no misleading total is shown.
  final int? walletStars;

  /// Progress from 0 to 1 toward the next quiet-minute star.
  final double starProgress;

  /// Whether the latest sample earned a star.
  final bool starJustEarned;

  /// Error detail when [phase] is [MonitorPhase.error].
  final MonitorErrorKind? error;

  /// Whether start/stop controls must wait for a transition.
  bool get isBusy =>
      phase == MonitorPhase.starting || phase == MonitorPhase.stopping;

  /// Whether a measurement is active and the primary action stops it.
  bool get isActive => phase == MonitorPhase.measuring;
}
