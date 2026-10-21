// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

void main() {
  test('German is the default language', () {
    expect(AppLanguage.defaultLanguage, AppLanguage.german);
  });

  test('every language round-trips through its code', () {
    for (final language in AppLanguage.values) {
      expect(AppLanguage.fromCode(language.code), language);
    }
  });

  test('unknown or mistyped codes are rejected', () {
    expect(AppLanguage.fromCode('fr'), isNull);
    expect(AppLanguage.fromCode('DE'), isNull);
    expect(AppLanguage.fromCode(''), isNull);
    expect(AppLanguage.fromCode(null), isNull);
    expect(AppLanguage.fromCode(1), isNull);
  });

  test('the languages are exactly the generated localizations', () {
    expect(
      AppLanguage.values.map((language) => language.code),
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
    );
  });
}
