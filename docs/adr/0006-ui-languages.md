<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# ADR 0006 – Four UI languages, switched live in Settings

- Status: accepted (owner request 2026-10-21)
- Date: 2026-10-21
- Amends: section 6 of `docs/vision.md` ("Deutsche Oberfläche; Texte zentral
  und für spätere Lokalisierung vorbereitet") and the AGENTS.md rule "UI is
  German"

## Context

The vision asked for a German UI with all texts prepared for later
localization. The owner now wants German, English, Croatian and Mandarin,
switchable live in Settings, remembered across restarts, with German as the
default.

## Decision

- **Languages:** German (`de`, the template `lib/l10n/app_de.arb`), English
  (`en`), Croatian (`hr`) and Mandarin in Simplified Chinese characters
  (`zh`). `AppLanguage` in the settings domain is the single list; a test
  keeps it equal to the generated `AppLocalizations.supportedLocales`.
- **No device-language detection.** The app starts in the stored language,
  or German when nothing is stored. A classroom device is shared and
  should look the same for everyone, and the owner set German as the
  default. Android's per-app language setting is not used for the same
  reason.
- **Live switch outside the draft.** Settings shows the four languages, each
  under its own name ("Deutsch", "English", "Hrvatski", "中文（简体）") so a
  person who cannot read the current language still finds theirs. Picking
  one switches the whole app at once (`MaterialApp.locale` follows
  `LanguageController`) and stores it immediately. Like the star reset, this
  is not part of the Save/Cancel draft: Cancel does not undo it. The draft
  of the other settings survives the switch, because rebuilding
  `MaterialApp` keeps the navigator and the open Settings route.
- **Own storage key.** The language is stored as its code under
  `settings.language`, not in the settings snapshot. The snapshot is written
  on Save from the draft; sharing it would let an older draft overwrite a
  newer language or the other way round. A missing, unknown or mistyped value
  and an unavailable storage load German; loading never fails.
- **No flash of German.** `main()` loads the language before the first
  frame. A failed write keeps the chosen language for the running app and
  says so in that language; the next start then uses the previously stored
  one.
- **Translations are checked, not trusted.** A test compares every
  translation with the template: same keys, same placeholders, the plural
  categories the language needs (Croatian `one`/`few`/`other`) and no text
  left in German except names, units and words that are spelled the same.
  Layout tests render every page in every language on a 360 px phone at
  normal and doubled text size. The translations were reviewed by an
  independent red-team agent; a native-speaker review on a device remains
  open for the owner.

## Consequences

- Every new user-visible string needs an entry in all four ARB files; the
  pipeline fails otherwise.
- A fifth language means one ARB file and one `AppLanguage` value.
- The app name "Raumfreund" and the cat's name "Mia" are not translated.
- Native error messages from the platform channel are developer
  diagnostics; the UI maps their codes to localized texts.
