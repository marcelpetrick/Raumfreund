// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Narrow interfaces between the measurement application layer and the
/// platform. Implemented by method/event channel adapters in
/// infrastructure/, and by fakes in tests. Protocol: docs/platform-channels.md.
library;

/// Result of a microphone permission query or request.
enum MicrophonePermissionStatus {
  /// Recording is allowed.
  granted,

  /// Not granted, but the system dialog may be shown (again).
  denied,

  /// Denied permanently ("don't ask again"); only the app settings help.
  permanentlyDenied,
}

/// Microphone permission handling.
abstract interface class MicrophonePermissionPort {
  /// Current status without showing any UI.
  Future<MicrophonePermissionStatus> status();

  /// Shows the system dialog if needed and returns the result.
  Future<MicrophonePermissionStatus> request();

  /// Opens the Android app settings page of Raumfreund.
  Future<void> openAppSettings();
}

/// Why level measurement failed or ended unexpectedly.
enum LevelFailure {
  /// Another app holds or silences the microphone.
  microphoneBusy,

  /// Recording started but was aborted (read error, system stop).
  recordingAborted,

  /// The microphone or required audio format is unavailable.
  unavailable,

  /// The permission is missing at the time of starting.
  permissionMissing,
}

/// Event of a measurement session. [sessionId] lets the application drop
/// stale events of earlier sessions.
sealed class LevelEvent {
  const LevelEvent(this.sessionId);

  /// Session the event belongs to.
  final int sessionId;
}

/// One RMS level of a ~100 ms window in dBFS (<= 0).
final class LevelReading extends LevelEvent {
  /// Creates a reading.
  const LevelReading(super.sessionId, this.dbfs);

  /// Level relative to digital full scale.
  final double dbfs;
}

/// Failure that ends the session on the native side.
final class LevelError extends LevelEvent {
  /// Creates an error event.
  const LevelError(super.sessionId, this.failure);

  /// Failure kind.
  final LevelFailure failure;
}

/// Thrown by [LevelSourcePort.start] when recording cannot start.
final class LevelSourceException implements Exception {
  /// Creates the exception.
  const LevelSourceException(this.failure);

  /// Failure kind.
  final LevelFailure failure;

  @override
  String toString() => 'LevelSourceException(${failure.name})';
}

/// Stream of microphone levels.
abstract interface class LevelSourcePort {
  /// Broadcast stream of events of all sessions.
  Stream<LevelEvent> get events;

  /// Starts recording for [sessionId]. Throws [LevelSourceException].
  /// Idempotent per session; a new id stops a previous session first.
  Future<void> start(int sessionId);

  /// Stops recording. Idempotent; safe to call when not recording.
  Future<void> stop();
}

/// Short alarm signal.
abstract interface class AlarmOutputPort {
  /// Plays the tone (if [sound]) and vibrates (if [vibrate] and the device
  /// has a vibrator). Completes when the output has ended, so the caller
  /// knows when the microphone is no longer influenced by it.
  Future<void> play({required bool sound, required bool vibrate});
}

/// Keeps the display on while measuring.
abstract interface class ScreenAwakePort {
  /// Enables or disables the keep-screen-on flag of the activity.
  Future<void> setKeepScreenOn({required bool enabled});
}

/// Called exactly once for every quiet-minute star the monitor earns.
///
/// Lets the app composition feed a persistent star wallet without the
/// monitor knowing about the shop. Must not throw and returns immediately.
typedef StarEarnedSink = void Function();

/// The default [StarEarnedSink]: ignores the star.
void ignoreStarEarned() {}
