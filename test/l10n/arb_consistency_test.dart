// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';

/// Checks every translation against the German template, so a missing,
/// half-translated or broken string fails the pipeline instead of showing
/// up on a classroom device.
void main() {
  final template = _messages('de');

  for (final language in AppLanguage.values.skip(1)) {
    final code = language.code;
    final messages = _messages(code);

    test('$code has exactly the template keys', () {
      expect(messages.keys.toSet(), template.keys.toSet());
    });

    test('$code uses exactly the template placeholders', () {
      for (final key in template.keys) {
        expect(
          _placeholders(messages[key] ?? ''),
          _placeholders(template[key]!),
          reason: '$code.$key',
        );
      }
    });

    test('$code plurals name the forms the language needs', () {
      for (final MapEntry(:key, :value) in messages.entries) {
        if (!value.contains(', plural,')) continue;
        for (final form in _pluralForms[code]!) {
          expect(value, contains('$form{'), reason: '$code.$key');
        }
      }
    });

    test('$code translates everything that is not a name or unit', () {
      for (final MapEntry(:key, :value) in messages.entries) {
        if (_sameEverywhere.contains(key)) continue;
        if (_sameIn[code]?.contains(key) ?? false) continue;
        expect(value, isNot(template[key]), reason: '$code.$key is German');
      }
    });
  }

  test('language names are the same in every language', () {
    for (final language in AppLanguage.values) {
      final messages = _messages(language.code);
      for (final key in _languageNames) {
        expect(messages[key], template[key], reason: '${language.code}.$key');
      }
    }
  });

  test('every template message is described for translators', () {
    final raw = _arb('de');
    for (final key in template.keys) {
      expect(raw['@$key'], isA<Map<String, dynamic>>(), reason: key);
    }
  });
}

const _languageNames = {
  'languageGerman',
  'languageEnglish',
  'languageCroatian',
  'languageChinese',
};

/// Brand, units, numbers and language names stay as they are.
const _sameEverywhere = {
  'appTitle',
  'gaugeValue',
  'gaugeNoValue',
  'settingsDbValue',
  'settingsCalibrationValue',
  'aboutLicenseValue',
  ..._languageNames,
};

/// Words that are spelled the same as in German.
const _sameIn = <String, Set<String>>{
  'en': {
    'alarmCountdown',
    'settingsAlarmHeading',
    'settingsVibration',
    'aboutVersion',
    'aboutBuild',
    'timelineMinus10',
    'timelineMinus5',
  },
  'hr': {
    'settingsAlarmHeading',
    'aboutBuild',
    'aboutAuthor',
    'aboutProject',
    'timelineMinus10',
    'timelineMinus5',
  },
  'zh': {},
};

/// CLDR plural categories the numbers in the app can hit.
const _pluralForms = <String, List<String>>{
  'en': ['other'],
  'hr': ['one', 'few', 'other'],
  'zh': ['other'],
};

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> _messages(String code) => {
  for (final MapEntry(:key, :value) in _arb(code).entries)
    if (!key.startsWith('@')) key: value as String,
};

/// Names of the `{placeholder}`s of an ICU message, including plural
/// selectors.
Set<String> _placeholders(String message) => {
  for (final match in RegExp(r'\{(\w+)[,}]').allMatches(message))
    match.group(1)!,
};
