// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Raumfreund';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionAbout => 'About Raumfreund';

  @override
  String get actionShop => 'Star shop';

  @override
  String get actionBack => 'Back';

  @override
  String get statusIdle => 'Ready – start measuring';

  @override
  String get statusStarting => 'Starting measurement …';

  @override
  String get statusStopping => 'Stopping measurement …';

  @override
  String get statusGreen => 'All nice and quiet!';

  @override
  String get statusYellow => 'A little quieter, please';

  @override
  String get statusRed => 'Oh dear, that\'s too loud!';

  @override
  String get statusSleeping => 'Mia is asleep – measurement paused';

  @override
  String get statusWaking => 'Mia is waking up …';

  @override
  String get sleepingHint =>
      'While the app is in the background, Raumfreund does not listen. As soon as you open the app again, Mia wakes up and keeps measuring.';

  @override
  String get statusError => 'Measurement not possible';

  @override
  String get zoneGreen => 'Green – nice and quiet';

  @override
  String get zoneYellow => 'Yellow – a bit loud';

  @override
  String get zoneRed => 'Red – too loud';

  @override
  String alarmCountdown(int seconds) {
    return 'Alarm in $seconds s';
  }

  @override
  String alarmCountdownSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Alarm in $seconds seconds',
      one: 'Alarm in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get alarmImminent => 'Alarm any moment';

  @override
  String get alarmFired => 'Alarm triggered';

  @override
  String get alarmPlaying => 'Alarm on – short measuring pause';

  @override
  String get measureStart => 'Start measuring';

  @override
  String get measureStop => 'Stop measuring';

  @override
  String get measureBusy => 'Please wait …';

  @override
  String gaugeValue(int value) {
    return '$value dB';
  }

  @override
  String get gaugeNoValue => '– dB';

  @override
  String get gaugeEstimated => 'estimated';

  @override
  String get gaugeSemanticsLabel => 'Loudness, estimated';

  @override
  String gaugeSemanticsValue(int value, String zone) {
    return '$value decibels, $zone';
  }

  @override
  String get gaugeSemanticsNoValue => 'no reading';

  @override
  String get timelineTitle => 'Last 10 minutes';

  @override
  String get timelineMinus10 => '−10 min';

  @override
  String get timelineMinus5 => '−5 min';

  @override
  String get timelineNow => 'now';

  @override
  String timelineSummary(int max, int average, int greenPercent) {
    return 'Chart points from 10-second averages: highest $max dB, average $average dB, $greenPercent % of the points in the green zone';
  }

  @override
  String get timelineEmpty => 'No readings yet';

  @override
  String get alarmOutputFailed =>
      'The alarm sound could not be played. Measuring continues.';

  @override
  String get signalThin =>
      'Measurement unreliable – too few readings. The phone may be throttling the microphone.';

  @override
  String get kittyIdle => 'Mia is sitting comfortably and waiting';

  @override
  String get kittyHappy => 'Mia is happy and purring';

  @override
  String get kittyUneasy => 'Mia is restless – it\'s getting too loud for her';

  @override
  String get kittyScared => 'Mia is scared – it is far too loud';

  @override
  String get kittySleeping => 'Mia is sleeping until you come back';

  @override
  String get kittyAwaySign => 'Too loud – Mia is hiding';

  @override
  String kittyWearing(String items) {
    return 'Mia has: $items';
  }

  @override
  String get accessoryBow => 'Bow';

  @override
  String get accessoryScarf => 'Scarf';

  @override
  String get accessoryHat => 'Party hat';

  @override
  String get accessoryCushion => 'Cushion';

  @override
  String get accessoryMouse => 'Toy mouse';

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
      zero: 'No stars yet',
    );
    return '$_temp0';
  }

  @override
  String starsWithTotal(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new stars',
      one: '1 new star',
      zero: 'No new stars yet',
    );
    return '$_temp0 · $total in the star shop';
  }

  @override
  String get starsHint => 'Every full minute in the green earns a star';

  @override
  String get starsHintQuickTest =>
      'Star test mode: one star every 5 seconds in the green';

  @override
  String starsProgress(int percent) {
    return 'Next star: $percent % done';
  }

  @override
  String get starsJustEarned => 'New star!';

  @override
  String get errorPermissionDeniedTitle => 'Microphone not allowed';

  @override
  String get errorPermissionDeniedBody =>
      'Raumfreund needs the microphone to estimate the loudness. The sound is only analysed for a moment – never saved or sent.';

  @override
  String get errorPermanentlyDeniedTitle => 'Microphone permanently blocked';

  @override
  String get errorPermanentlyDeniedBody =>
      'Microphone access was permanently denied. Allow it in Android\'s app settings under “Permissions”.';

  @override
  String get errorMicrophoneBusyTitle => 'Microphone in use';

  @override
  String get errorMicrophoneBusyBody =>
      'Another app is using the microphone right now, for example a call or a voice recording, or microphone access is turned off in Android\'s quick settings. Close that app or turn access on, then try again.';

  @override
  String get errorRecordingAbortedTitle => 'Measurement interrupted';

  @override
  String get errorRecordingAbortedBody =>
      'The measurement stopped unexpectedly. Just start it again.';

  @override
  String get errorUnavailableTitle => 'No microphone available';

  @override
  String get errorUnavailableBody =>
      'No usable microphone was found on this device.';

  @override
  String get errorNoReadingsTitle => 'No readings';

  @override
  String get errorNoReadingsBody =>
      'The microphone is delivering no values or only complete silence, so the measurement was stopped. Maybe microphone access is turned off in Android\'s quick settings or the microphone is not responding. Check this and start the measurement again.';

  @override
  String get errorOpenSettings => 'Open settings';

  @override
  String get errorRetry => 'Try again';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThresholdsHeading => 'Limits';

  @override
  String get settingsYellowLabel => 'Yellow from';

  @override
  String get settingsRedLabel => 'Red from';

  @override
  String settingsDbValue(int value) {
    return '$value dB';
  }

  @override
  String settingsDecrease(String name) {
    return '$name: 1 dB lower';
  }

  @override
  String settingsIncrease(String name) {
    return '$name: 1 dB higher';
  }

  @override
  String get settingsThresholdsHint =>
      'Yellow always stays below red. If you move one limit past the other, the other one moves along automatically.';

  @override
  String get settingsCalibrationHeading => 'Calibration';

  @override
  String get settingsCalibrationLabel => 'Correction';

  @override
  String settingsCalibrationValue(String value) {
    return '$value dB';
  }

  @override
  String get settingsCalibrationExplanation =>
      'Phone microphones differ in sensitivity. Put a sound level meter right next to the phone and make a steady sound (for example white noise or a fan). Compare Raumfreund with the meter, enter the difference here as the correction, save and check again. The display is still an estimate.';

  @override
  String get settingsAlarmHeading => 'Alarm';

  @override
  String get settingsAlarmDelayLabel => 'Alarm after';

  @override
  String settingsSecondsValue(int value) {
    return '$value seconds';
  }

  @override
  String get settingsAlarmDelayDecrease =>
      'Shorten the alarm delay by 1 second';

  @override
  String get settingsAlarmDelayIncrease =>
      'Lengthen the alarm delay by 1 second';

  @override
  String settingsAlarmDelayRule(int seconds, int min, int max, int standard) {
    return 'How the alarm works: when the light stays yellow for $seconds seconds (or red for $seconds seconds), the alarm goes off. Short quieter moments do not stop the clock. If the light switches between yellow and red or turns green, the time starts over – and also after every alarm: if it stays loud, the alarm comes again. You can choose $min to $max seconds; the default is $standard seconds.';
  }

  @override
  String get settingsAlarmSound => 'Alarm sound';

  @override
  String get settingsAlarmSoundHint => 'A short, friendly tone';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationHint =>
      'A short vibration, if the device has one';

  @override
  String get settingsStarTestHeading => 'Star test';

  @override
  String get settingsStarTestMode => 'Quick star test mode';

  @override
  String get settingsStarTestModeHint =>
      'A star comes after 5 seconds in the green zone instead of after 60 seconds. These stars go to the star shop too. Off by default; collected stars are kept.';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsRetrySave => 'Save again';

  @override
  String get settingsSaveError =>
      'Saving failed. Your changes are still here – please try again.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDefaults => 'Restore defaults';

  @override
  String get settingsDefaultsApplied =>
      'Defaults filled in – save to apply them.';

  @override
  String get aboutTitle => 'About Raumfreund';

  @override
  String get aboutTagline =>
      'The friendly noise traffic light for shared rooms.';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuild => 'Build';

  @override
  String aboutBuildValue(int buildNumber, String commit) {
    return '$buildNumber (commit $commit)';
  }

  @override
  String get aboutAuthor => 'Author';

  @override
  String get aboutEmail => 'Email';

  @override
  String get aboutProject => 'Project';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutLicenseValue => 'GNU GPL v3.0 (GPL-3.0-only)';

  @override
  String get aboutPrivacyHeading => 'Privacy';

  @override
  String get aboutPrivacyBody =>
      'Raumfreund works completely offline. The microphone signal is turned into a loudness number in memory for a moment and discarded right away – no sound is saved or sent. Only settings and stars are kept on the device. No accounts, no ads, no tracking.';

  @override
  String get aboutMeasurementHeading => 'About the measurement';

  @override
  String get aboutMeasurementBody =>
      'The values shown are estimates from the phone microphone. Raumfreund is not a calibrated sound level meter and is not suitable for occupational safety or expert reports.';

  @override
  String get aboutLicensesButton => 'Open-source licenses';

  @override
  String get shopTitle => 'Star shop';

  @override
  String shopBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count stars',
      one: 'You have 1 star',
      zero: 'You don\'t have any stars yet',
    );
    return '$_temp0';
  }

  @override
  String get shopLoading => 'Loading stars …';

  @override
  String get shopLoadFailed =>
      'Your stars can\'t be loaded right now. Buying and giving things to Mia will work again once they can.';

  @override
  String get shopSaveFailed =>
      'Saving didn\'t work. Your stars are safe; the app will try again the next time you open it or the star shop, or when something changes.';

  @override
  String get shopDismiss => 'Dismiss';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopEquip => 'Give to Mia';

  @override
  String get shopUnequip => 'Take back';

  @override
  String shopMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stars',
      one: '1 more star',
    );
    return '$_temp0';
  }

  @override
  String get shopWorn => 'With Mia';

  @override
  String get shopOwned => 'Owned';

  @override
  String shopPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String shopConfirmTitle(String item, String price) {
    return 'Buy “$item” for $price?';
  }

  @override
  String get shopConfirmBuy => 'Buy';

  @override
  String get shopConfirmCancel => 'Cancel';

  @override
  String get settingsResetHeading => 'For teachers';

  @override
  String get settingsResetBody =>
      'Deletes all stars and everything bought in the star shop. This happens immediately and is not part of Save or Cancel – Cancel does not undo it either.';

  @override
  String get settingsResetButton => 'Reset stars';

  @override
  String get settingsResetConfirmTitle => 'Delete all stars and bought items?';

  @override
  String get settingsResetConfirmBody => 'This cannot be undone.';

  @override
  String get settingsResetConfirm => 'Delete';

  @override
  String get settingsResetDone =>
      'All stars and bought items have been deleted.';

  @override
  String get settingsResetNotReady =>
      'The stars are still loading. Please try again in a moment.';

  @override
  String get settingsResetSaveFailed =>
      'The stars were reset, but saving didn\'t work. The app will try again later – until then, the old stars may come back if the app is restarted.';

  @override
  String get settingsLanguageHeading => 'Language';

  @override
  String get settingsLanguageHint =>
      'The language changes immediately and is saved right away, independent of Save and Cancel.';

  @override
  String get settingsLanguageSaveFailed =>
      'The language was changed but could not be saved. The next time the app starts, the previous language is used.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageChinese => '中文（简体）';
}
