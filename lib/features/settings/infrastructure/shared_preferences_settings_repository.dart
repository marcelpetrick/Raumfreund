// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:convert';

import '../../monitor/domain/thresholds.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';
import 'preferences_store.dart';

/// Reads one raw stored value by key.
typedef PreferenceReader = Object? Function(String key);

/// Converts data of schema version `n` into a reader of version `n + 1`.
typedef SettingsMigration = PreferenceReader Function(PreferenceReader read);

/// Thrown by [SharedPreferencesSettingsRepository.save] when the settings
/// could not be stored completely.
final class SettingsStorageException implements Exception {
  /// Creates the exception.
  const SettingsStorageException(this.message, [this.cause]);

  /// What failed (no user data).
  final String message;

  /// Underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'SettingsStorageException: $message';
}

/// Versioned, validating persistence of [AppSettings] in SharedPreferences.
///
/// Loading never throws: every field is validated on its own, and a
/// missing, mistyped or out-of-range value falls back to its default. An
/// invalid yellow/red pair falls back to the default thresholds.
///
/// Schema versions:
///
/// New saves use one JSON snapshot so settings become visible atomically. The
/// individual keys remain readable for migration from releases that predate the
/// snapshot format.
///
/// * Version 1: thresholds, calibration, sound and vibration.
/// * Version 2 ([schemaVersion]) adds [alarmDelayKey]. Version 1 data is
///   upgraded by [migrateV1ToV2]: the alarm delay becomes the factory
///   default (10 s), because the fixed delay of version 1 was 10 s.
/// * Missing or non-integer version: treated as the current layout (fields
///   are validated individually anyway, a missing delay falls back to its
///   default).
/// * Older versions are upgraded step by step through [migrations]
///   (`migrations[n]` turns version n into n + 1). A version without a
///   migration path loads defaults.
/// * A *newer* version (written by a later app release, e.g. after a
///   downgrade) cannot be interpreted safely and loads defaults. The stored
///   data is left untouched until the user saves.
final class SharedPreferencesSettingsRepository implements SettingsRepository {
  /// Creates the repository. [openStore] defaults to the real
  /// SharedPreferences; [migrations] defaults to [defaultMigrations].
  SharedPreferencesSettingsRepository({
    Future<PreferencesStore> Function()? openStore,
    this.migrations = defaultMigrations,
  }) : _openStore = openStore ?? SharedPreferencesStore.open;

  /// Current schema version written by [save].
  static const int schemaVersion = 2;

  /// Upgrade steps of all released schema versions.
  static const Map<int, SettingsMigration> defaultMigrations = {
    1: migrateV1ToV2,
  };

  /// Storage key of the schema version.
  static const String versionKey = 'settings.schemaVersion';

  /// Storage key of the complete, atomically replaced settings snapshot.
  static const String snapshotKey = 'settings.snapshot';

  /// Storage key of the yellow threshold.
  static const String yellowKey = 'settings.yellowDb';

  /// Storage key of the red threshold.
  static const String redKey = 'settings.redDb';

  /// Storage key of the calibration correction.
  static const String calibrationKey = 'settings.calibrationCorrectionDb';

  /// Storage key of the alarm sound flag.
  static const String soundKey = 'settings.alarmSoundEnabled';

  /// Storage key of the vibration flag.
  static const String vibrationKey = 'settings.vibrationEnabled';

  /// Storage key of the alarm delay in seconds (since schema version 2).
  static const String alarmDelayKey = 'settings.alarmDelaySeconds';

  /// Upgrades version 1 data: the delay was fixed at the factory default
  /// then, so any value found under [alarmDelayKey] cannot stem from the
  /// user and is ignored.
  static PreferenceReader migrateV1ToV2(PreferenceReader read) =>
      (key) => switch (key) {
        alarmDelayKey => AppSettings.defaultAlarmDelaySeconds,
        versionKey => 2,
        _ => read(key),
      };

  /// Upgrade steps keyed by the version they upgrade from.
  final Map<int, SettingsMigration> migrations;

  final Future<PreferencesStore> Function() _openStore;
  Future<PreferencesStore>? _store;

  @override
  Future<AppSettings> load() async {
    final PreferencesStore store;
    try {
      store = await _storeOnce();
    } on Exception {
      // Storage unavailable: the app must still work, with defaults.
      return AppSettings.defaults;
    }
    final snapshot = store.read(snapshotKey);
    final source = snapshot == null ? store.read : _snapshotReader(snapshot);
    if (source == null) return AppSettings.defaults;
    final reader = _upgrade(source);
    return reader == null ? AppSettings.defaults : decode(reader);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final PreferencesStore store;
    try {
      store = await _storeOnce();
    } on Exception catch (error) {
      throw SettingsStorageException('storage unavailable', error);
    }
    final snapshot = jsonEncode(_encode(settings));
    await _write(snapshotKey, () => store.writeString(snapshotKey, snapshot));
  }

  /// Builds validated settings from current-schema data.
  static AppSettings decode(PreferenceReader read) {
    final yellow = _intIn(
      read(yellowKey),
      Thresholds.minDb,
      Thresholds.maxDb,
      Thresholds.defaultYellowDb,
    );
    final red = _intIn(
      read(redKey),
      Thresholds.minDb,
      Thresholds.maxDb,
      Thresholds.defaultRedDb,
    );
    final defaults = AppSettings.defaults;
    return AppSettings(
      thresholds:
          Thresholds.tryCreate(yellowDb: yellow, redDb: red) ??
          Thresholds.defaults,
      calibrationCorrectionDb: _intIn(
        read(calibrationKey),
        AppSettings.minCalibrationDb,
        AppSettings.maxCalibrationDb,
        defaults.calibrationCorrectionDb,
      ),
      alarmSoundEnabled: _bool(read(soundKey), defaults.alarmSoundEnabled),
      vibrationEnabled: _bool(read(vibrationKey), defaults.vibrationEnabled),
      alarmDelaySeconds: _intIn(
        read(alarmDelayKey),
        AppSettings.minAlarmDelaySeconds,
        AppSettings.maxAlarmDelaySeconds,
        defaults.alarmDelaySeconds,
      ),
    );
  }

  Future<PreferencesStore> _storeOnce() async {
    final pending = _store ??= _openStore();
    try {
      return await pending;
    } on Exception {
      _store = null; // allow a retry on the next call
      rethrow;
    }
  }

  static Map<String, Object> _encode(AppSettings settings) => {
    versionKey: schemaVersion,
    yellowKey: settings.thresholds.yellowDb,
    redKey: settings.thresholds.redDb,
    calibrationKey: settings.calibrationCorrectionDb,
    soundKey: settings.alarmSoundEnabled,
    vibrationKey: settings.vibrationEnabled,
    alarmDelayKey: settings.alarmDelaySeconds,
  };

  static PreferenceReader? _snapshotReader(Object raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded.containsKey(versionKey) ? (key) => decoded[key] : null;
    } on FormatException {
      return null;
    }
  }

  /// Returns a reader of the current schema, or null if the stored version
  /// cannot be interpreted.
  PreferenceReader? _upgrade(PreferenceReader read) {
    final stored = read(versionKey);
    if (stored is! int) return read;
    if (stored > schemaVersion) return null;
    var reader = read;
    for (var version = stored; version < schemaVersion; version++) {
      final migration = migrations[version];
      if (migration == null) return null;
      reader = migration(reader);
    }
    return reader;
  }

  static Future<void> _write(String key, Future<bool> Function() write) async {
    final bool ok;
    try {
      ok = await write();
    } on Exception catch (error) {
      throw SettingsStorageException('writing $key failed', error);
    }
    if (!ok) throw SettingsStorageException('writing $key was rejected');
  }

  static int _intIn(Object? value, int min, int max, int fallback) =>
      value is int && value >= min && value <= max ? value : fallback;

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;
}
