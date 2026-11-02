# Test- und Coverage-Abschlussbericht v1.0.0
## Umfassende Validierung: Unit-, Integrations-, E2E- und Manuelle Hardware-Tests

---

**Projekt:** Train-your-Brain (Native iOS- & iPadOS-Quiz-Applikation)  
**Modul:** DLAMSD01 – Apple Mobile Solution Development I  
**Studiengang:** B.Sc. Softwareentwicklung  
**Hochschule:** IU Internationale Hochschule  
**Maintainer:** `scherenhaenden`
**Datum:** 25. Oktober 2026  
**Zielversion:** Version 1.0.0 (Build `20261025.100000`)  
**Git-Zweig:** `fix/history-robustness-and-docs` (Vorbereitung für PR auf `master`)  
**Prüfplattformen:**  
- **Hardware:** iPad (9. Generation, 10,2", Modell `iPad12,1`, iPadOS 27.x) & iPhone (iOS 27.x)  
- **Simulator:** iPhone 17 (iOS 27.0) & iPad 9th Gen (iPadOS 27.0)  
- **Compiler / Test-Runner:** Apple Clang / Swift 5.10 / SwiftPM / LLVM-cov / XCTest & XCUITest  

---

## Inhaltsverzeichnis
1. [Management Summary](#1-management-summary)
2. [Gesamte Testpyramide im Überblick](#2-gesamte-testpyramide-im-überblick)
3. [Offizielle Code-Coverage-Ergebnisse (llvm-cov)](#3-offizielle-code-coverage-ergebnisse-llvm-cov)
   - [3.1 Globale Metriken und Schwellenwerte](#31-globale-metriken-und-schwellenwerte)
   - [3.2 Compilertechnische Erklärung zur Branch-Abdeckung in Swift](#32-compilertechnische-erklärung-zur-branch-abdeckung-in-swift)
   - [3.3 Detaillierte Komponenten- und Dateiabdeckung](#33-detaillierte-komponenten--und-dateiabdeckung)
4. [Stufe 1: Unit-Tests (Unittests)](#4-stufe-1-unit-tests-unittests)
5. [Stufe 2: Integrationstests (Integration Tests)](#5-stufe-2-integrationstests-integration-tests)
6. [Stufe 3: End-to-End & UI-Automatisierungstests (XCUITest)](#6-stufe-3-end-to-end--ui-automatisierungstests-xcuitest)
7. [Stufe 4: Protokoll für Manuelle Tests & Usability-Evaluation (Ausfüllbar)](#7-stufe-4-protokoll-für-manuelle-tests--usability-evaluation-ausfüllbar)
   - [7.1 Checkliste für Hardware- und Barrierefreiheits-Tests](#71-checkliste-für-hardware--und-barrierefreiheits-tests)
   - [7.2 Usability-Testprotokoll mit externer Testperson](#72-usability-testprotokoll-mit-externer-testperson)
8. [Fazit und Freigabe-Empfehlung](#8-fazit-und-freigabe-empfehlung)

---

## 1. Management Summary

Der vorliegende Prüfbericht dokumentiert die Qualitätssicherung und die empirischen Testergebnisse der mobilen Anwendung **Train-your-Brain (v1.0.0)**. Ziel der Teststrategie war es, eine systematische Verifikation der funktionalen und nicht-funktionalen Anforderungen gemäß den User Stories US-01 bis US-16 durchzuführen und das selbstgesetzte **interne Projektqualitätsziel von mindestens 80 % Testabdeckung** in den vom Swift-Toolchain-Profiler (`llvm-cov`) gemessenen Dimensionen zu erreichen.

### Wichtigste Ergebnisse auf einen Blick:
- **152 von 152 Unit- und Integrationstests bestanden (100 % Erfolgsquote, 0 Fehler, SwiftPM auf macOS arm64).**
- **Alle von `llvm-cov` instrumentierten Coverage-Dimensionen erreichen das interne Projektziel ($\ge 80\%$):**
  - **Lines of Code (Zeilenabdeckung):** **90,84 %** (7.862 / 8.655 Zeilen)
  - **Functions (Methodenabdeckung):** **89,12 %** (639 / 717 Funktionen)
  - **Execution Regions (Ausführungsregionen):** **89,10 %** (1.406 / 1.578 Regionen)
- **Alle 26 Produktionsdateien (`src/`) erreichen einzeln $\ge 80,0\%$ in Zeilen, Funktionen und Regionen.**
- **12 native E2E-UI-Tests (`XCUITest`):** Alle 12 Testmethoden in `ui-tests/TrainYourBrainUITests.swift` laufen deterministisch auf dem **iPad (9th generation) Simulator** durch; die 9 Kern-Flows wurden zusätzlich auf dem **iPhone 17 Simulator** verifiziert.
- **Hardware-Bereitstellung & bestätigter physischer Nachtest (02.11.2026):** Das aktualisierte App-Bundle (`v1.0.0`, Build `20261025.100000`) wurde am 02.11.2026 auf einem physischen iPad (9. Generation, `iPad12,1`, iPadOS 27.0.1 Build `24A446`) installiert und anhand eines unabhängigen Testplans erfolgreich geprüft: Das Speichern eigener Fragen funktionierte einwandfrei; ein ergänzender UX-Hinweis zur Übersichtlichkeit der Fragen- und Fächeraufteilung wurde als Verbesserungspotenzial für eine Folgeversion (`v1.1`) aufgenommen.

---

## 2. Gesamte Testpyramide im Überblick

Die Testarchitektur folgt der klassischen Software-Testpyramide nach Mike Cohn, angepasst an moderne Apple-Plattformparadigmen:

```
               / \
              /   \
             / MAN \      Stufe 4: Manuelle Tests (Hardware iPad 9, VoiceOver, Taptic Engine)
            /-------\
           /   E2E   \    Stufe 3: End-to-End UI-Tests (12 XCUITest Flows auf iPhone & iPad)
          /-----------\
         / INTEGRATION \  Stufe 2: Integrationstests (ViewModels + Services + Persistence)
        /---------------\
       /    UNIT TESTS   \ Stufe 1: 152 Unit-Tests (Domänenmodelle, Algorithmen, Validierung)
      /-------------------\
```

---

## 3. Offizielle Code-Coverage-Ergebnisse (llvm-cov)

### 3.1 Globale Metriken und Schwellenwerte

Die Erhebung erfolgte mittels instrumentiertem Profiling über `swift test --enable-code-coverage` und den offiziellen LLVM-Coverage-Export (`docs/evidence/final_audit_2026-10-30/llvm_cov_report.txt` & `llvm_cov_export_summary.json`):

| Test-Metrik | Was wird gemessen? | Erreicht (App-Code) | Internes Projektziel | Status |
| :--- | :--- | :---: | :---: | :---: |
| **Lines (Zeilen)** | Prozentualer Anteil aller ausgeführten Codezeilen. | **90,84 %** (7.862 / 8.655) | $\ge 80,0\%$ | ✅ **Erfüllt** |
| **Functions (Funktionen)** | Prozentualer Anteil aller aufgerufenen Methoden/Closures. | **89,12 %** (639 / 717) | $\ge 80,0\%$ | ✅ **Erfüllt** |
| **Execution Regions** | Ausgeführte AST-Code-Regionen und Teilausdrücke. | **89,10 %** (1.406 / 1.578) | $\ge 80,0\%$ | ✅ **Erfüllt** |
| **Branches (Zweige)** | Wahrheitswert-Verzweigungen (`true`/`false` je Bedingung). | *0 / 0 (In SwiftPM-Standardprofil nicht ausgewiesen)* | N/A | ℹ️ **Nicht instrumentiert** |

*(Unter Einbeziehung des Test-Codes selbst liegt die Gesamtabdeckung bei 92,6 % Zeilen, 91,4 % Funktionen und 89,8 % Regionen).*

### 3.2 Compilertechnische Abgrenzung: Execution Regions vs. Branch-Coverage in Swift

In der Literatur zur Softwarequalitätssicherung werden häufig *Line-, Function-, Region/Statement-* und *Branch-/Path-Coverage* unterschieden.

> **Methodische Einordnung zum LLVM-Export (`branches: 0/0`):**  
> Beim Ausführen von `swift test --enable-code-coverage` erzeugt der Swift-Compiler (`swiftc` / Apple Clang) Zähler für **Lines**, **Functions** und **Execution Regions**, gibt jedoch in der Standardkonfiguration `branches: 0/0` aus.  
> 
> **Wichtige Abgrenzung:** Eine *Execution Region* markiert einen zusammenhängenden Code-Abschnitt oder Teilausdruck im abstrakten Syntaxbaum (AST), etwa den Rumpf eines `if`-, `else`-, `guard`-, `switch`- oder `catch`-Blocks. Eine Regionenabdeckung von **89,10 %** belegt, welcher Anteil dieser Code-Blöcke mindestens einmal betreten wurde. Sie ist jedoch **nicht gleichbedeutend mit einer vollständigen Branch- oder Pfadabdeckung** (d. h. sie beweist nicht automatisch, dass jede einzelne boolesche Teilbedingung sowohl zu `true` als auch zu `false` ausgewertet oder jede kombinatorische Pfadfolge durchlaufen wurde). Kritische fachliche Verzweigungen wurden deshalb gezielt über dedizierte Positiv- und Negativ-Unit-Tests geprüft.

---

### 3.3 Detaillierte Komponenten- und Dateiabdeckung

Alle 26 Quelldateien der Kernanwendung im Überblick – **jede einzelne Datei liegt über 80 %**:

| Quellcode-Datei (`src/`) | Typ / Schicht | Lines (%) | Functions (%) | Statements / Regions (%) | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `AppTheme.swift` | Theme / Domain | **100,00 %** (22/22) | **100,00 %** (4/4) | **100,00 %** (16/16) | ✅ Vollständig |
| `Difficulty.swift` | Model / Domain | **100,00 %** (31/31) | **100,00 %** (4/4) | **100,00 %** (16/16) | ✅ Vollständig |
| `HapticFeedbackService.swift` | Service / Sensory | **100,00 %** (38/38) | **100,00 %** (16/16) | **100,00 %** (16/16) | ✅ Vollständig |
| `QuestionServiceProtocol.swift` | Protocol / DI | **100,00 %** (38/38) | **100,00 %** (9/9) | **100,00 %** (22/22) | ✅ Vollständig |
| `ScoreStoreProtocol.swift` | Protocol / DI | **100,00 %** (15/15) | **100,00 %** (2/2) | **100,00 %** (7/7) | ✅ Vollständig |
| `ResultView.swift` | View / Screen | **100,00 %** (695/695) | **100,00 %** (21/21) | **100,00 %** (38/38) | ✅ Vollständig |
| `Color+Adaptive.swift` | View / Theme | **100,00 %** (96/96) | **100,00 %** (22/22) | **100,00 %** (32/32) | ✅ Vollständig |
| `UserDefaultsScoreStore.swift` | Service / Persistence | **99,39 %** (163/164) | **100,00 %** (28/28) | **98,15 %** (53/54) | ✅ Exzellent |
| `QuestionCard.swift` | View / Component | **99,29 %** (140/141) | **100,00 %** (13/13) | **90,00 %** (18/20) | ✅ Exzellent |
| `CustomCatalogPayload.swift` | Model / Serialization | **98,89 %** (89/90) | **90,91 %** (10/11) | **92,86 %** (26/28) | ✅ Exzellent |
| `QuizCategory.swift` | Model / Open Enum | **98,17 %** (107/109) | **100,00 %** (11/11) | **96,15 %** (50/52) | ✅ Exzellent |
| `Question.swift` | Model / Invariants | **97,66 %** (125/128) | **100,00 %** (14/14) | **96,15 %** (50/52) | ✅ Exzellent |
| `AnswerButton.swift` | View / Component | **97,60 %** (244/250) | **94,44 %** (17/18) | **92,75 %** (64/69) | ✅ Exzellent |
| `LeaderboardViewModel.swift` | ViewModel | **97,26 %** (71/73) | **100,00 %** (18/18) | **97,06 %** (33/34) | ✅ Exzellent |
| `LeaderboardView.swift` | View / Screen | **96,31 %** (678/704) | **82,61 %** (38/46) | **86,30 %** (63/73) | ✅ Exzellent |
| `CategoryCard.swift` | View / Component | **96,23 %** (230/239) | **90,00 %** (18/20) | **88,00 %** (44/50) | ✅ Stark |
| `LocalQuestionService.swift` | Service / Engine | **96,17 %** (552/574) | **94,34 %** (50/53) | **90,37 %** (197/218) | ✅ Stark |
| `QuizView.swift` | View / Screen | **96,11 %** (544/566) | **84,62 %** (22/26) | **87,50 %** (49/56) | ✅ Stark |
| `QuizSession.swift` | Model / Session | **95,45 %** (126/132) | **94,74 %** (18/19) | **84,00 %** (42/50) | ✅ Stark |
| `NetworkCatalogImporter.swift` | Service / Networking | **95,12 %** (39/41) | **100,00 %** (4/4) | **95,24 %** (20/21) | ✅ Stark |
| `HomeView.swift` | View / Screen | **95,14 %** (529/556) | **80,00 %** (32/40) | **82,00 %** (41/50) | ✅ Stark |
| `QuizViewModel.swift` | ViewModel / Core State | **95,08 %** (367/386) | **88,89 %** (48/54) | **84,72 %** (122/144) | ✅ Stark |
| `ScoreRecord.swift` | Model / Value Object | **92,44 %** (208/225) | **93,10 %** (27/29) | **93,48 %** (86/92) | ✅ Stark |
| `TimerBar.swift` | View / Component | **81,03 %** (94/116) | **81,82 %** (9/11) | **90,91 %** (20/22) | ✅ Stark |
| `StudyMaterialManagerView.swift` | View / Editor | **81,27 %** (2.573/3.166) | **81,99 %** (173/211) | **81,23 %** (264/325) | ✅ Stark |
| `CategoryRegistry.swift` | Model / Registry | **80,00 %** (48/60) | **84,62 %** (11/13) | **80,95 %** (17/21) | ✅ Stark |
| **GESAMT (`llvm-cov report`)** | **26 Produktionsdateien** | **90,84 %** (7.862/8.655) | **89,12 %** (639/717) | **89,10 %** (1.406/1.578) | 🏆 **100 % ALLER DATEIEN >= 80 %** |

---

## 4. Stufe 1: Unit-Tests (Unittests)

Die Unit-Test-Suite umfasst 152 Tests und deckt sämtliche Algorithmen, Datenstrukturen und isolierte Komponenten ab:

1. **Domänenmodell `Question` & Invarianten:**
   - Verifikation aller 6 `ValidationError`-Fälle (leerer Fragetext, unzureichende/leere Optionen, fehlerhafte Indexe, Duplikate).
   - Fisher-Yates-Mischalgorithmus: Sicherstellung, dass Optionen randomisiert werden, aber der Zeiger auf die korrekte Antwort deterministisch mitgeführt wird.
   - Abwärtskompatibles Codable-Roundtripping: Automatisches Generieren von UUIDs und Fallback auf `Difficulty.medium` bei unvollständigen externen Daten.
2. **Scoring- und Bewertungssystem (`ScoreRecord`):**
   - Berechnung der akademischen Note (1,0 bis 5,0) basierend auf der linearen Produktskala (Bestehensgrenze bei genau 50 %).
   - Streak-Multiplikatoren und Zeitmessungsberechnungen (durchschnittliche Antwortzeit, Gesamtdauer).
3. **Session-Logik (`QuizSession`):**
   - Zustandsübergänge: Initial -> Laufend -> Beantwortet -> Timeout -> Beendet.
   - Isolierte Berechnung von Streak-Rekorden ohne Seiteneffekte.
4. **Themen und Barrierefreiheit (`AppTheme`, `Color+Adaptive`):**
   - Prüfung aller System-, Hell- und Dunkelmodus-Farben auf WCAG 2.1 AAA-Kontrast (> 7:1 für Feedback, > 4,5:1 für Text & Icons).
   - Dynamische Farbauflösung unter AppKit (macOS) und UIKit (iOS).

---

## 5. Stufe 2: Integrationstests (Integration Tests)

Die Integrationstests validieren das Zusammenspiel mehrerer Schichten und externer Subsysteme:

1. **ViewModel & Persistence (`QuizViewModel` <-> `UserDefaultsScoreStore`):**
   - **Corrupted Data Recovery (C02):** Bei korrupten oder beschädigten `UserDefaults`-Payloads erfolgt keine destruktive Löschung; die fehlerhaften Bytes werden unter `.corrupted_bak` gesichert, bevor der aktive Speicher zurückgesetzt wird.
   - **Resilience bei Schreibfehlern (C01):** Schlägt das Speichern fehl, bleibt der Zustand `.finished(record)` intakt und der Fehler wird im `@Published var lastScoreSaveError` transparent an die Benutzeroberfläche übergeben.
2. **Katalogverwaltung & Transaktionssicherheit (`LocalQuestionService` & `CategoryRegistry`):**
   - **Transaktionales Rollback:** Schlägt der Import eines externen Katalogs fehl (z. B. fehlerhaftes JSON oder Duplikat-IDs), wird der In-Memory-Zustand der `CategoryRegistry` vollständig auf den vorherigen Snapshot zurückgerollt.
   - **Schutz der Systemfächer:** Lösch- und Änderungsversuche an den 4 vordefinierten Hochschulfächern werden mit spezifischen Exceptions (`systemCategoryDeletionNotAllowed`) blockiert.
3. **Lebenszyklus-Integration:**
   - Simulation des Übergangs in den Hintergrund (`ScenePhase.background`) mit automatischem Pausieren des Timers und sauberer Reaktivierung bei Rückkehr in den Vordergrund (`ScenePhase.active`).

---

## 6. Stufe 3: End-to-End & UI-Automatisierungstests (XCUITest)

Die native XCUITest-Suite in `ui-tests/TrainYourBrainUITests.swift` umfasst exakt **12 Testmethoden** und prüft die lauffähige Applikation im Simulator:

| Exakter Methodenname (`TrainYourBrainUITests.swift`) | Geprüfter User-Flow & Pflicht-Assertions | Verifizierte Umgebung | Ergebnis |
| :--- | :--- | :---: | :---: |
| `testCategoryRoundShowsFeedbackResultsAndCanReplay` | Auswahl Fach „Software Engineering“ $\to$ 6 Fragen beantworten $\to$ Scorecard-Metriken (`result.gradeValue`, `result.scoreValue`, `result.accuracyValue`, `result.speedValue`, `result.categoryBreakdownSection`) $\to$ „Play Again“ | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testMixedRoundStartsAndReturnsToTopics` | Start „All Topics (Mixed)“ $\to$ 24 Fragen durchspielen $\to$ Ergebnisansicht $\to$ „Change Topic“ zurück zu `HomeView` | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testIncorrectAnswerMarksTheCorrectOption` | Start Fachrunde $\to$ Antwort wählen $\to$ Prüfung auf Feedback-Erklärung (`quiz.explanation`) und Weiter-Button (`quiz.nextButton`) | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testAccessibilityDynamicTypeKeepsCategoryStartAvailable` | App-Start mit `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge` (XXXL) $\to$ Startbarkeit der Fachrunde | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testLiveCountdownReachesTimeoutAndEnablesAdvance` | Warten auf realen Countdown-Ablauf (25 s Timeout-Fenster) $\to$ Prüfung auf `Time's Up!` Banner und Aktivierung von `quiz.nextButton` | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testBackgroundAndForegroundResumeDeductsTimeAndPreservesGameplay` | Spielstart $\to$ `XCUIDevice.shared.press(.home)` (Hintergrund) $\to$ `app.activate()` $\to$ Abzug verstrichener Zeit (`systemUptime`) und Fortsetzung der Runde | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testLeaderboardAndHistoryOpensAndDismisses` | Öffnen von `home.scoresButton` $\to$ Wechsel zwischen „High Scores“ und „Recent Games“ (`leaderboard.modePicker`) $\to$ Schließen per `leaderboard.doneButton` | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testIPadLandscapeAndPortraitErgonomicAdaptation` | Rotation `.landscapeLeft` $\to$ Prüfung 640pt-Containerbreite (`width <= 680pt`) und Touch-Targets ($\ge 44\text{ pt}$) auf `HomeView`, `QuizView`, `ResultView`, `LeaderboardView` $\to$ `.portrait` | iPad 9 Sim (`iPad12,2`) | ✅ PASS |
| `testStudyMaterialManagerSheetCanOpenAndClose` | E2E-Durchstich: Fach „Robotics“ anlegen $\to$ umbenennen in „Robotics Lab“ $\to$ Frage „What is ROS?“ anlegen $\to$ Runde spielen $\to$ Frage & Fach löschen (`XCTAssertFalse`) | iPad 9 Sim & iPhone 17 Sim | ✅ PASS |
| `testQuestionSaveValidationAndErrorAlerts` | Prüft alle 4 modalen Validierungs-Alerts inkl. exakter Fehlertexte (leerer Fragetext, fehlende Optionen, Duplikat-Optionen, leere Erklärung), Korrektur, Speichern und Pflicht-Löschung | iPad 9 Sim (`iPad12,2`) | ✅ PASS |
| `testMultipleCustomSubjectsQuestionIsolation` | Erstellt 2 eigene Fächer („Algebra“, „Geometry“), legt je eine Frage an und prüft über `studyMaterial.categoryFilterPicker` mit `XCTAssertTrue`/`XCTAssertFalse` die strikte Isolation | iPad 9 Sim (`iPad12,2`) | ✅ PASS |
| `testEditCustomQuestionContentAndDifficulty` | Erstellt eigene Frage (`Medium`), öffnet Editor (Pflicht-Assertion ohne `if`), ändert Schwierigkeit auf `Hard` und Text auf `(Updated)`, prüft Liste sowie Persistenz nach `app.terminate()` + `app.launch()` | iPad 9 Sim (`iPad12,2`) | ✅ PASS |

---

## 7. Stufe 4: Protokoll für Manuelle Tests & Usability-Evaluation (Ausfüllbar)

Dieses Formular ist für die Durchführung der physischen Hardwaretests auf dem **iPad (9. Generation)** und dem **iPhone** sowie für die Beobachtung einer externen Testperson vorbereitet.

### 7.1 Checkliste für Hardware- und Barrierefreiheits-Tests

*Tester:* ___________________________  
*Gerät:* iPad (9. Gen) / iPhone ________  
*Betriebssystem:* iPadOS 27.x / iOS 27.x  
*Datum:* ____.____.2026  

| Nr. | Prüfpunkt / Kriterium | Erwartetes Verhalten | Status | Bemerkungen / Notizen des Testers |
| :---: | :--- | :--- | :---: | :--- |
| **M01** | **Zertifikats-Vertrauen & Launch** | App startet ohne Fehler nach Aktivierung in *Einstellungen > Allgemein > VPN & Geräteverwaltung*. | [ ] Pass<br>[ ] Fail | |
| **M02** | **Touch-Targets (44x44 pt)** | Alle 4 Antwort-Buttons, Menü-Buttons und Tab-Leisten lassen sich auch mit großen Fingern zielsicher antippen. | [ ] Pass<br>[ ] Fail | |
| **M03** | **VoiceOver-Screenreader** | Bei aktiviertem VoiceOver liest iOS Frage, Index und Antwortoptionen klar vor. Nach Beantwortung erfolgt eine akustische Erfolgs-/Fehlermeldung. | [ ] Pass<br>[ ] Fail | |
| **M04** | **Physische Haptik (iPhone)** | Bei richtiger Antwort erfolgt spürbarer leichter Impuls (`UIImpactFeedbackGenerator`); bei falscher Antwort Doppelimpuls (`UINotificationFeedbackGenerator`). | [ ] Pass<br>[ ] Fail | *(Hinweis: iPad unterstützt keine Vibration)* |
| **M05** | **iPad-Ergonomie (Layout)** | Im Hoch- und Querformat bleibt der Inhalt zentriert und ergonomisch auf 640 pt begrenzt. Keine Textverzerrung. | [ ] Pass<br>[ ] Fail | |
| **M06** | **Große Schriftgrößen (Dynamic Type)** | In *Einstellungen > Bedienungshilfen > Anzeige & Textgröße* maximale Schriftgröße wählen: UI bricht dynamisch um ohne abgeschnittenen Text. | [ ] Pass<br>[ ] Fail | |
| **M07** | **Echter Netzwerk-Download** | Im Material-Manager eine externe JSON-URL eingeben: Download lädt Fragen herunter und zeigt grünes Feedback. | [ ] Pass<br>[ ] Fail | |
| **M08** | **App-Wechsel / Standby** | Während einer Frage Home-Geste ausführen, 5 Sekunden warten und zurückkehren: Timer war pausiert, Quiz läuft weiter. | [ ] Pass<br>[ ] Fail | |

---

### 7.2 Usability-Testprotokoll mit externer Testperson

*Testperson (Pseudonym):* ___________________________  
*Alter / Hintergrund:* ___________________________  
*Beobachter:* Projektleitung  
*Dauer:* ca. 15 Minuten  

#### Aufgaben für die Testperson:
1. **Aufgabe 1 (Schnellstart):** Starten Sie die App und spielen Sie eine 5-Fragen-Runde im Gesamtkatalog.
2. **Aufgabe 2 (Ergebnis):** Begutachten Sie Ihren Notenschnitt und Ihre durchschnittliche Antwortzeit im Ergebnisbildschirm.
3. **Aufgabe 3 (Eigenes Fach):** Erstellen Sie im Bereich „Material“ ein neues Fach namens *„Künstliche Intelligenz“* und fügen Sie eine eigene Frage hinzu.
4. **Aufgabe 4 (Highscore):** Überprüfen Sie, ob Ihre Runde in der Historie der Bestenliste eingetragen ist.

#### Beobachtungen & Usability-Metriken (Ausfüllen):

| Kriterium | Bewertung (1 = Sehr schlecht, 5 = Ausgezeichnet) | Beobachtete Probleme / Zitate der Testperson |
| :--- | :---: | :--- |
| **Intuitivität der Navigation** | [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] | |
| **Verständlichkeit des Timers** | [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] | |
| **Klarheit des Farbfeedbacks** | [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] | |
| **Aufwand Frage-Erstellung** | [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] | |
| **Gesamteindruck & Motivation** | [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] | |

**Freitext-Feedback der Testperson:**  
> *„____________________________________________________________________________________*  
> *____________________________________________________________________________________*  
> *____________________________________________________________________________________“*  

**Unterschrift / Abnahme Tester:** ___________________________  
**Datum:** ____.____.2026  

---

## 8. Fazit und Freigabe-Empfehlung

Die vorliegenden Prüfergebnisse fassen den verifizierten Stand von **Train-your-Brain v1.0.0** zusammen:

1. **Automatisierte Testabdeckung:** Alle 16 User Stories (US-01 bis US-16) sind durch 152 automatisierte Unit-/Integrationstests (SwiftPM) sowie 12 native XCUITest-Szenarien (insgesamt 164 automatisierte Tests) abgedeckt.
2. **Internes Coverage-Ziel erreicht:** Mit **90,84 % Zeilen**, **89,12 % Funktionen** und **89,10 % Ausführungsregionen** (und **allen 26 Quellcode-Dateien einzeln $\ge 80\%$**) wird das selbstgesetzte interne Projektqualitätsziel ($\ge 80\%$) in allen von `llvm-cov` instrumentierten Dimensionen erreicht.
3. **Physischer Hardware-Nachtest & Usability-Feedback abgeschlossen (02.11.2026):** Nach dem Deployment des gehärteten Builds auf ein physisches iPad (9. Generation, `iPad12,1`, iPadOS 27.0.1) wurde der Nachtest anhand eines unabhängigen Benutzertestplans durchgeführt. Das Speichern eigener Fragen ist auf dem Endgerät behoben; das qualitative UX-Feedback zur Vereinfachung der Fragen- und Fächeraufteilung wird im Sinne eines sauberen Release-Freezes als Weiterentwicklungspotenzial für eine Folgeversion (`v1.1`) festgehalten. Die detaillierte Schritt-für-Schritt-Prüfung aller Editor-Aktionen ist zusätzlich durch die 12 XCUITest-Szenarien auf dem iPad-9-Simulator abgesichert.
