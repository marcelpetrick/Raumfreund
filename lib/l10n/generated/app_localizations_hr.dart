// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Raumfreund';

  @override
  String get actionSettings => 'Postavke';

  @override
  String get actionAbout => 'O aplikaciji Raumfreund';

  @override
  String get actionShop => 'Trgovina zvjezdica';

  @override
  String get actionBack => 'Natrag';

  @override
  String get statusIdle => 'Spremno – pokreni mjerenje';

  @override
  String get statusStarting => 'Mjerenje se pokreće …';

  @override
  String get statusStopping => 'Mjerenje se zaustavlja …';

  @override
  String get statusGreen => 'Sve je u redu, lijepo je tiho!';

  @override
  String get statusYellow => 'Malo tiše, molim';

  @override
  String get statusRed => 'Joj, ovo je preglasno!';

  @override
  String get statusSleeping => 'Mia spava – mjerenje je pauzirano';

  @override
  String get statusWaking => 'Mia se budi …';

  @override
  String get sleepingHint =>
      'Dok je aplikacija u pozadini, Raumfreund ne sluša. Čim ponovno otvoriš aplikaciju, Mia se probudi i nastavi mjeriti.';

  @override
  String get statusError => 'Mjerenje nije moguće';

  @override
  String get zoneGreen => 'Zeleno – ugodno tiho';

  @override
  String get zoneYellow => 'Žuto – malo glasno';

  @override
  String get zoneRed => 'Crveno – preglasno';

  @override
  String alarmCountdown(int seconds) {
    return 'Alarm za $seconds s';
  }

  @override
  String alarmCountdownSemantics(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Alarm za $seconds sekundi',
      few: 'Alarm za $seconds sekunde',
      one: 'Alarm za $seconds sekundu',
    );
    return '$_temp0';
  }

  @override
  String get alarmImminent => 'Alarm samo što nije';

  @override
  String get alarmFired => 'Alarm se oglasio';

  @override
  String get alarmPlaying => 'Alarm se oglašava – kratka stanka u mjerenju';

  @override
  String get measureStart => 'Pokreni mjerenje';

  @override
  String get measureStop => 'Zaustavi mjerenje';

  @override
  String get measureBusy => 'Pričekaj …';

  @override
  String gaugeValue(int value) {
    return '$value dB';
  }

  @override
  String get gaugeNoValue => '– dB';

  @override
  String get gaugeEstimated => 'procjena';

  @override
  String get gaugeSemanticsLabel => 'Glasnoća, procjena';

  @override
  String gaugeSemanticsValue(int value, String zone) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value decibela',
      few: '$value decibela',
      one: '$value decibel',
    );
    return '$_temp0, $zone';
  }

  @override
  String get gaugeSemanticsNoValue => 'nema izmjerene vrijednosti';

  @override
  String get timelineTitle => 'Zadnjih 10 minuta';

  @override
  String get timelineMinus10 => '−10 min';

  @override
  String get timelineMinus5 => '−5 min';

  @override
  String get timelineNow => 'sada';

  @override
  String timelineSummary(int max, int average, int greenPercent) {
    return 'Točke grafikona iz 10-sekundnih prosjeka: najviše $max dB, prosjek $average dB, $greenPercent % točaka u zelenom području';
  }

  @override
  String get timelineEmpty => 'Još nema izmjerenih vrijednosti';

  @override
  String get alarmOutputFailed =>
      'Zvuk alarma nije se mogao reproducirati. Mjerenje se nastavlja.';

  @override
  String get signalThin =>
      'Mjerenje je nepouzdano – premalo izmjerenih vrijednosti. Možda mobitel ograničava mikrofon.';

  @override
  String get kittyIdle => 'Mia udobno sjedi i čeka';

  @override
  String get kittyHappy => 'Mia je vesela i prede';

  @override
  String get kittyUneasy => 'Mia je nemirna, postaje joj preglasno';

  @override
  String get kittyScared => 'Mia se boji – previše je glasno';

  @override
  String get kittySleeping => 'Mia spava dok se ne vratiš';

  @override
  String get kittyAwaySign => 'Preglasno – Mia se sakrila';

  @override
  String kittyWearing(String items) {
    return 'Mia ima: $items';
  }

  @override
  String get accessoryBow => 'Mašnica';

  @override
  String get accessoryScarf => 'Šal';

  @override
  String get accessoryHat => 'Rođendanska kapica';

  @override
  String get accessoryCushion => 'Jastuk';

  @override
  String get accessoryMouse => 'Miš igračka';

  @override
  String starsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvjezdica',
      few: '$count zvjezdice',
      one: '$count zvjezdica',
      zero: 'Još nema zvjezdica',
    );
    return '$_temp0 u ovom mjerenju';
  }

  @override
  String starsWithTotal(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvjezdica',
      few: '$count zvjezdice',
      one: '$count zvjezdica',
      zero: 'Još nema zvjezdica',
    );
    return '$_temp0 u ovom mjerenju · $total u trgovini zvjezdica';
  }

  @override
  String starsInShop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvjezdica u trgovini zvjezdica',
      few: '$count zvjezdice u trgovini zvjezdica',
      one: '$count zvjezdica u trgovini zvjezdica',
      zero: 'U trgovini zvjezdica još nema zvjezdica',
    );
    return '$_temp0';
  }

  @override
  String get starsHint =>
      'Za svaku minutu zaredom u zelenom dobiva se zvjezdica';

  @override
  String get starsHintQuickTest =>
      'Testni način: zvjezdica za svakih 5 sekundi zaredom u zelenom';

  @override
  String starsProgress(int percent) {
    return 'Sljedeća zvjezdica: $percent % gotovo';
  }

  @override
  String get starsJustEarned => 'Nova zvjezdica!';

  @override
  String get errorPermissionDeniedTitle => 'Pristup mikrofonu nije dopušten';

  @override
  String get errorPermissionDeniedBody =>
      'Raumfreund treba mikrofon kako bi procijenio glasnoću. Zvuk se samo nakratko analizira – nikad se ne sprema niti šalje.';

  @override
  String get errorPermanentlyDeniedTitle => 'Mikrofon je trajno blokiran';

  @override
  String get errorPermanentlyDeniedBody =>
      'Pristup mikrofonu trajno je odbijen. Dopusti ga u Androidovim postavkama aplikacije pod „Dopuštenja”.';

  @override
  String get errorMicrophoneBusyTitle => 'Mikrofon je zauzet';

  @override
  String get errorMicrophoneBusyBody =>
      'Druga aplikacija upravo koristi mikrofon, npr. poziv ili snimanje glasa, ili je pristup mikrofonu isključen u Androidovim brzim postavkama. Zatvori tu aplikaciju ili uključi pristup pa pokušaj ponovno.';

  @override
  String get errorRecordingAbortedTitle => 'Mjerenje je prekinuto';

  @override
  String get errorRecordingAbortedBody =>
      'Mjerenje se neočekivano prekinulo. Jednostavno ga ponovno pokreni.';

  @override
  String get errorUnavailableTitle => 'Nema dostupnog mikrofona';

  @override
  String get errorUnavailableBody =>
      'Na ovom uređaju nije pronađen upotrebljiv mikrofon.';

  @override
  String get errorNoReadingsTitle => 'Nema izmjerenih vrijednosti';

  @override
  String get errorNoReadingsBody =>
      'Mikrofon trenutačno ne daje vrijednosti ili daje samo potpunu tišinu, pa je mjerenje zaustavljeno. Možda je pristup mikrofonu isključen u Androidovim brzim postavkama ili mikrofon ne reagira. Provjeri to i ponovno pokreni mjerenje.';

  @override
  String get errorOpenSettings => 'Otvori postavke';

  @override
  String get errorRetry => 'Pokušaj ponovno';

  @override
  String get settingsTitle => 'Postavke';

  @override
  String get settingsThresholdsHeading => 'Granice';

  @override
  String get settingsYellowLabel => 'Žuto od';

  @override
  String get settingsRedLabel => 'Crveno od';

  @override
  String settingsDbValue(int value) {
    return '$value dB';
  }

  @override
  String settingsDecrease(String name) {
    return '$name: 1 dB manje';
  }

  @override
  String settingsIncrease(String name) {
    return '$name: 1 dB više';
  }

  @override
  String get settingsThresholdsHint =>
      'Žuto je uvijek ispod crvenog. Ako jednu granicu pomakneš preko druge, druga se automatski pomakne s njom.';

  @override
  String get settingsCalibrationHeading => 'Kalibracija';

  @override
  String get settingsCalibrationLabel => 'Korekcija';

  @override
  String settingsCalibrationValue(String value) {
    return '$value dB';
  }

  @override
  String get settingsCalibrationExplanation =>
      'Mikrofoni mobitela nisu jednako osjetljivi. Stavi mjerač razine zvuka odmah uz mobitel (ako može, s vrednovanjem C ili Z umjesto A) i preko zvučnika pusti ravnomjeran šum. Pokreni mjerenje na glavnom zaslonu, očitaj obje vrijednosti i zatim ponovno otvori postavke. Od vrijednosti mjerača oduzmi vrijednost Raumfreunda i rezultat dodaj trenutačnoj korekciji ovdje – primjer: korekcija +5, mjerač 63 dB, Raumfreund 60 dB, dakle nova korekcija +8. Spremi i ponovno provjeri. Prikaz i dalje ostaje procjena.';

  @override
  String get settingsAlarmHeading => 'Alarm';

  @override
  String get settingsAlarmDelayLabel => 'Alarm nakon';

  @override
  String settingsSecondsValue(int value) {
    String _temp0 = intl.Intl.pluralLogic(
      value,
      locale: localeName,
      other: '$value sekundi',
      few: '$value sekunde',
      one: '$value sekunda',
    );
    return '$_temp0';
  }

  @override
  String get settingsAlarmDelayDecrease => 'Skrati čekanje alarma za 1 sekundu';

  @override
  String get settingsAlarmDelayIncrease =>
      'Produlji čekanje alarma za 1 sekundu';

  @override
  String settingsAlarmDelayRule(int seconds, int min, int max, int standard) {
    return 'Ovako radi alarm: ako semafor $seconds s ostane žut (ili $seconds s crven), oglasi se alarm. Kratki tiši trenuci ne prekidaju vrijeme. Ako semafor prijeđe između žutog i crvenog ili postane zelen, vrijeme kreće ispočetka – kao i nakon svakog alarma sa zvukom ili vibracijom: ako i dalje bude glasno, alarm se ponovno oglasi. Ako su zvuk i vibracija isključeni, Raumfreund alarm samo prikazuje, jednom po glasnoj fazi. Može se namjestiti od $min do $max s, zadano je $standard s.';
  }

  @override
  String get settingsAlarmSound => 'Zvuk alarma';

  @override
  String get settingsAlarmSoundHint => 'Kratak, ugodan ton';

  @override
  String get settingsVibration => 'Vibracija';

  @override
  String get settingsVibrationHint => 'Kratka vibracija, ako je uređaj ima';

  @override
  String get settingsStarTestHeading => 'Testiranje zvjezdica';

  @override
  String get settingsStarTestMode => 'Brzi testni način za zvjezdice';

  @override
  String get settingsStarTestModeHint =>
      'Zvjezdica se dobiva nakon 5 sekundi u zelenom području umjesto nakon 60 sekundi. I te zvjezdice idu u trgovinu zvjezdica. Zadano je isključeno; skupljene zvjezdice ostaju sačuvane.';

  @override
  String get settingsSave => 'Spremi';

  @override
  String get settingsRetrySave => 'Ponovno spremi';

  @override
  String get settingsSaveError =>
      'Spremanje nije uspjelo. Tvoje promjene su još tu – pokušaj ponovno.';

  @override
  String get settingsCancel => 'Odustani';

  @override
  String get settingsDefaults => 'Zadane vrijednosti';

  @override
  String get settingsDefaultsApplied =>
      'Zadane vrijednosti su unesene – spremi da se primijene.';

  @override
  String get aboutTitle => 'O aplikaciji Raumfreund';

  @override
  String get aboutTagline =>
      'Prijateljski semafor glasnoće za zajedničke prostorije.';

  @override
  String get aboutVersion => 'Verzija';

  @override
  String get aboutBuild => 'Build';

  @override
  String aboutBuildValue(int buildNumber, String commit) {
    return '$buildNumber (commit $commit)';
  }

  @override
  String get aboutAuthor => 'Autor';

  @override
  String get aboutEmail => 'E-pošta';

  @override
  String get aboutProject => 'Projekt';

  @override
  String get aboutLicense => 'Licenca';

  @override
  String get aboutLicenseValue => 'GNU GPL v3.0 (GPL-3.0-only)';

  @override
  String get aboutPrivacyHeading => 'Privatnost';

  @override
  String get aboutPrivacyBody =>
      'Raumfreund radi potpuno bez interneta. Signal mikrofona samo se nakratko u radnoj memoriji pretvori u broj glasnoće i odmah odbaci – nikakav zvuk se ne sprema niti šalje. Na uređaju ostaju samo postavke i zvjezdice. Bez korisničkih računa, bez oglasa, bez praćenja.';

  @override
  String get aboutMeasurementHeading => 'Napomena o mjerenju';

  @override
  String get aboutMeasurementBody =>
      'Prikazane vrijednosti su procjene na temelju mikrofona mobitela. Raumfreund nije ovjereni (baždareni) mjerač razine zvuka i nije prikladan za zaštitu na radu ni za vještačenja.';

  @override
  String get aboutLicensesButton => 'Licence otvorenog koda';

  @override
  String get shopTitle => 'Trgovina zvjezdica';

  @override
  String shopBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imaš $count zvjezdica',
      few: 'Imaš $count zvjezdice',
      one: 'Imaš $count zvjezdicu',
      zero: 'Još nemaš zvjezdica',
    );
    return '$_temp0';
  }

  @override
  String get shopLoading => 'Učitavanje zvjezdica …';

  @override
  String get shopLoadFailed =>
      'Zvjezdice se trenutačno ne mogu učitati. Kupnja i davanje dodataka Miji opet će raditi kad to uspije.';

  @override
  String get shopSaveFailed =>
      'Spremanje nije uspjelo. Tvoje zvjezdice ostaju sačuvane; pokušat će se ponovno pri sljedećem otvaranju aplikacije ili trgovine zvjezdica te pri sljedećoj promjeni.';

  @override
  String get shopDismiss => 'Sakrij';

  @override
  String get shopBuy => 'Kupi';

  @override
  String get shopEquip => 'Daj Miji';

  @override
  String get shopUnequip => 'Uzmi natrag';

  @override
  String shopMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Još $count zvjezdica',
      few: 'Još $count zvjezdice',
      one: 'Još $count zvjezdica',
    );
    return '$_temp0';
  }

  @override
  String get shopWorn => 'Kod Mije';

  @override
  String get shopOwned => 'Kupljeno';

  @override
  String shopPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zvjezdica',
      few: '$count zvjezdice',
      one: '$count zvjezdica',
    );
    return '$_temp0';
  }

  @override
  String shopConfirmTitle(String item, String price) {
    return 'Kupiti „$item” za $price?';
  }

  @override
  String get shopConfirmBuy => 'Kupi';

  @override
  String get shopConfirmCancel => 'Odustani';

  @override
  String get settingsResetHeading => 'Za učitelje i učiteljice';

  @override
  String get settingsResetBody =>
      'Briše sve zvjezdice i sve što je kupljeno u trgovini zvjezdica. To se događa odmah i nije dio radnji Spremi ili Odustani – ni Odustani to ne poništava.';

  @override
  String get settingsResetButton => 'Izbriši zvjezdice';

  @override
  String get settingsResetConfirmTitle =>
      'Izbrisati sve zvjezdice i kupljene stvari?';

  @override
  String get settingsResetConfirmBody => 'Ovo se ne može poništiti.';

  @override
  String get settingsResetConfirm => 'Izbriši';

  @override
  String get settingsResetDone =>
      'Sve zvjezdice i kupljene stvari su izbrisane.';

  @override
  String get settingsResetNotReady =>
      'Zvjezdice se još učitavaju. Pokušaj ponovno za trenutak.';

  @override
  String get settingsResetSaveFailed =>
      'Zvjezdice su izbrisane, ali spremanje nije uspjelo. Pokušat će se ponovno kasnije – do tada se stare zvjezdice nakon ponovnog pokretanja aplikacije mogu vratiti.';

  @override
  String get settingsLanguageHeading => 'Jezik';

  @override
  String get settingsLanguageHint =>
      'Jezik se mijenja odmah i odmah se sprema, neovisno o tipkama Spremi i Odustani.';

  @override
  String get settingsLanguageSaveFailed =>
      'Jezik je promijenjen, ali nije spremljen. Pri sljedećem pokretanju aplikacije koristit će se prethodni jezik.';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCroatian => 'Hrvatski';

  @override
  String get languageChinese => '中文（简体）';
}
