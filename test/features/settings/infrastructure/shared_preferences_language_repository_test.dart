// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/features/settings/infrastructure/preferences_store.dart';
import 'package:raumfreund/features/settings/infrastructure/shared_preferences_language_repository.dart';
import 'package:raumfreund/features/settings/infrastructure/shared_preferences_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fakes/fake_preferences_store.dart';

const _key = SharedPreferencesLanguageRepository.languageKey;

SharedPreferencesLanguageRepository _repository(PreferencesStore store) =>
    SharedPreferencesLanguageRepository(openStore: () async => store);

void main() {
  _loadTests();
  _saveTests();

  test('the real SharedPreferences store keeps the language', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesLanguageRepository();
    await repository.save(AppLanguage.chinese);
    expect(
      await SharedPreferencesLanguageRepository().load(),
      AppLanguage.chinese,
    );
  });
}

void _loadTests() {
  test('nothing stored loads German', () async {
    expect(
      await _repository(FakePreferencesStore()).load(),
      AppLanguage.german,
    );
  });

  test('a stored code loads its language', () async {
    final store = FakePreferencesStore({_key: 'hr'});
    expect(await _repository(store).load(), AppLanguage.croatian);
  });

  test('an unknown or mistyped value loads German', () async {
    for (final raw in <Object>['fr', 'EN', 3, true]) {
      final store = FakePreferencesStore({_key: raw});
      expect(
        await _repository(store).load(),
        AppLanguage.german,
        reason: '$raw',
      );
    }
  });

  test('an unavailable storage loads German and is retried', () async {
    var opens = 0;
    final store = FakePreferencesStore({_key: 'en'});
    final repository = SharedPreferencesLanguageRepository(
      openStore: () async {
        if (++opens == 1) throw const FormatException('locked');
        return store;
      },
    );
    expect(await repository.load(), AppLanguage.german);
    expect(await repository.load(), AppLanguage.english);
    expect(opens, 2);
  });
}

void _saveTests() {
  test('saving writes the language code', () async {
    final store = FakePreferencesStore();
    await _repository(store).save(AppLanguage.english);
    expect(store.values[_key], 'en');
  });

  test('saving leaves the settings snapshot alone', () async {
    final store = FakePreferencesStore({
      SharedPreferencesSettingsRepository.snapshotKey: '{"x":1}',
    });
    await _repository(store).save(AppLanguage.chinese);
    expect(
      store.values[SharedPreferencesSettingsRepository.snapshotKey],
      '{"x":1}',
    );
  });

  test('a rejected write throws', () async {
    final store = FakePreferencesStore()..rejectedKeys.add(_key);
    await expectLater(
      _repository(store).save(AppLanguage.english),
      throwsA(isA<SettingsStorageException>()),
    );
  });

  test('a failing write throws with its cause', () async {
    final store = FakePreferencesStore()..throwingKeys.add(_key);
    await expectLater(
      _repository(store).save(AppLanguage.english),
      throwsA(
        isA<SettingsStorageException>().having(
          (error) => error.cause,
          'cause',
          isA<FormatException>(),
        ),
      ),
    );
  });

  test('an unavailable storage makes saving throw', () async {
    final repository = SharedPreferencesLanguageRepository(
      openStore: () async => throw const FormatException('locked'),
    );
    await expectLater(
      repository.save(AppLanguage.english),
      throwsA(isA<SettingsStorageException>()),
    );
  });
}
