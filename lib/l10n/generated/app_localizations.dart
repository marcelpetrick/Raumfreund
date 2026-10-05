import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de')];

  /// Name of the app.
  ///
  /// In de, this message translates to:
  /// **'Raumfreund'**
  String get appTitle;

  /// Tooltip/label of the settings button.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get actionSettings;

  /// Tooltip/label of the about button.
  ///
  /// In de, this message translates to:
  /// **'Über Raumfreund'**
  String get actionAbout;

  /// Tooltip of a back/close button.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get actionBack;

  /// Headline when no measurement is running.
  ///
  /// In de, this message translates to:
  /// **'Bereit – starte die Messung'**
  String get statusIdle;

  /// Headline while the measurement starts.
  ///
  /// In de, this message translates to:
  /// **'Messung startet …'**
  String get statusStarting;

  /// Headline while the measurement stops.
  ///
  /// In de, this message translates to:
  /// **'Messung wird beendet …'**
  String get statusStopping;

  /// Headline in the green zone.
  ///
  /// In de, this message translates to:
  /// **'Alles im grünen Bereich!'**
  String get statusGreen;

  /// Headline in the yellow zone.
  ///
  /// In de, this message translates to:
  /// **'Bitte etwas leiser'**
  String get statusYellow;

  /// Headline in the red zone.
  ///
  /// In de, this message translates to:
  /// **'Oh weh, das ist zu laut!'**
  String get statusRed;

  /// Headline when the measurement failed.
  ///
  /// In de, this message translates to:
  /// **'Messung nicht möglich'**
  String get statusError;

  /// Label of the green zone.
  ///
  /// In de, this message translates to:
  /// **'Grün – angenehm leise'**
  String get zoneGreen;

  /// Label of the yellow zone.
  ///
  /// In de, this message translates to:
  /// **'Gelb – etwas laut'**
  String get zoneYellow;

  /// Label of the red zone.
  ///
  /// In de, this message translates to:
  /// **'Rot – zu laut'**
  String get zoneRed;

  /// Countdown until the alarm fires.
  ///
  /// In de, this message translates to:
  /// **'Alarm in {seconds} s'**
  String alarmCountdown(int seconds);

  /// Screen-reader text of the countdown.
  ///
  /// In de, this message translates to:
  /// **'Alarm in {seconds} Sekunden'**
  String alarmCountdownSemantics(int seconds);

  /// Countdown reached zero; the alarm fires with the next loud reading.
  ///
  /// In de, this message translates to:
  /// **'Alarm gleich'**
  String get alarmImminent;

  /// Shown after the alarm of the current phase fired.
  ///
  /// In de, this message translates to:
  /// **'Alarm ausgelöst'**
  String get alarmFired;

  /// Shown while the own alarm sound plays (measurement suppressed).
  ///
  /// In de, this message translates to:
  /// **'Alarmton läuft – kurze Messpause'**
  String get alarmPlaying;

  /// Start button.
  ///
  /// In de, this message translates to:
  /// **'Messung starten'**
  String get measureStart;

  /// Stop button.
  ///
  /// In de, this message translates to:
  /// **'Messung stoppen'**
  String get measureStop;

  /// Button label while starting/stopping.
  ///
  /// In de, this message translates to:
  /// **'Bitte warten …'**
  String get measureBusy;

  /// Big level number of the gauge.
  ///
  /// In de, this message translates to:
  /// **'{value} dB'**
  String gaugeValue(int value);

  /// Gauge text without a value.
  ///
  /// In de, this message translates to:
  /// **'– dB'**
  String get gaugeNoValue;

  /// Caption marking the level as an estimate.
  ///
  /// In de, this message translates to:
  /// **'geschätzt'**
  String get gaugeEstimated;

  /// Screen-reader label of the gauge.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke, geschätzt'**
  String get gaugeSemanticsLabel;

  /// Screen-reader value of the gauge.
  ///
  /// In de, this message translates to:
  /// **'{value} Dezibel, {zone}'**
  String gaugeSemanticsValue(int value, String zone);

  /// Screen-reader value without measurement.
  ///
  /// In de, this message translates to:
  /// **'kein Messwert'**
  String get gaugeSemanticsNoValue;

  /// Title of the heartbeat timeline.
  ///
  /// In de, this message translates to:
  /// **'Verlauf der letzten 10 Minuten'**
  String get timelineTitle;

  /// Left x-axis label.
  ///
  /// In de, this message translates to:
  /// **'−10 min'**
  String get timelineMinus10;

  /// Middle x-axis label.
  ///
  /// In de, this message translates to:
  /// **'−5 min'**
  String get timelineMinus5;

  /// Right x-axis label.
  ///
  /// In de, this message translates to:
  /// **'jetzt'**
  String get timelineNow;

  /// Screen-reader summary of the timeline chart points (smoothed 10-second means, not the alarm zone).
  ///
  /// In de, this message translates to:
  /// **'Diagrammpunkte aus 10-Sekunden-Mittelwerten: höchster {max} dB, Durchschnitt {average} dB, {greenPercent} % der Punkte im grünen Bereich'**
  String timelineSummary(int max, int average, int greenPercent);

  /// Timeline summary without points.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Messwerte'**
  String get timelineEmpty;

  /// Non-fatal warning after alarm output fails.
  ///
  /// In de, this message translates to:
  /// **'Der Alarmton konnte nicht wiedergegeben werden. Die Messung läuft weiter.'**
  String get alarmOutputFailed;

  /// Warning while microphone readings arrive too sparsely to judge the room; no alarm can fire then.
  ///
  /// In de, this message translates to:
  /// **'Messung gestört – zu wenige Messwerte. Das Handy drosselt vielleicht das Mikrofon.'**
  String get signalThin;

  /// Kitty mood idle (screen reader).
  ///
  /// In de, this message translates to:
  /// **'Mia sitzt gemütlich da und wartet'**
  String get kittyIdle;

  /// Kitty mood happy (screen reader).
  ///
  /// In de, this message translates to:
  /// **'Mia ist fröhlich und schnurrt'**
  String get kittyHappy;

  /// Kitty mood uneasy (screen reader).
  ///
  /// In de, this message translates to:
  /// **'Mia ist unruhig, es wird ihr zu laut'**
  String get kittyUneasy;

  /// Kitty mood scared (screen reader).
  ///
  /// In de, this message translates to:
  /// **'Mia hat Angst – es ist viel zu laut'**
  String get kittyScared;

  /// Sign shown when the kitty walked away.
  ///
  /// In de, this message translates to:
  /// **'Zu laut – Mia hat sich versteckt'**
  String get kittyAwaySign;

  /// Appended to the kitty label (screen reader) when she wears shop items.
  ///
  /// In de, this message translates to:
  /// **'Mia trägt: {items}'**
  String kittyWearing(String items);

  /// Shop item name: bow.
  ///
  /// In de, this message translates to:
  /// **'Schleife'**
  String get accessoryBow;

  /// Shop item name: scarf.
  ///
  /// In de, this message translates to:
  /// **'Schal'**
  String get accessoryScarf;

  /// Shop item name: party hat.
  ///
  /// In de, this message translates to:
  /// **'Partyhut'**
  String get accessoryHat;

  /// Shop item name: cushion.
  ///
  /// In de, this message translates to:
  /// **'Kissen'**
  String get accessoryCushion;

  /// Shop item name: toy mouse.
  ///
  /// In de, this message translates to:
  /// **'Spielzeugmaus'**
  String get accessoryMouse;

  /// Number of stars earned for quiet minutes.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Sterne} =1{1 Stern} other{{count} Sterne}}'**
  String starsCount(int count);

  /// Explains the star counter.
  ///
  /// In de, this message translates to:
  /// **'Für jede ruhige Minute gibt es einen Stern'**
  String get starsHint;

  /// Progress towards the next star.
  ///
  /// In de, this message translates to:
  /// **'{percent} % bis zum nächsten Stern'**
  String starsProgress(int percent);

  /// Shown right after a star was earned.
  ///
  /// In de, this message translates to:
  /// **'Neuer Stern!'**
  String get starsJustEarned;

  /// Error title.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon nicht erlaubt'**
  String get errorPermissionDeniedTitle;

  /// Error body.
  ///
  /// In de, this message translates to:
  /// **'Raumfreund braucht das Mikrofon, um die Lautstärke zu schätzen. Es wird nichts aufgenommen oder gespeichert.'**
  String get errorPermissionDeniedBody;

  /// Error title.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon dauerhaft gesperrt'**
  String get errorPermanentlyDeniedTitle;

  /// Error body.
  ///
  /// In de, this message translates to:
  /// **'Der Mikrofonzugriff wurde dauerhaft abgelehnt. Erlaube ihn in den App-Einstellungen von Android unter „Berechtigungen“.'**
  String get errorPermanentlyDeniedBody;

  /// Error title.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon belegt'**
  String get errorMicrophoneBusyTitle;

  /// Error body.
  ///
  /// In de, this message translates to:
  /// **'Eine andere App benutzt gerade das Mikrofon, z. B. ein Anruf oder eine Sprachaufnahme. Beende sie und versuche es erneut.'**
  String get errorMicrophoneBusyBody;

  /// Error title.
  ///
  /// In de, this message translates to:
  /// **'Messung abgebrochen'**
  String get errorRecordingAbortedTitle;

  /// Error body.
  ///
  /// In de, this message translates to:
  /// **'Die Messung wurde unerwartet unterbrochen. Starte sie einfach noch einmal.'**
  String get errorRecordingAbortedBody;

  /// Error title.
  ///
  /// In de, this message translates to:
  /// **'Kein Mikrofon verfügbar'**
  String get errorUnavailableTitle;

  /// Error body.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät konnte kein nutzbares Mikrofon gefunden werden.'**
  String get errorUnavailableBody;

  /// Opens the Android app settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get errorOpenSettings;

  /// Retries the measurement.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get errorRetry;

  /// Settings page title.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Section heading.
  ///
  /// In de, this message translates to:
  /// **'Grenzwerte'**
  String get settingsThresholdsHeading;

  /// Yellow threshold label.
  ///
  /// In de, this message translates to:
  /// **'Gelb ab'**
  String get settingsYellowLabel;

  /// Red threshold label.
  ///
  /// In de, this message translates to:
  /// **'Rot ab'**
  String get settingsRedLabel;

  /// A threshold value.
  ///
  /// In de, this message translates to:
  /// **'{value} dB'**
  String settingsDbValue(int value);

  /// Tooltip of the minus button.
  ///
  /// In de, this message translates to:
  /// **'{name} um 1 dB verringern'**
  String settingsDecrease(String name);

  /// Tooltip of the plus button.
  ///
  /// In de, this message translates to:
  /// **'{name} um 1 dB erhöhen'**
  String settingsIncrease(String name);

  /// Explains the threshold coupling.
  ///
  /// In de, this message translates to:
  /// **'Gelb liegt immer unter Rot. Schiebst du eine Grenze über die andere, rückt die andere automatisch mit.'**
  String get settingsThresholdsHint;

  /// Section heading.
  ///
  /// In de, this message translates to:
  /// **'Kalibrierung'**
  String get settingsCalibrationHeading;

  /// Calibration slider label.
  ///
  /// In de, this message translates to:
  /// **'Korrektur'**
  String get settingsCalibrationLabel;

  /// Signed calibration value, e.g. +3 dB.
  ///
  /// In de, this message translates to:
  /// **'{value} dB'**
  String settingsCalibrationValue(String value);

  /// How to calibrate.
  ///
  /// In de, this message translates to:
  /// **'Handy-Mikrofone hören unterschiedlich gut. Lege ein Referenz-Schallpegelmessgerät direkt neben das Handy, sorge für ein gleichmäßiges Geräusch (z. B. Rauschen oder einen Lüfter) und verschiebe die Korrektur, bis Raumfreund denselben Wert zeigt wie das Messgerät. Die Anzeige bleibt trotzdem eine Schätzung.'**
  String get settingsCalibrationExplanation;

  /// Section heading.
  ///
  /// In de, this message translates to:
  /// **'Alarm'**
  String get settingsAlarmHeading;

  /// Label of the alarm delay control.
  ///
  /// In de, this message translates to:
  /// **'Alarm nach'**
  String get settingsAlarmDelayLabel;

  /// The configured alarm delay.
  ///
  /// In de, this message translates to:
  /// **'{value} Sekunden'**
  String settingsSecondsValue(int value);

  /// Tooltip of the alarm delay minus button.
  ///
  /// In de, this message translates to:
  /// **'Alarm-Wartezeit um 1 Sekunde verkürzen'**
  String get settingsAlarmDelayDecrease;

  /// Tooltip of the alarm delay plus button.
  ///
  /// In de, this message translates to:
  /// **'Alarm-Wartezeit um 1 Sekunde verlängern'**
  String get settingsAlarmDelayIncrease;

  /// Explains the alarm rule with the configured delay and its range.
  ///
  /// In de, this message translates to:
  /// **'So funktioniert der Alarm: Er ertönt erst, wenn es insgesamt {seconds} Sekunden gelb oder rot bleibt – kurze Pausen zählen mit – und nur einmal pro Phase. Wechselt die Ampel die Farbe, beginnt die Zeit neu; wird sie wieder grün, wird alles zurückgesetzt. Einstellbar sind {min} bis {max} Sekunden, Standard sind {standard} Sekunden.'**
  String settingsAlarmDelayRule(int seconds, int min, int max, int standard);

  /// Alarm sound switch.
  ///
  /// In de, this message translates to:
  /// **'Alarmton'**
  String get settingsAlarmSound;

  /// Alarm sound switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Ein kurzer, freundlicher Ton'**
  String get settingsAlarmSoundHint;

  /// Vibration switch.
  ///
  /// In de, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// Vibration switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Kurze Vibration, sofern vorhanden'**
  String get settingsVibrationHint;

  /// Save button.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get settingsSave;

  /// Retries a failed settings save.
  ///
  /// In de, this message translates to:
  /// **'Erneut speichern'**
  String get settingsRetrySave;

  /// Retryable error after settings persistence failed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen. Deine Änderungen sind noch da – versuche es bitte erneut.'**
  String get settingsSaveError;

  /// Cancel button (discards changes).
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get settingsCancel;

  /// Resets the draft to factory defaults.
  ///
  /// In de, this message translates to:
  /// **'Standardwerte'**
  String get settingsDefaults;

  /// Hint after resetting to defaults.
  ///
  /// In de, this message translates to:
  /// **'Standardwerte eingetragen – zum Übernehmen bitte speichern.'**
  String get settingsDefaultsApplied;

  /// About page title.
  ///
  /// In de, this message translates to:
  /// **'Über Raumfreund'**
  String get aboutTitle;

  /// Short description.
  ///
  /// In de, this message translates to:
  /// **'Die freundliche Lautstärkeampel für gemeinsame Räume.'**
  String get aboutTagline;

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'Build'**
  String get aboutBuild;

  /// Build number and git commit.
  ///
  /// In de, this message translates to:
  /// **'{buildNumber} (Commit {commit})'**
  String aboutBuildValue(int buildNumber, String commit);

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'Autor'**
  String get aboutAuthor;

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get aboutEmail;

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'Projekt'**
  String get aboutProject;

  /// Label.
  ///
  /// In de, this message translates to:
  /// **'Lizenz'**
  String get aboutLicense;

  /// License name.
  ///
  /// In de, this message translates to:
  /// **'GNU GPL v3.0 (GPL-3.0-only)'**
  String get aboutLicenseValue;

  /// Heading.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get aboutPrivacyHeading;

  /// Privacy statement.
  ///
  /// In de, this message translates to:
  /// **'Raumfreund arbeitet komplett offline. Es wird kein Ton aufgenommen, gespeichert oder versendet – das Mikrofonsignal wird nur kurz im Arbeitsspeicher zu einer Zahl verrechnet und sofort verworfen. Keine Konten, keine Werbung, kein Tracking.'**
  String get aboutPrivacyBody;

  /// Heading.
  ///
  /// In de, this message translates to:
  /// **'Hinweis zur Messung'**
  String get aboutMeasurementHeading;

  /// Measurement disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Die angezeigten Werte sind Schätzungen aus dem Handy-Mikrofon. Raumfreund ist kein geeichtes Schallpegelmessgerät und nicht für Arbeitsschutz oder Gutachten geeignet.'**
  String get aboutMeasurementBody;

  /// Opens the license page.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get aboutLicensesButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
