// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/infrastructure/preferences_store.dart';
import 'package:raumfreund/features/settings/infrastructure/shared_preferences_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_preferences_store.dart';

typedef Repo = SharedPreferencesSettingsRepository;

/// A valid, non-default stored data set of the current schema.
Map<String, Object?> validData() => {
  Repo.versionKey: Repo.schemaVersion,
  Repo.yellowKey: 55,
  Repo.redKey: 75,
  Repo.calibrationKey: -5,
  Repo.soundKey: false,
  Repo.vibrationKey: false,
};

final AppSettings validSettings = AppSettings(
  thresholds: Thresholds(yellowDb: 55, redDb: 75),
  calibrationCorrectionDb: -5,
  alarmSoundEnabled: false,
  vibrationEnabled: false,
);

Future<AppSettings> loadFrom(
  Map<String, Object?> data, {
  Map<int, SettingsMigration> migrations = const {},
}) => Repo(
  openStore: () async => FakePreferencesStore(data),
  migrations: migrations,
).load();

void main() {
  loadTests();
  invalidFieldTests();
  versionTests();
  saveTests();
  sharedPreferencesTests();
}

void loadTests() {
  group('load', () {
    test('empty storage gives defaults', () async {
      expect(await loadFrom({}), AppSettings.defaults);
    });

    test('valid data round-trips', () async {
      expect(await loadFrom(validData()), validSettings);
    });

    test('unavailable storage gives defaults and allows a retry', () async {
      var attempts = 0;
      final repo = Repo(
        openStore: () async {
          attempts++;
          if (attempts == 1) throw const FormatException('locked');
          return FakePreferencesStore(validData());
        },
      );
      expect(await repo.load(), AppSettings.defaults);
      expect(await repo.load(), validSettings);
      expect(await repo.load(), validSettings);
      expect(attempts, 2);
    });
  });
}

void invalidFieldTests() {
  group('invalid fields fall back per field', () {
    final cases = <String, Object?>{
      'missing': null,
      'string': '60',
      'double': 60.0,
      'bool': true,
      'negative': -1,
      'too large': 131,
    };
    for (final entry in cases.entries) {
      for (final key in [Repo.yellowKey, Repo.redKey]) {
        test('$key ${entry.key} → default for that limit', () async {
          final data = validData()..[key] = entry.value;
          final loaded = await loadFrom(data);
          expect(
            loaded.thresholds,
            key == Repo.yellowKey
                ? Thresholds(yellowDb: Thresholds.defaultYellowDb, redDb: 75)
                : Thresholds(yellowDb: 55, redDb: Thresholds.defaultRedDb),
          );
          expect(loaded.calibrationCorrectionDb, -5);
          expect(loaded.alarmSoundEnabled, isFalse);
        });
      }
    }

    for (final bad in <Object?>[null, '3', 3.0, -31, 31]) {
      test('calibration $bad → 0, rest kept', () async {
        final loaded = await loadFrom(validData()..[Repo.calibrationKey] = bad);
        expect(loaded.calibrationCorrectionDb, 0);
        expect(loaded.thresholds, validSettings.thresholds);
      });
    }

    test('calibration limits are accepted', () async {
      expect(
        (await loadFrom(validData()..[Repo.calibrationKey] = 30))
            .calibrationCorrectionDb,
        30,
      );
      expect(
        (await loadFrom(validData()..[Repo.calibrationKey] = -30))
            .calibrationCorrectionDb,
        -30,
      );
    });

    for (final key in [Repo.soundKey, Repo.vibrationKey]) {
      for (final bad in <Object?>[null, 1, 'true']) {
        test('$key $bad → default true', () async {
          final loaded = await loadFrom(validData()..[key] = bad);
          expect(
            key == Repo.soundKey
                ? loaded.alarmSoundEnabled
                : loaded.vibrationEnabled,
            isTrue,
          );
          expect(loaded.thresholds, validSettings.thresholds);
        });
      }
    }

    test('invalid pairs give default thresholds', () async {
      // (90, 131): red falls back to 80 per field, then the pair is invalid.
      for (final pair in [(70, 70), (80, 60), (90, 131), (85, 50)]) {
        final data = validData()
          ..[Repo.yellowKey] = pair.$1
          ..[Repo.redKey] = pair.$2;
        expect((await loadFrom(data)).thresholds, Thresholds.defaults);
      }
    });

    test('scale limits 0/130 are a valid pair', () async {
      final data = validData()
        ..[Repo.yellowKey] = 0
        ..[Repo.redKey] = 130;
      final loaded = await loadFrom(data);
      expect(loaded.thresholds.yellowDb, 0);
      expect(loaded.thresholds.redDb, 130);
    });
  });
}

void versionTests() {
  group('schema version', () {
    test('missing or mistyped version is read as current schema', () async {
      expect(
        await loadFrom(validData()..remove(Repo.versionKey)),
        validSettings,
      );
      expect(
        await loadFrom(validData()..[Repo.versionKey] = 'one'),
        validSettings,
      );
    });

    test('a newer version loads defaults', () async {
      expect(
        await loadFrom(validData()..[Repo.versionKey] = Repo.schemaVersion + 1),
        AppSettings.defaults,
      );
    });

    test('an older version without migration loads defaults', () async {
      expect(
        await loadFrom(validData()..[Repo.versionKey] = 0),
        AppSettings.defaults,
      );
    });

    test('an older version is migrated step by step', () async {
      // Hypothetical v0 stored the yellow limit under another key.
      final v0 = <String, Object?>{
        Repo.versionKey: 0,
        'legacy.yellow': 50,
        Repo.redKey: 70,
      };
      PreferenceReader migrate(PreferenceReader read) =>
          (key) => key == Repo.yellowKey ? read('legacy.yellow') : read(key);
      final loaded = await loadFrom(v0, migrations: {0: migrate});
      expect(loaded.thresholds, Thresholds(yellowDb: 50, redDb: 70));
    });
  });
}

void saveTests() {
  group('save', () {
    test('writes all keys and the version', () async {
      final store = FakePreferencesStore();
      final repo = Repo(openStore: () async => store);
      await repo.save(validSettings);
      expect(store.values, validData());
      expect(await repo.load(), validSettings);
    });

    test('a rejected write throws and keeps the old version marker', () async {
      final store = FakePreferencesStore()..rejectedKeys.add(Repo.redKey);
      final repo = Repo(openStore: () async => store);
      await expectLater(
        repo.save(validSettings),
        throwsA(isA<SettingsStorageException>()),
      );
      expect(store.values.containsKey(Repo.versionKey), isFalse);
    });

    test('a throwing write is wrapped', () async {
      final store = FakePreferencesStore()..throwingKeys.add(Repo.soundKey);
      final repo = Repo(openStore: () async => store);
      final error = await repo
          .save(validSettings)
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(error, isA<SettingsStorageException>());
      final storageError = error! as SettingsStorageException;
      expect(storageError.cause, isA<FormatException>());
      expect(storageError.toString(), contains(Repo.soundKey));
    });

    test('unavailable storage throws', () async {
      final repo = Repo(openStore: () async => throw const FormatException());
      await expectLater(
        repo.save(validSettings),
        throwsA(isA<SettingsStorageException>()),
      );
    });
  });
}

void sharedPreferencesTests() {
  group('SharedPreferencesStore', () {
    test('reads and writes through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({Repo.yellowKey: 42});
      final store = await SharedPreferencesStore.open();
      expect(store.read(Repo.yellowKey), 42);
      expect(await store.writeInt(Repo.redKey, 99), isTrue);
      expect(await store.writeBool(Repo.soundKey, value: false), isTrue);
      expect(store.read(Repo.redKey), 99);
      expect(store.read(Repo.soundKey), isFalse);
    });

    test('default repository persists across instances', () async {
      SharedPreferences.setMockInitialValues({});
      await Repo().save(validSettings);
      expect(await Repo().load(), validSettings);
    });
  });
}
