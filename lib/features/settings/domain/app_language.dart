// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Languages of the user interface (ADR 0006).
///
/// The app does not follow the device language: a shared classroom device
/// should look the same for everyone, so German stays the default until
/// someone picks another language in Settings.
enum AppLanguage {
  /// German, the default and the template of the translations.
  german('de'),

  /// English.
  english('en'),

  /// Croatian.
  croatian('hr'),

  /// Mandarin in Simplified Chinese characters.
  chinese('zh');

  const AppLanguage(this.code);

  /// Language used until the user chooses one.
  static const AppLanguage defaultLanguage = german;

  /// Language code of the matching `lib/l10n/app_<code>.arb` file.
  final String code;

  /// The language stored as [code], or null for anything else.
  static AppLanguage? fromCode(Object? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
