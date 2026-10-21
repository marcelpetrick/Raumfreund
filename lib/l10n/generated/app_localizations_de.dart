// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Raumfreund';

  @override
  String get actionSettings => 'Einstellungen';

  @override
  String get actionAbout => 'Über Raumfreund';

  @override
  String get actionShop => 'Sternenladen';

  @override
  String get actionBack => 'Zurück';

  @override
  String get statusIdle => 'Bereit – starte die Messung';

  @override
  String get statusStarting => 'Messung startet …';

  @override
  String get statusStopping => 'Messung wird beendet …';

  @override
  String get statusGreen => 'Alles im grünen Bereich!';

  @override
  String get statusYellow => 'Bitte etwas leiser';

  @override
  String get statusRed => 'Oh weh, das ist zu laut!';

  @override
  String get statusSleeping => 'Mia schläft – Messung pausiert';

  @override
  String get statusWaking => 'Mia wacht auf …';

  @override
  String get sleepingHint =>
      'Im Hintergrund hört Raumfreund nicht zu. Sobald du die App wieder öffnest, wacht Mia auf und misst weiter.';

  @override
  String get statusError => 'Messung nicht möglich';

  @override
  String get zoneGreen => 'Grün – angenehm leise';

  @override
  String get zoneYellow => 'Gelb – etwas laut';

  @override
  String get zoneRed => 'Rot – zu laut';

  @override
  String alarmCountdown(int seconds) {
    return 'Alarm in $seconds s';
  }

  @override
  String alarmCountdownSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Alarm in $seconds Sekunden',
      one: 'Alarm in 1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get alarmImminent => 'Alarm gleich';

  @override
  String get alarmFired => 'Alarm ausgelöst';

  @override
  String get alarmPlaying => 'Alarm läuft – kurze Messpause';

  @override
  String get measureStart => 'Messung starten';

  @override
  String get measureStop => 'Messung stoppen';

  @override
  String get measureBusy => 'Bitte warten …';

  @override
  String gaugeValue(int value) {
    return '$value dB';
  }

  @override
  String get gaugeNoValue => '– dB';

  @override
  String get gaugeEstimated => 'geschätzt';

  @override
  String get gaugeSemanticsLabel => 'Lautstärke, geschätzt';

  @override
  String gaugeSemanticsValue(int value, String zone) {
    return '$value Dezibel, $zone';
  }

  @override
  String get gaugeSemanticsNoValue => 'kein Messwert';

  @override
  String get timelineTitle => 'Verlauf der letzten 10 Minuten';

  @override
  String get timelineMinus10 => '−10 min';

  @override
  String get timelineMinus5 => '−5 min';

  @override
  String get timelineNow => 'jetzt';

  @override
  String timelineSummary(int max, int average, int greenPercent) {
    return 'Diagrammpunkte aus 10-Sekunden-Mittelwerten: höchster $max dB, Durchschnitt $average dB, $greenPercent % der Punkte im grünen Bereich';
  }

  @override
  String get timelineEmpty => 'Noch keine Messwerte';

  @override
  String get alarmOutputFailed =>
      'Der Alarmton konnte nicht wiedergegeben werden. Die Messung läuft weiter.';

  @override
  String get signalThin =>
      'Messung unsicher – zu wenige Messwerte. Das Handy drosselt vielleicht das Mikrofon.';

  @override
  String get kittyIdle => 'Mia sitzt gemütlich da und wartet';

  @override
  String get kittyHappy => 'Mia ist fröhlich und schnurrt';

  @override
  String get kittyUneasy => 'Mia ist unruhig, es wird ihr zu laut';

  @override
  String get kittyScared => 'Mia hat Angst – es ist viel zu laut';

  @override
  String get kittySleeping => 'Mia schläft, bis du zurückkommst';

  @override
  String get kittyAwaySign => 'Zu laut – Mia hat sich versteckt';

  @override
  String kittyWearing(String items) {
    return 'Bei Mia: $items';
  }

  @override
  String get accessoryBow => 'Schleife';

  @override
  String get accessoryScarf => 'Schal';

  @override
  String get accessoryHat => 'Partyhut';

  @override
  String get accessoryCushion => 'Kissen';

  @override
  String get accessoryMouse => 'Spielzeugmaus';

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
      zero: 'Noch keine Sterne',
    );
    return '$_temp0';
  }

  @override
  String starsWithTotal(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Sterne',
      one: '1 neuer Stern',
      zero: 'Noch keine neuen Sterne',
    );
    return '$_temp0 · $total im Sternenladen';
  }

  @override
  String get starsHint =>
      'Für jede Minute am Stück im grünen Bereich gibt es einen Stern';

  @override
  String get starsHintQuickTest =>
      'Stern-Testmodus: alle 5 Sekunden am Stück im grünen Bereich ein Stern';

  @override
  String starsProgress(int percent) {
    return 'Nächster Stern: $percent % geschafft';
  }

  @override
  String get starsJustEarned => 'Neuer Stern!';

  @override
  String get errorPermissionDeniedTitle => 'Mikrofon nicht erlaubt';

  @override
  String get errorPermissionDeniedBody =>
      'Raumfreund braucht das Mikrofon, um die Lautstärke zu schätzen. Der Ton wird nur kurz ausgewertet – nie gespeichert oder verschickt.';

  @override
  String get errorPermanentlyDeniedTitle => 'Mikrofon dauerhaft gesperrt';

  @override
  String get errorPermanentlyDeniedBody =>
      'Der Mikrofonzugriff wurde dauerhaft abgelehnt. Erlaube ihn in den App-Einstellungen von Android unter „Berechtigungen“.';

  @override
  String get errorMicrophoneBusyTitle => 'Mikrofon belegt';

  @override
  String get errorMicrophoneBusyBody =>
      'Eine andere App benutzt gerade das Mikrofon, z. B. ein Anruf oder eine Sprachaufnahme, oder der Mikrofonzugriff ist in den Android-Schnelleinstellungen ausgeschaltet. Beende die App oder schalte den Zugriff ein und versuche es erneut.';

  @override
  String get errorRecordingAbortedTitle => 'Messung abgebrochen';

  @override
  String get errorRecordingAbortedBody =>
      'Die Messung wurde unerwartet unterbrochen. Starte sie einfach noch einmal.';

  @override
  String get errorUnavailableTitle => 'Kein Mikrofon verfügbar';

  @override
  String get errorUnavailableBody =>
      'Auf diesem Gerät konnte kein nutzbares Mikrofon gefunden werden.';

  @override
  String get errorNoReadingsTitle => 'Keine Messwerte';

  @override
  String get errorNoReadingsBody =>
      'Das Mikrofon liefert gerade keine Werte oder nur völlige Stille, deshalb wurde die Messung beendet. Vielleicht ist der Mikrofonzugriff in den Android-Schnelleinstellungen ausgeschaltet oder das Mikrofon reagiert nicht. Prüfe das und starte die Messung erneut.';

  @override
  String get errorOpenSettings => 'Einstellungen öffnen';

  @override
  String get errorRetry => 'Erneut versuchen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsThresholdsHeading => 'Grenzwerte';

  @override
  String get settingsYellowLabel => 'Gelb ab';

  @override
  String get settingsRedLabel => 'Rot ab';

  @override
  String settingsDbValue(int value) {
    return '$value dB';
  }

  @override
  String settingsDecrease(String name) {
    return '$name: 1 dB weniger';
  }

  @override
  String settingsIncrease(String name) {
    return '$name: 1 dB mehr';
  }

  @override
  String get settingsThresholdsHint =>
      'Gelb liegt immer unter Rot. Schiebst du eine Grenze über die andere, rückt die andere automatisch mit.';

  @override
  String get settingsCalibrationHeading => 'Kalibrierung';

  @override
  String get settingsCalibrationLabel => 'Korrektur';

  @override
  String settingsCalibrationValue(String value) {
    return '$value dB';
  }

  @override
  String get settingsCalibrationExplanation =>
      'Handy-Mikrofone sind unterschiedlich empfindlich. Lege ein Schallpegelmessgerät direkt neben das Handy und sorge für ein gleichmäßiges Geräusch (z. B. Rauschen oder einen Lüfter). Vergleiche die Anzeige von Raumfreund mit dem Messgerät, stelle hier die Differenz als Korrektur ein, speichere und prüfe erneut. Die Anzeige bleibt trotzdem eine Schätzung.';

  @override
  String get settingsAlarmHeading => 'Alarm';

  @override
  String get settingsAlarmDelayLabel => 'Alarm nach';

  @override
  String settingsSecondsValue(int value) {
    return '$value Sekunden';
  }

  @override
  String get settingsAlarmDelayDecrease =>
      'Alarm-Wartezeit um 1 Sekunde verkürzen';

  @override
  String get settingsAlarmDelayIncrease =>
      'Alarm-Wartezeit um 1 Sekunde verlängern';

  @override
  String settingsAlarmDelayRule(int seconds, int min, int max, int standard) {
    return 'So funktioniert der Alarm: Ist die Ampel $seconds Sekunden lang gelb (oder $seconds Sekunden lang rot), kommt der Alarm. Kurze leisere Momente unterbrechen die Zeit nicht. Springt die Ampel zwischen Gelb und Rot oder wird sie grün, beginnt die Zeit von vorn – und auch nach jedem Alarm: Bleibt es laut, kommt er erneut. Einstellbar sind $min bis $max Sekunden, Standard sind $standard Sekunden.';
  }

  @override
  String get settingsAlarmSound => 'Alarmton';

  @override
  String get settingsAlarmSoundHint => 'Ein kurzer, freundlicher Ton';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationHint => 'Kurze Vibration, sofern vorhanden';

  @override
  String get settingsStarTestHeading => 'Sterne testen';

  @override
  String get settingsStarTestMode => 'Schneller Stern-Testmodus';

  @override
  String get settingsStarTestModeHint =>
      'Nach 5 Sekunden im grünen Bereich gibt es einen Stern statt nach 60 Sekunden. Auch diese Sterne landen im Sternenladen. Standardmäßig aus; gesammelte Sterne bleiben erhalten.';

  @override
  String get settingsSave => 'Speichern';

  @override
  String get settingsRetrySave => 'Erneut speichern';

  @override
  String get settingsSaveError =>
      'Speichern fehlgeschlagen. Deine Änderungen sind noch da – versuche es bitte erneut.';

  @override
  String get settingsCancel => 'Abbrechen';

  @override
  String get settingsDefaults => 'Standardwerte';

  @override
  String get settingsDefaultsApplied =>
      'Standardwerte eingetragen – zum Übernehmen bitte speichern.';

  @override
  String get aboutTitle => 'Über Raumfreund';

  @override
  String get aboutTagline =>
      'Die freundliche Lautstärkeampel für gemeinsame Räume.';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuild => 'Build';

  @override
  String aboutBuildValue(int buildNumber, String commit) {
    return '$buildNumber (Commit $commit)';
  }

  @override
  String get aboutAuthor => 'Autor';

  @override
  String get aboutEmail => 'E-Mail';

  @override
  String get aboutProject => 'Projekt';

  @override
  String get aboutLicense => 'Lizenz';

  @override
  String get aboutLicenseValue => 'GNU GPL v3.0 (GPL-3.0-only)';

  @override
  String get aboutPrivacyHeading => 'Datenschutz';

  @override
  String get aboutPrivacyBody =>
      'Raumfreund arbeitet komplett offline. Das Mikrofonsignal wird nur kurz im Arbeitsspeicher zu einer Lautstärkezahl verrechnet und sofort verworfen – kein Ton wird gespeichert oder versendet. Auf dem Gerät bleiben nur Einstellungen und Sterne. Keine Konten, keine Werbung, kein Tracking.';

  @override
  String get aboutMeasurementHeading => 'Hinweis zur Messung';

  @override
  String get aboutMeasurementBody =>
      'Die angezeigten Werte sind Schätzungen aus dem Handy-Mikrofon. Raumfreund ist kein geeichtes Schallpegelmessgerät und nicht für Arbeitsschutz oder Gutachten geeignet.';

  @override
  String get aboutLicensesButton => 'Open-Source-Lizenzen';

  @override
  String get shopTitle => 'Sternenladen';

  @override
  String shopBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Du hast $count Sterne',
      one: 'Du hast 1 Stern',
      zero: 'Du hast noch keine Sterne',
    );
    return '$_temp0';
  }

  @override
  String get shopLoading => 'Sterne werden geladen …';

  @override
  String get shopLoadFailed =>
      'Die Sterne können gerade nicht geladen werden. Kaufen und Geben klappen erst wieder, wenn das funktioniert.';

  @override
  String get shopSaveFailed =>
      'Speichern hat nicht geklappt. Deine Sterne bleiben erhalten; es wird beim nächsten Öffnen der App oder des Sternenladens und bei der nächsten Änderung erneut versucht.';

  @override
  String get shopDismiss => 'Ausblenden';

  @override
  String get shopBuy => 'Kaufen';

  @override
  String get shopEquip => 'Geben';

  @override
  String get shopUnequip => 'Wegnehmen';

  @override
  String shopMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Sterne',
      one: 'Noch 1 Stern',
    );
    return '$_temp0';
  }

  @override
  String get shopWorn => 'Bei Mia';

  @override
  String get shopOwned => 'Gekauft';

  @override
  String shopPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sterne',
      one: '1 Stern',
    );
    return '$_temp0';
  }

  @override
  String shopConfirmTitle(String item, String price) {
    return '$item für $price kaufen?';
  }

  @override
  String get shopConfirmBuy => 'Kaufen';

  @override
  String get shopConfirmCancel => 'Abbrechen';

  @override
  String get settingsResetHeading => 'Für Lehrkräfte';

  @override
  String get settingsResetBody =>
      'Löscht alle Sterne und gekauften Sachen im Sternenladen. Das passiert sofort und gehört nicht zu Speichern oder Abbrechen – auch Abbrechen macht es nicht rückgängig.';

  @override
  String get settingsResetButton => 'Sterne zurücksetzen';

  @override
  String get settingsResetConfirmTitle =>
      'Alle Sterne und gekauften Sachen löschen?';

  @override
  String get settingsResetConfirmBody =>
      'Das kann nicht rückgängig gemacht werden.';

  @override
  String get settingsResetConfirm => 'Löschen';

  @override
  String get settingsResetDone =>
      'Alle Sterne und gekauften Sachen wurden gelöscht.';

  @override
  String get settingsResetNotReady =>
      'Die Sterne werden noch geladen. Bitte versuche es gleich noch einmal.';

  @override
  String get settingsResetSaveFailed =>
      'Die Sterne wurden zurückgesetzt, aber das Speichern hat nicht geklappt. Es wird später erneut versucht – bis dahin können die alten Sterne nach einem Neustart der App wieder auftauchen.';

  @override
  String get settingsLanguageHeading => 'Sprache';

  @override
  String get settingsLanguageHint =>
      'Die Sprache wechselt sofort und wird gleich gespeichert – unabhängig von Speichern und Abbrechen.';

  @override
  String get settingsLanguageSaveFailed =>
      'Die Sprache wurde gewechselt, aber nicht gespeichert. Beim nächsten Start der App gilt wieder die vorherige Sprache.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageChinese => '中文（简体）';
}
