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
    return 'Alarm in $seconds Sekunden';
  }

  @override
  String get alarmImminent => 'Alarm gleich';

  @override
  String get alarmFired => 'Alarm ausgelöst';

  @override
  String get alarmPlaying => 'Alarmton läuft – kurze Messpause';

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
      'Messung gestört – zu wenige Messwerte. Das Handy drosselt vielleicht das Mikrofon.';

  @override
  String get kittyIdle => 'Mia sitzt gemütlich da und wartet';

  @override
  String get kittyHappy => 'Mia ist fröhlich und schnurrt';

  @override
  String get kittyUneasy => 'Mia ist unruhig, es wird ihr zu laut';

  @override
  String get kittyScared => 'Mia hat Angst – es ist viel zu laut';

  @override
  String get kittyAwaySign => 'Zu laut – Mia hat sich versteckt';

  @override
  String kittyWearing(String items) {
    return 'Mia trägt: $items';
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
      other: '$count Sterne heute',
      one: '1 Stern heute',
      zero: 'Noch keine Sterne heute',
    );
    return '$_temp0 · $total im Sternenladen';
  }

  @override
  String get starsHint => 'Für jede ruhige Minute gibt es einen Stern';

  @override
  String starsProgress(int percent) {
    return '$percent % bis zum nächsten Stern';
  }

  @override
  String get starsJustEarned => 'Neuer Stern!';

  @override
  String get errorPermissionDeniedTitle => 'Mikrofon nicht erlaubt';

  @override
  String get errorPermissionDeniedBody =>
      'Raumfreund braucht das Mikrofon, um die Lautstärke zu schätzen. Es wird nichts aufgenommen oder gespeichert.';

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
    return '$name um 1 dB verringern';
  }

  @override
  String settingsIncrease(String name) {
    return '$name um 1 dB erhöhen';
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
      'Handy-Mikrofone hören unterschiedlich gut. Lege ein Referenz-Schallpegelmessgerät direkt neben das Handy, sorge für ein gleichmäßiges Geräusch (z. B. Rauschen oder einen Lüfter) und verschiebe die Korrektur, bis Raumfreund denselben Wert zeigt wie das Messgerät. Die Anzeige bleibt trotzdem eine Schätzung.';

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
    return 'So funktioniert der Alarm: Er ertönt erst, wenn es insgesamt $seconds Sekunden gelb oder rot bleibt – kurze Pausen zählen mit – und nur einmal pro Phase. Wechselt die Ampel die Farbe, beginnt die Zeit neu; wird sie wieder grün, wird alles zurückgesetzt. Einstellbar sind $min bis $max Sekunden, Standard sind $standard Sekunden.';
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
      'Nach 5 Sekunden im grünen Bereich gibt es einen Stern statt nach 60 Sekunden. Standardmäßig aus; gesammelte Sterne bleiben erhalten.';

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
      'Raumfreund arbeitet komplett offline. Es wird kein Ton aufgenommen, gespeichert oder versendet – das Mikrofonsignal wird nur kurz im Arbeitsspeicher zu einer Zahl verrechnet und sofort verworfen. Keine Konten, keine Werbung, kein Tracking.';

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
      'Sterne werden gerade nur zwischengespeichert. Kaufen und Anlegen gehen erst, wenn der Speicher wieder antwortet.';

  @override
  String get shopSaveFailed =>
      'Speichern hat nicht geklappt. Deine Sterne bleiben erhalten; es wird beim nächsten Öffnen der App oder des Sternenladens und bei der nächsten Änderung erneut versucht.';

  @override
  String get shopDismiss => 'Ausblenden';

  @override
  String get shopBuy => 'Kaufen';

  @override
  String get shopEquip => 'Anlegen';

  @override
  String get shopUnequip => 'Ablegen';

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
  String get shopWorn => 'Wird getragen';

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
      'Die Sterne wurden zurückgesetzt, aber das Speichern hat nicht geklappt. Es wird später erneut versucht.';
}
