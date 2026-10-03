# Raumfreund – Vision und verbindlicher Umsetzungsauftrag

Stand: 3. Oktober 2026. Dieses Dokument kann vollständig als Auftrag in eine neue ChatGPT-/Codex-Sitzung kopiert werden.

## 1. Auftrag an den ausführenden Agenten

Entwickle eine vollständige, wartbare Android-App namens **Raumfreund** mit Flutter und Dart. Liefere ein reguläres GitHub-fähiges Repository, alle Android-Projektdateien, Tests, Dokumentation, CI/CD und einen nachvollziehbaren Release-Prozess. Arbeite bis zu einem überprüfbaren Ergebnis; ein Quellcodegerüst oder ein Skript, das erst das eigentliche Android-Projekt erzeugt, reicht nicht als Fertigstellung.

Erstelle vor der Implementierung eine `AGENTS.md` im Repository-Stamm mit den Regeln aus Abschnitt 8. Teile anschließend geeignete Aufgaben an Sub-Agenten auf, sofern die Umgebung das unterstützt. Koordiniere deren Arbeit, prüfe die Ergebnisse und integriere sie. Falls Sub-Agenten nicht verfügbar sind, arbeite die Aufgaben selbst ab und benenne diese Einschränkung. Behaupte keine ausgeführten Tests, erzeugten Releases oder Plattformkompatibilität ohne Belege.

Ein vorhandenes `raumfreund-source.zip` ist ein unvalidierter Prototyp und darf nach Prüfung als Ausgangspunkt dienen. Falls es nicht beigefügt ist, ist dieser Auftrag auch ohne das ZIP vollständig. Übernehme keinen Prototypcode ungeprüft. Korrigiere insbesondere Lifecycle-, Berechtigungs-, Nebenläufigkeits- und Alarmprobleme.

## 2. Vision und Umfang

Raumfreund hilft Kindern und Erwachsenen, in gemeinsam genutzten Räumen eine angenehme Lautstärke einzuhalten. Die App reagiert freundlich und verständlich: ein glückliches Gesicht bei Grün, ein trauriges bei Gelb und ein sehr trauriges, weinendes Gesicht bei Rot.

Die Bedienung ist einfach: App öffnen, Messung starten, Lautstärkeampel beobachten, Messung stoppen. Einstellungen und About sind jederzeit erreichbar. Die App arbeitet offline, ohne Konto, Werbung, Tracking oder Audioarchiv.

Version 1 ist eine Android-App für Handy und Tablet. iOS, Desktop und Web gehören nicht zum Lieferumfang. Eine vollständige Android-Kompatibilität gilt ausschließlich für die dokumentierte und geprüfte Betriebssystem-/Gerätematrix.

## 3. Funktionsanforderungen

### Messung und Anzeige

- Nutze das Handy-Mikrofon mit einer zuverlässig getesteten Android-Implementierung.
- Zeige geschätzten Schallpegel, Einheit, Messstatus und eine Skala von 0 bis 130 dB.
- Standard: Grün unter 60 dB, Gelb ab 60 bis unter 80 dB, Rot ab 80 dB.
- Zeige Status zusätzlich durch Gesicht und Text; Farbe allein darf keine Information tragen.
- Die Anzeige darf leicht geglättet sein. Verwende für die Alarmentscheidung einen separat definierten und dokumentierten Messwert; UI-Animationen dürfen die Timerlogik nicht beeinflussen.
- Unterstütze Start/Stopp, verhindere parallele Messinstanzen und schnelle Mehrfachstarts.
- Halte den Bildschirm nur während einer aktiven Messung eingeschaltet.
- Stoppe die Messung beim Wechsel in den Hintergrund und beim Öffnen von Einstellungen oder About. Kehre ohne automatischen Neustart zurück.
- Behandle Berechtigungsdialoge getrennt von einem echten Hintergrundwechsel. Eine Anfrage darf sich durch den eigenen Lifecycle-Handler nicht selbst abbrechen. Nach Freigabe nur im Vordergrund starten.
- Zeige verständliche Fehler für verweigerte Berechtigung, dauerhaft verweigerten Zugriff, belegtes Mikrofon und abgebrochene Aufnahme. Biete einen passenden Weg zu den Android-App-Einstellungen, wenn erforderlich.

### Grenzen und Einstellungen

- Gelb- und Rotgrenzen in ganzen dB innerhalb 0–130 einstellbar; immer `0 <= gelb < rot <= 130`.
- Verhindere ungültige Werte in UI, Domänenlogik und persistenten Daten.
- Speichere Grenzen, Kalibrierung und Alarmoptionen lokal und dauerhaft; validiere beim Laden und migriere zukünftige Datenversionen.
- Speichern und Abbrechen haben klare, unterschiedliche Wirkung. Standardwerte können wiederhergestellt werden.
- Erlaube einen verständlich beschriebenen Kalibrierungsoffset.
- Alarmton ist abschaltbar; kurze Vibration sofern vorhanden. Keine Voraussetzung, dass jedes Gerät vibrieren kann.

### Verbindliche Alarmregeln

| Zustand/Ereignis | Verhalten |
| --- | --- |
| Grün | Kein Alarm; Zeit und Auslösestatus zurücksetzen |
| Eintritt in Gelb | Neue gelbe Phase, Timer startet bei null |
| Eintritt in Rot | Neue rote Phase, Timer startet bei null |
| Gelb oder Rot für mindestens 10 Sekunden durchgehend | Ein Alarm für diese Phase |
| Weiterhin gleiche Phase nach Alarm | Kein wiederholter Daueralarm |
| Wechsel Gelb ↔ Rot | Neuer Timer und neuer Auslösestatus |
| Stopp, Hintergrund, Fehler oder Messlücke über 1 Sekunde | Kontinuität aufheben; keine Zeit ohne Samples mitzählen |
| Änderung der Grenzwerte | Messung bleibt gestoppt; nächster Start beginnt eine neue Phase |

Nutze monotone Zeit und injizierbare Zeitquellen für Tests. Definiere den Startzeitpunkt als Zeitpunkt des ersten gültigen Samples einer Phase. Messintervalle und Zeitauflösung dokumentieren. Der Alarm darf nicht vor zehn Sekunden auslösen; danach spätestens mit dem nächsten gültigen Sample. Ein Sample exakt auf einer Grenze gehört zur höheren Stufe.

Der eigene Alarmton kann das Mikrofon beeinflussen. Definiere und teste eine Behandlung: während des Tons keine weiteren Alarme auslösen, anschließend den Timer zurücksetzen und eine neue Phase erst mit gültigen Samples nach Tonende beginnen. Dokumentiere die kurze Messunterbrechung und halte UI und Domänenzustand konsistent.

### About und Lizenzen

- About mit Appname, Version, Buildinformation, Autorenangabe und Projektadresse, sobald bekannt.
- Fehlenden persönlichen Autorennamen als Platzhalter kennzeichnen; keinen Namen erfinden. Platzhalter vor dem öffentlichen Release auflösen.
- App-Quellcode unter `GPL-3.0-only`; vollständige GPL-v3-Lizenzdatei und konsistente SPDX-Hinweise.
- Bibliotheken, verwendete Versionen und Lizenztexte aufführen; Flutter-Lizenzdialog sowie native/transitive Komponenten berücksichtigen.
- Vor Veröffentlichung Abhängigkeiten auf GPL-Kompatibilität prüfen und Quellcode passend zum Binärrelease zugänglich machen.

## 4. Messqualität und Datenschutz

Ein Mikrofon liefert zunächst digitale Pegel, z. B. dBFS. Ein konstanter Offset macht daraus keine geräteunabhängig genaue dB-SPL-Messung. Dokumentiere Berechnung, RMS-Zeitfenster, Glättung, Kalibrierung und Geräteeinflüsse wie automatische Verstärkung. Kennzeichne die Anzeige als geschätzt. Behaupte keine dB(A)-Messung ohne tatsächlich implementierte, geprüfte Gewichtung.

Kalibrierung mit einem Referenzmessgerät bei gleichmäßigem Geräusch erklären. Keine Eignung als professionelles Arbeitsschutz- oder geeichtes Schallpegelmessgerät behaupten. Für die Raumampel ist eine konsistente, verständliche Reaktion wichtiger als vorgetäuschte Präzision.

Audiosamples ausschließlich kurzfristig im RAM verarbeiten und unmittelbar verwerfen. Keine Audiodateien, keine Uploads, keine versteckten Analytics. Nur notwendige Berechtigungen deklarieren; insbesondere keine Internetberechtigung im Release, sofern technisch nicht benötigt. Logs enthalten keine Audioinhalte und keine personenbezogenen Daten.

## 5. Aktuelle und reproduzierbare Toolchain

1. Ermittle zu Implementierungsbeginn die **neueste stabile Flutter-Version** aus offiziellen Quellen und nutze die dazugehörige, mitgelieferte Dart-Version. Flutter und Dart nicht unabhängig auf inkompatible Versionen aktualisieren. Keine Beta-/Dev-Versionen.
2. Dokumentiere Versionsnummern, Prüfdatum und Quellen in `docs/toolchain.md`. Veraltete Versionsnummern aus diesem Auftrag sind keine Vorgabe.
3. Pinne exakt diese Flutter-Version für lokale Entwicklung und CI, z. B. über eine passende SDK-Versionsdatei. Committe `pubspec.lock` für die App und den Gradle Wrapper.
4. Verwende aktuelle stabile Abhängigkeiten, sofern sie mit der gewählten Flutter-/Android-Toolchain kompatibel sind. Für JDK, Kotlin, AGP und Gradle zählt die offiziell unterstützte Kombination; begründe Abweichungen von einem einzelnen neuesten Release.
5. Ermittle `minSdk`, `compileSdk`, `targetSdk` und unterstützte ABIs anhand aktueller Flutter-/Android-Vorgaben und der Zielgeräte. Dokumentiere die exakten Werte. Prüfe aktuelle Play-Anforderungen, falls Play-Veröffentlichung vorgesehen ist.
6. Prüfe wöchentlich SDK- und Dependency-Updates; übernehme sie per Pull Request nach erfolgreicher CI. Release-Builds verwenden gepinnte Versionen, kein unkontrolliertes `latest`.

## 6. Architektur und Wartbarkeit

Verwende eine kleine, klar gegliederte Architektur: Darstellung, Anwendungssteuerung, reine Domänenlogik und Infrastruktur. Die Zustandsmaschine für Zonen und Alarm ist unabhängig von Flutter-Widgets, Mikrofon und echter Uhr testbar.

Definiere schmale Schnittstellen für Mikrofonstream, Einstellungen, Uhr und Alarm. Nutze explizite Zustände wie gestoppt, Berechtigung ausstehend, startet, misst, stoppt und Fehler. Cleanup ist idempotent; keine verwaisten Streams, Threads, Timer oder Recorder. Veraltete Events vorheriger Messsitzungen werden über eine Sitzungskennung verworfen.

Entscheide anhand Wartungszustand, Lizenz und Tests zwischen gepflegtem Mikrofonpaket und eigenem nativen Modul. Halte die Abhängigkeiten klein und dokumentiere die Entscheidung in einem ADR. Falls Kotlin nötig ist: getrennte Klassen für Aufnahme, Berechtigung und Alarm, statt einer übergroßen Activity.

- Maximal **100 physische Zeilen pro handgeschriebener Funktion/Methode**, einschließlich Signatur, Leerzeilen und Kommentaren bis zur schließenden Klammer. Gilt auch für Widget-`build`, lokale Funktionen und längere Closures.
- Zielwert eher 20–40 Zeilen; klare Namen und eine Verantwortung je Funktion.
- Generierter Code, vendorte Quellen und Lizenztexte sind ausgenommen; keine pauschalen Ausnahmen für eigenen UI-Code.
- Erzwinge die 100-Zeilen-Grenze in CI mit einem parserbasierten Check für die tatsächlich verwendeten Sprachen. Teste den Checker mit 99/100/101 Zeilen sowie verschachtelten Funktionen. Keine fragile Regex als alleinige Prüfung.
- Vermeide globale veränderliche Zustände, versteckte Seiteneffekte, leere Catch-Blöcke und pauschale Lint-Unterdrückung.
- Öffentliche APIs und nicht offensichtliche fachliche Entscheidungen dokumentieren. Kommentare erklären Gründe.
- Layout funktioniert auf kleinen Handys, Tablets, im Querformat und bei großer Textskalierung; keine abgeschnittenen Bedienelemente.
- Material 3, zugängliche Kontraste, TalkBack-Semantik, große Touchziele und reduzierte Animationen berücksichtigen. Deutsche Oberfläche; Texte zentral und für spätere Lokalisierung vorbereitet.

## 7. Erwartete Repository-Struktur

Passe Details begründet an, behalte aber die Trennung der Verantwortlichkeiten.

```text
AGENTS.md
README.md
LICENSE
CHANGELOG.md
CONTRIBUTING.md
SECURITY.md
pubspec.yaml / pubspec.lock / analysis_options.yaml
lib/app/
lib/features/monitor/{presentation,application,domain,infrastructure}/
lib/features/settings/
lib/features/about/
lib/l10n/
android/                     vollständiges Android-Hostprojekt
assets/licenses/
test/                        Unit-, Widget-, Golden-Tests
integration_test/
tool/                        Qualitätschecks und lokale Build-Helfer
.github/workflows/           CI, Integrationstests, Release, Wartung
.github/                     PR-/Issue-Vorlagen und Updatekonfiguration
docs/{architecture,toolchain,measurement,privacy,testing,releasing}.md
docs/adr/
```

Das Repository muss nach frischem Checkout mit dokumentierter Toolchain direkt analysierbar und baubar sein. Ein Setup-Helfer darf Voraussetzungen prüfen und Befehle bündeln, aber nicht bei jedem Build Hostprojekt oder Versionsdateien neu generieren oder eigenen Code überschreiben.

## 8. Inhalt der zuerst anzulegenden AGENTS.md

Übernimm diese verbindlichen Arbeitsregeln in die tatsächliche `AGENTS.md`:

- Lies Vision, README und bestehende Architekturentscheidungen vor Änderungen.
- Arbeite innerhalb des beschriebenen Android-Umfangs; dokumentiere notwendige Annahmen.
- Erstelle einen Arbeitsplan und verteile unabhängige Pakete an Sub-Agenten, sofern verfügbar.
- Koordinator besitzt Integration, gemeinsame Konfiguration, Architektur und endgültige Abnahme. Weise jedem Sub-Agenten eindeutige Dateibereiche oder getrennte Branches/Worktrees zu.
- Sub-Agenten liefern Änderungen, Tests, ausgeführte Befehle, Ergebnisse, Risiken und offene Punkte. Ein weiterer Agent prüft kritische Logik unabhängig.
- Prüfe aktuelle stabile Versionen offiziell; pinne die Toolchain und halte Lockfiles konsistent.
- Halte jede eigene Funktion/Methode innerhalb von 100 Zeilen; keine Umgehung durch Minifizierung oder künstliches Zusammenziehen.
- Bewahre Domänenlogik unabhängig von UI und nativen APIs; teste fachliche Grenzfälle.
- Kein Audio speichern oder übertragen; keine Secrets oder Signierschlüssel committen.
- Für jeden PR relevante Formatierung, Analyse, Tests und Builds ausführen. Fehler beheben; übersprungene Checks ausdrücklich benennen.
- Ein Testskript im Repository ist kein Nachweis eines erfolgreichen Testlaufs.
- Keine pauschalen `ignore`-Direktiven, deaktivierten Checks oder Coverage-Ausnahmen zur künstlichen Verbesserung.
- Dokumentation, Lizenzhinweise und Changelog zusammen mit Verhalten ändern.
- Nicht ausgeführte Plattform-/Gerätetests als offen kennzeichnen.
- Öffentliche Releases nur aus geprüftem Commit mit passenden Tags, Artefakten und Release-Notizen. Fehlende Zugänge oder Signiergeheimnisse benennen; nicht simulieren.

## 9. Sub-Agent-Aufteilung für schnelle Umsetzung

| Rolle | Paket | Ergebnis |
| --- | --- | --- |
| Koordinator | Erst AGENTS.md, Toolchain, Schnittstellen, Integration | Konsistente Architektur, integrierter Build, Abnahme |
| Agent A | Domäne und Alarmzustandsmaschine | Reine Logik mit Fake-Uhr, vollständige Grenzfalltests |
| Agent B | Flutter-UI, Einstellungen und About | Kleine Widgets, zugängliche Oberfläche, Widget-/Layouttests |
| Agent C | Android-Mikrofon, Berechtigung, Lifecycle, Alarm | Robuste Infrastruktur, native Tests und Gerätestestplan |
| Agent D | CI/CD, Qualitätschecks, Dokumentation und Releases | Gepinnte Workflows, Releaseplan, Buildanleitung |
| Reviewer | Unabhängige Prüfung nach Integration | Befunde zu Rennen, Timerlogik, Datenschutz, Wartbarkeit |

Zuerst gemeinsame Schnittstellen festlegen, danach parallel arbeiten. Keine gleichzeitigen konkurrierenden Änderungen an denselben Dateien. Der Koordinator integriert früh einen vertikalen Pfad von Mikrofon bis UI, statt erst am Ende alle Komponenten zusammenzusetzen.

## 10. Linter und Qualitätsprüfungen

Verwende passende, gepflegte Prüfungen und aktiviere sie verbindlich. Nicht alle existierenden Lintregeln blind einschalten: widersprüchliche Regeln vermeiden und das gewählte Profil dokumentieren.

| Bereich | Verbindliche Prüfung |
| --- | --- |
| Dart/Flutter | Formatter, `flutter analyze --fatal-infos --fatal-warnings`, aktuelles `flutter_lints` plus sinnvolle strengere Regeln |
| Typisierung | Strikte Analyzer-Einstellungen für Casts, Inferenz und Raw Types, sofern von der gewählten SDK-Version unterstützt |
| Kotlin, falls vorhanden | ktlint, detekt und Android Lint mit geprüft kompatiblen Versionen |
| Shell | ShellCheck und shfmt für enthaltene Skripte |
| Python, falls vorhanden | Ruff Format/Lint und passende Typprüfung für Tooling |
| Markdown/YAML | markdownlint und YAML-/Workflow-Prüfung |
| GitHub Actions | actionlint, minimale Permissions, Prüfung exakter Action-SHA-Pins |
| Wartbarkeit | Automatischer 100-Zeilen-Check für Funktionen und Methoden |
| Sicherheit/Lizenzen | Secret-Scan, Dependency-/Schwachstellenprüfung und Lizenzinventar einschließlich nativer Komponenten |

Sicherheitsprüfungen auf vorhandene Sprachunterstützung abstimmen. Ein Tool ohne Dart-Unterstützung ist kein Ersatz für Dart-Analyse. Ausnahmen müssen konkret begründet, eng begrenzt und überprüfbar sein.

## 11. Teststrategie und Abnahmefälle

Unit-Tests: exakte Grenzen, 9,9/10/10,1 Sekunden, gelb/rot-Wechsel, Grün-Rückkehr, erneutes Starten, Messlücken, geänderte Grenzen, Kalibrierung, ungültige persistierte Werte, nur ein Alarm pro Phase und Unterbrechung durch eigenen Alarm.

Widget-Tests: alle Gesichter und Texte, Start-/Stopp-Zustände, Countdown, Fehleransichten, Speichern/Abbrechen, valide Slidergrenzen, About/Lizenzen und TalkBack-Semantik.

Layout-/Golden-Tests: kleines Handy, Tablet, Querformat und große Schrift. Goldens kontrolliert und nachvollziehbar aktualisieren.

Integration/native Tests: Mikrofonfreigabe und Ablehnung, dauerhaft verweigerter Zugriff, Dialog-Lifecycle, Hintergrundwechsel während Start und Messung, wiederholtes Start/Stopp, belegtes Mikrofon, Streamfehler, Cleanup, gespeicherte Einstellungen nach Neustart und Alarm ohne Vibrator.

Gerätetests: mindestens zwei reale Android-Geräte unterschiedlicher Hersteller. Emulatoren prüfen UI und Plattformintegration, ersetzen keine Schallpegel-/Mikrofontests. Prüfe 30 Minuten Dauerbetrieb auf Crash, Ressourcenleck und ungewöhnliche Wärmeentwicklung.

Coverage-Gates: mindestens 90 % Line-Coverage für reine Domänen-/Anwendungslogik und 80 % über den eigenen messbaren Dart-Code. Native Logik zusätzlich separat testen; kritische Szenarien sind unabhängig von Coverage verpflichtend. Keine Garantie „hohe Qualität“ allein aus Prozentzahlen ableiten.

## 12. CI/CD auf GitHub

### Pull Requests und main

- Parallelisierte Jobs für Format/Lint, Unit-/Widget-Tests mit Coverage, native Checks und Android-Debug-Build.
- Emulator-Integrationstests mindestens vor Merge für kritische Änderungen; längere Matrix zusätzlich nächtlich oder wöchentlich.
- Erforderliche Statuschecks und Branchschutz dokumentieren und konfigurieren, sobald GitHub-Zugang vorhanden ist.
- Stabile Toolchain exakt pinnen; Caches an SDK-, Gradle- und Lockfile-Version koppeln.
- Externe Actions an vollständige Commit-SHAs pinnen; zugehörige Versionsnamen als Kommentar angeben. Keine erfundenen SHAs.
- Standard-Token nur lesend; Schreibrechte nur im benötigten Releasejob. Keine Release-Secrets in Fork-PRs und kein Ausführen fremden PR-Codes mit privilegiertem `pull_request_target`.
- Sinnvolle Timeouts, Concurrency-Abbruch für überholte PR-Läufe und befristete Test-/Build-Artefakte.

### Releasepipeline

- Release aus SemVer-Tag `vX.Y.Z`, Vorabversionen z. B. `v0.1.0-alpha.1`.
- Tag, Appversion, monotoner Android-`versionCode` und Changelog auf Konsistenz prüfen.
- Qualitätsgates am exakten Releasecommit ausführen; keine beliebigen alten Buildartefakte veröffentlichen.
- Signierte Release-APK für direkte Installation, AAB für optionalen Play-Upload; unterstützte ABIs dokumentieren.
- Keystore und Zugangsdaten als geschützte Secrets; nie im Repo oder Artefaktarchiv. Fehlende Signierung ist ein Releaseblocker und muss klar sichtbar sein.
- Erzeuge SHA-256-Prüfsummen, Abhängigkeits-/Lizenzinventar, SBOM und soweit unterstützt Build-Provenienz.
- GitHub Release mit Quellcode des Tags, APK, optional AAB, Prüfsummen, Lizenzhinweisen und verständlichen Release-Notizen vorbereiten.
- Produktion über geschützte Releaseumgebung freigeben. GitHub-Funktionen hängen vom verfügbaren Konto/Plan ab; benötigte Einstellungen dokumentieren.
- Releasehinweise nennen Änderungen, unterstützte Geräte/Android-Versionen, bekannte Grenzen und Installationsweg.
- Rücknahmeverfahren: fehlerhaften Release kennzeichnen, Assets gegebenenfalls zurückziehen, Fix mit höherer Version liefern. Android-Downgrade ist kein verlässlicher Rollbackweg.

## 13. GitHub-Releasezeitplan

Planungswerte relativ zum tatsächlichen Projektstart; keine zugesagten Kalendertermine. Bei fehlgeschlagenen Gates verschiebt sich die Veröffentlichung.

| Zeitraum | GitHub-Meilenstein | Abnahmekriterium |
| --- | --- | --- |
| Tag 1 | M0 – Fundament | AGENTS.md, Versionen geprüft/gepinnt, komplettes Android-Projekt, Architektur, erste grüne CI |
| Tag 2–3 | M1 – Kernfunktionen | Mikrofon bis UI, Zonen, Einstellungen, Alarmtests, installierbarer interner Debug-Build |
| Tag 4–5 | `v0.1.0-alpha.1` | Alle Hauptfunktionen, dokumentierte Grenzen, interne Testartefakte; keine Produktionsfreigabe |
| Woche 2 | `v0.2.0-beta.1` | Geräteprüfung, zugängliche UI, robuste Fehler-/Lifecycle-Pfade, vollständige Doku und Qualitätsgates |
| Ende Woche 2 | `v1.0.0-rc.1` | Signierte Artefakte, Lizenzinventar, Releaseprobe, keine offenen kritischen Fehler |
| Frühestens Woche 3 | `v1.0.0` | RC mindestens fünf Werktage erprobt, beide realen Geräte bestanden, Releasecheckliste vollständig |
| Danach wöchentlich | Wartung | Abhängigkeiten/SDK prüfen, Fehler triagieren, CI-Gesundheit kontrollieren |
| Danach monatlich nach Bedarf | Patch-/Minor-Release | Nur geprüfte Änderungen mit Changelog; keine Veröffentlichung ohne Bedarf |

Lege passende GitHub-Issues mit Akzeptanzkriterien und Abhängigkeiten an, sobald das Repository verfügbar ist. Labels: `feature`, `bug`, `testing`, `documentation`, `ci`, `security`, `release-blocker`. Ohne Zugriff liefere kopierbare Issue-/Milestone-Vorlagen statt behaupteter GitHub-Einträge. Dieser Plan erzeugt keine automatischen Erinnerungen oder bereits terminierten Veröffentlichungen.

## 14. Dokumentationsumfang

- README: Produktzweck, Screenshots, Installation, Schnellstart und Status.
- Toolchain/Build: exakte Versionen, frischer Checkout, Analyse, Tests, Debug-/Releasebuilds und Fehlersuche; Linux, macOS und Windows berücksichtigen.
- Architektur: Module, Schnittstellen, Zustandsmaschine, Lebenszyklus und ADRs.
- Messung: dBFS vs. geschätzte dB, RMS, Kalibrierung, Glättung, Grenzen und Alarmverhalten.
- Datenschutz: Berechtigungen, lokale Verarbeitung, keine Audioaufzeichnung.
- Testing: Testmatrix, reale Geräte, ausgeführte Ergebnisse und bekannte Lücken.
- Releasing: Signierung, Geheimnisverwaltung, Tags, Versionscodes, Artefakte und Wiederherstellungsprozess.
- CONTRIBUTING: lokaler Ablauf, Qualitätsregeln, 100-Zeilen-Regel und PR-Checkliste.
- SECURITY, CHANGELOG und vollständige Lizenzhinweise.

## 15. Definition of Done

Die Version gilt erst als fertig, wenn:

- [ ] Vollständiges Repository mit Android-Hostprojekt vorhanden ist; ein Build muss keine Projektdateien nachträglich erzeugen.
- [ ] AGENTS.md zuerst erstellt und die Arbeitsregeln eingehalten wurden.
- [ ] Neueste stabile Flutter-Version zum Projektstart und zugehöriges Dart geprüft, dokumentiert und exakt gepinnt sind.
- [ ] Alle Produktanforderungen und Alarmregeln implementiert und getestet sind.
- [ ] Keine eigene Funktion/Methode mehr als 100 Zeilen umfasst; CI erzwingt dies.
- [ ] Formatierung, Linter, Analyse, Tests, Coverage-Gates und Builds erfolgreich sind.
- [ ] Dokumentierte Android-/ABI-Matrix und zwei reale Gerätetests bestanden sind.
- [ ] Hintergrund, Berechtigungsdialoge und schnelle Start-/Stopp-Folgen keine Ressourcenlecks oder Rennen verursachen.
- [ ] GPL-v3-Datei, passende Quellcodebereitstellung und Lizenzinventar vollständig sind.
- [ ] Dokumentation vollständig ist und ein frischer Checkout anhand dieser Anleitung gebaut wurde.
- [ ] Signierte Releaseartefakte und Checksummen vorhanden sind oder fehlende Signierung ausdrücklich als Blocker benannt ist.
- [ ] GitHub-Workflows und Releasevorbereitung geprüft sind; tatsächlich fehlende Kontozugänge klar benannt werden.
- [ ] Keine offenen kritischen Fehler oder Releaseblocker bestehen.

## 16. Erwartete Abschlussübergabe des Agenten

Liefere Repository bzw. vollständiges Archiv, kurze Funktionsübersicht, konkrete Toolchain-Versionen, ausgeführte Befehle mit Ergebnissen, geprüfte Geräte, verbleibende Einschränkungen, Artefaktpfade und nächsten Release-Schritt. Unterscheide klar zwischen implementiert, automatisiert geprüft, auf Gerät geprüft und veröffentlicht.

## 17. Offizielle Referenzen zur erneuten Prüfung

Diese URLs sind Quellen für die Umsetzung; die tatsächlich aktuellen Versionen sind beim Start erneut zu prüfen.

- Flutter SDK und mitgelieferte Dart-Version: https://docs.flutter.dev/install/archive
- Flutter aktualisieren: https://docs.flutter.dev/install/upgrade
- Dart-Analyse: https://dart.dev/tools/analysis
- Dart-Lintregeln: https://dart.dev/tools/linter-rules
- GitHub Actions sicher einsetzen: https://docs.github.com/en/actions/reference/security/secure-use
- Android AudioRecord: https://developer.android.com/reference/android/media/AudioRecord
- Aktuelle Android-Ziel-API-Vorgaben: https://developer.android.com/google/play/requirements/target-sdk
