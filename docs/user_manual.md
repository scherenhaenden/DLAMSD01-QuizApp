# Train Your Brain – Benutzerhandbuch & Operativer Leitfaden
**DLAMSD01: Apple Mobile Solution Development I**  
*IU Internationale Hochschule (IU International University of Applied Sciences)*  
*Studiengang: B.Sc. Softwareentwicklung*  
*Anwendungsversion:* **v0.9.0** (Build `20261024.150000`)

---

## 1. Einleitung & Didaktische Zielsetzung

Die native iOS- und iPadOS-Applikation **Train Your Brain** wurde konzipiert, um Studierenden der Informatik und Softwareentwicklung eine interaktive, didaktisch fundierte Plattform zur Festigung prüfungsrelevanten Fachwissens bereitzustellen. Gemäß der Aufgabenstellung des Moduls *DLAMSD01* verbindet die Anwendung moderne Human-Interface-Guidelines von Apple mit fortgeschrittenen didaktischen Mechanismen:

- **Aktives Lernen (Active Recall):** Gezielte Wissensabfrage in Kernfächern des Curriculums (*Software Engineering*, *Swift & Apple Ökosystem*, *Algorithmen & Datenstrukturen*, *Qualitätssicherung & Testen*).
- **Sofortiges pädagogisches Feedback:** Unmittelbare Einblendung fachlicher Begründungen nach jeder Antwortabgabe, um Fehlkonzepte instantan aufzulösen.
- **Transparente akademische Leistungsmessung:** Abbildung des offiziellen deutschen Notensystems (1,0 bis 5,0) gemäß Rahmenprüfungsordnung der IU (§ 15 APO).
- **Personalisiertes Wissensmanagement:** Vollständige Authoring- und Importfunktionen für eigene Fächer und Fragenkataloge.

---

## 2. Systemvoraussetzungen & Installation

### 2.1 Technische Mindestanforderungen
| Parameter | Spezifikation |
|---|---|
| **Betriebssystem** | iOS 17.0+ / iPadOS 17.0+ |
| **Unterstützte Geräte** | iPhone (kompaktes Layout) & iPad (ab 9. Generation, optimiert für 10.2" bis 12.9") |
| **Entwicklungsumgebung** | Xcode 15.0+ (Swift-Sprachmodus 5.0, SwiftPM Tools 5.9) |
| **Architektur** | Native SwiftUI-Architektur (@MainActor, Combine, Sendable Domain Core) |
| **Konnektivität** | Vollständig offline-funktionsfähig; Internetverbindung optional nur für Web-Downloads von Fragenkatalogen erforderlich |

### 2.2 Bauen und Ausführen in Xcode
1. Klonen Sie das Repository und navigieren Sie in das Projektverzeichnis:
   ```bash
   git clone https://github.com/scherenhaenden/DLAMSD01-QuizApp.git
   cd DLAMSD01-QuizApp
   ```
2. Öffnen Sie `TrainYourBrain.xcodeproj` in Xcode.
3. Wählen Sie das Scheme **TrainYourBrain** und ein beliebiges Zielgerät (z. B. *iPhone 17* oder *iPad (9th generation)*).
4. Drücken Sie `Cmd + R` zum Starten oder führen Sie die Test-Suite mit `Cmd + U` aus.

### 2.3 Entwickler- und Test-Flags
Für reproduzierbare Prüfungen und automatisierte UI-Tests unterstützt die App spezielle Startargumente:
- `--reset-state`: Bereinigt beim Start deterministisch alle im Simulator gespeicherten JSON-Kataloge und Bestenlisten-Daten (`Application Support/TrainYourBrain/custom_catalog.json`), um einen sauberen Werkszustand zu simulieren.

---

## 3. Benutzeroberfläche & Navigation (Home Screen)

Beim Öffnen der App präsentiert die `HomeView` eine übersichtliche, vertikal scrollbare Lernzentrale.

```
┌────────────────────────────────────────────────────────┐
│  Train Your Brain               [Scores]  [Material]   │
│  Wähle ein Thema oder starte ein schnelles Quiz         │
├────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐  │
│  │ ⚡ Gemischte Runde                 (24 Fragen)   │  │
│  │ Alle Themenbereiche im schnellen Durchlauf       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  KATEGORIEN                                            │
│  ┌──────────────────────────────────────────────────┐  │
│  │ ⚙️ Software Engineering            (6 Fragen)    │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🍎 Swift & Apple Ecosystem        (6 Fragen)    │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🌲 Algorithms & Data Structures   (6 Fragen)    │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🧪 Testing & Quality Assurance     (6 Fragen)    │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### 3.1 Die zentralen Komponenten der Startansicht
1. **Kopfzeile (Header):**
   - **Titel & Untertitel:** Begrüßung und didaktische Handlungsaufforderung.
   - **Button [Scores]:** Öffnet das Modalblatt der Bestenliste und Spielhistorie (`LeaderboardView`).
   - **Button [Material]:** Öffnet den Manager für benutzerdefinierte Fächer und Fragen (`StudyMaterialManagerView`).
2. **Schnellstartkarte (Quick Play – Gemischte Runde):**
   - Wählt zufällig Fragen aus allen verfügbaren Fächern aus und aggregiert diese zu einer umfassenden Prüfungssimulation (mindestens 24 Fragen im Basiskatalog).
3. **Themenkarten (Category Cards):**
   - Jede Themenkarte zeigt das Fach-Icon (SF Symbol), den offiziellen Titel, die didaktische Kurzbeschreibung und die Anzahl der aktuell verfügbaren Fragen an.
   - Ein Tippen auf eine Karte startet sofort eine zielgerichtete Runde für dieses spezifische Thema.
4. **Ergonomie & Responsive Design:**
   - Auf iPads und Bildschirmen im Querformat (Landscape) ist der gesamte Inhalt in einem zentrierten **640-pt-Container** gebündelt. Dies verhindert überdehnte Lesezeilen und stellt sicher, dass alle Steuerelemente mühelos im beidhändigen Griff erreichbar bleiben.

---

## 4. Quiz-Ablauf & Interaktive Mechanismen

Nach dem Start einer Runde öffnet sich die `QuizView`. Der Ablauf ist in eine strenge Zustandsmaschine unterteilt, die Ablenkungen minimiert und Fokus garantiert.

### 4.1 Die Benutzeroberfläche der Quiz-Runde
- **Kopfzeile:** Schließen-Button (`xmark`), Anzeige des aktuellen Faches sowie der Fortschrittszähler (z. B. `Question 1 of 6`).
- **Reaktiver Countdown-Timer (`TimerBar`):**
  - Aktualisiert mit 10 Hz (alle 0,1 Sekunden) über Combine ohne RunLoop-Verzögerungen.
  - Das Zeitlimit skaliert dynamisch mit dem Schwierigkeitsgrad:
    - *Leicht (Easy):* 20 Sekunden
    - *Mittel (Medium):* 15 Sekunden
    - *Schwer (Hard):* 12 Sekunden
  - **Farbliche Dringlichkeitsphasen:**
    - *Normal (> 50% Zeit):* Neutrales Blau / Akzentfarbe.
    - *Warnung (20% bis 50% Zeit):* Warmes Gelb/Bernstein (`#FF9800`).
    - *Kritisch (<= 20% Zeit):* Dringendes Karmesinrot (`#FF2020`).
- **Fragenkarte (`QuestionCard`):**
  - Hervorgehobener Fragetext mit hohem Kontrast und Metadaten-Badge für den Schwierigkeitsgrad.
- **Antwortschaltflächen (`AnswerButton`):**
  - Vier klar voneinander unterscheidbare Optionen (`Option A:`, `Option B:`, etc.).
  - Jedes Steuerelement besitzt eine Mindesthöhe von **56 pt** für ergonomische Treffsicherheit nach WCAG 2.1 AAA.

### 4.2 Antwortauswahl & Didaktisches Feedback
1. **Tipp-Entprellung (Touch Debouncing):** Sobald eine Option gewählt wird, sperrt die App sofort alle Buttons, um versehentliche Doppelabgaben oder Race-Conditions zu verhindern.
2. **Visuelle & Sensorische Rückmeldung:**
   - **Richtige Antwort:** Der gewählte Button färbt sich smaragdgrün (`#1B5E20`) mit dem Symbol `checkmark.circle.fill`. Das Taptic Engine erzeugt ein spürbares `.success`-Muster.
   - **Falsche Antwort:** Der gewählte Button färbt sich karmesinrot (`#B71C1C`) mit dem Symbol `xmark.circle.fill`. Zeitgleich wird die tatsächlich richtige Option grün hervorgehoben, um den Lerneffekt zu maximieren. Das Taptic Engine signalisiert einen `.error`-Impuls.
   - **Zeitüberschreitung (Timeout):** Läuft der Timer ab, verfällt die Frage als unvollständig, die richtige Option wird angezeigt und ein `.warning`-Feedback ausgelöst.
3. **Pädagogische Rationale:**
   - Direkt unter den Antwortoptionen erscheint ein Infokasten mit der didaktischen Erklärung (*"Warum ist das so?"*).
4. **Manuelles Weiterschalten:**
   - Die App schaltet erst nach bewusstem Betätigen des Buttons **"Next Question"** (bzw. **"View Results"** bei der letzten Frage) weiter. Dadurch hat der Studierende ausreichend Zeit, die Erklärung in Ruhe zu lesen.

### 4.3 Schutz vor Manipulation (App Lifecycle & Anti-Cheat)
Wird die App während einer laufenden Frage minimiert oder in den Hintergrund verschoben, erfasst `ScenePhase` den exakten Zeitstempel über die kontinuierliche Systemzeit (`ProcessInfo.processInfo.systemUptime`). Beim erneuten Öffnen wird die abgelaufene Wanduhrzeit präzise von der verbleibenden Antwortzeit abgezogen. Manipulationsversuche über die manuelle Systemuhr werden dadurch vollständig neutralisiert.

---

## 5. Leistungsanalyse & Deutsches Notensystem

Nach Beendigung der letzten Frage präsentiert die `ResultView` eine detaillierte akademische Auswertung.

```
┌────────────────────────────────────────────────────────┐
│                   [ Round Completed! ]                 │
│                 Score: 6 / 6   •   100 %               │
│                                                        │
│               ┌───────────────────────┐                │
│               │   Note: 1,0 (Sehr Gut) │                │
│               └───────────────────────┘                │
├────────────────────────────────────────────────────────┤
│  KENNZAHLEN                                            │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │
│  │ Score: 6/6   │ │ Accuracy:100%│ │ Streak: 6 Max  │  │
│  └──────────────┘ └──────────────┘ └────────────────┘  │
│  ┌───────────────────────────────┐                     │
│  │ Avg Speed: 4.2s               │                     │
│  └───────────────────────────────┘                     │
├────────────────────────────────────────────────────────┤
│  THEMEN-AUFSCHLÜSSELUNG                                │
│  Software Engineering: 6 / 6 (100%) [████████████]     │
├────────────────────────────────────────────────────────┤
│  [ Play Again ]                     [ Return to Menu ] │
└────────────────────────────────────────────────────────┘
```

### 5.1 Das Deutsche Notensystem (IU Rahmenprüfungsordnung)
Die App ermittelt auf Basis der erreichten Prozentpunkte eine akademische Note gemäß der linearen Notenskala deutscher Hochschulen (§ 15 APO):

| Genauigkeit in % | Deutsche Note | Akademisches Prädikat | Farbcodierung |
| :---: | :---: | :--- | :--- |
| **95% – 100%** | **1,0** | Sehr gut | Smaragdgrün (`#1B5E20`) |
| **90% – 94%** | **1,3** | Sehr gut | Smaragdgrün (`#1B5E20`) |
| **85% – 89%** | **1,7** | Gut | Smaragdgrün (`#1B5E20`) |
| **80% – 84%** | **2,0** | Gut | Smaragdgrün (`#1B5E20`) |
| **75% – 79%** | **2,3** | Befriedigend | Smaragdgrün (`#1B5E20`) |
| **70% – 74%** | **2,7** | Befriedigend | Smaragdgrün (`#1B5E20`) |
| **65% – 69%** | **3,0** | Befriedigend | Smaragdgrün (`#1B5E20`) |
| **60% – 64%** | **3,3** | Ausreichend | Smaragdgrün (`#1B5E20`) |
| **55% – 59%** | **3,7** | Ausreichend | Smaragdgrün (`#1B5E20`) |
| **50% – 54%** | **4,0** | Ausreichend (Bestehensgrenze) | Smaragdgrün (`#1B5E20`) |
| **0% – 49%** | **5,0** | Nicht bestanden | Karmesinrot (`#B71C1C`) |

### 5.2 Das 4-Metriken-Dashboard
1. **Score:** Absolute Anzahl richtig beantworteter Fragen im Verhältnis zur Gesamtzahl.
2. **Accuracy:** Prozentuale Trefferquote.
3. **Streak:** Längste ununterbrochene Folge fehlerfreier Antworten innerhalb der Runde.
4. **Avg Speed:** Reine Bearbeitungszeit pro beantworteter Frage in Sekunden (unter Ausschluss von Pausen).

---

## 6. Bestenliste & Spielhistorie (`LeaderboardView`)

Über den Button **[Scores]** im Header der Startansicht öffnet sich das Sheet der Bestenliste.

### 6.1 Funktionsumfang
- **Zwei Ansichtsmodi:**
  - *High Scores:* Listet die erfolgreichsten Durchläufe auf. Ränge 1 bis 3 werden durch optische Podium-Badges hervorgehoben.
  - *Recent Games:* Chronologischer Verlauf aller absolvierten Übungsrunden mit relativem Zeitstempel.
- **Kategoriefilter:** Horizontale Filterchips ermöglichen das Filtern nach einzelnen Themengebieten oder der gemischten Runde.
- **Zusammenfassungsleiste:** Aggregierte Kennzahlen über alle Spiele (Gesamtzahl absolvierter Runden, mittlere Genauigkeit, persönlicher Rekord).
- **Historie löschen:** Über das Mülleimer-Symbol kann die Historie zurückgesetzt werden. Eine Bestätigungsabfrage schützt vor versehentlichem Löschen.
- **Speicherkapazität & Rekordschutz:** Der Speicher (`UserDefaultsScoreStore`) verwaltet bis zu 100 Einträge thread-sicher (`NSLock`). Das Verfahren `pruneRecordsWithBestProtection` stellt sicher, dass allzeitige persönliche Bestleistungen niemals durch neuere schwächere Runden überschrieben werden.

---

## 7. Eigenes Lernmaterial & Dynamischer Katalog (`StudyMaterialManagerView`)

Über den Button **[Material]** auf der Startseite gelangen Studierende in das Modul zur Erweiterung von Studieninhalten. Das Sheet ist in drei Registerkarten gegliedert.

### 7.1 Registerkarte 1: Fächer (Subjects)
- **Katalogübersicht:** Zeigt alle aktiven Fächer mit farbigen Kennzeichnungen an:
  - `Curriculum` (Grau): Unveränderliche Basisfächer der IU.
  - `Custom` (Blau): Vom Nutzer selbst angelegte oder importierte Fächer.
- **Neues Fach erstellen (`+ Add New Subject`):**
  1. Tippen Sie auf den Button `+ Add New Subject`.
  2. Geben Sie den Fachnamen (z. B. *"Cloud Computing"* oder *"Cybersecurity"*) und eine didaktische Beschreibung ein.
  3. Wählen Sie ein passendes Symbol aus dem integrierten SF-Symbols-Katalog.
  4. Tippen Sie auf **Save Subject**. Das neue Fach steht ab sofort im Hauptmenü für Übungsrunden bereit.
- **Fach bearbeiten & löschen:**
  - Benutzerdefinierte Fächer können über das Stift-Symbol umbenannt werden (`EditCategorySheet`).
  - Ein Wischen nach links (Swipe to Delete) löscht das Fach inklusive aller darin enthaltenen Fragen.
  - *Schutzregel:* Vordefinierte Systemfächer können weder verändert noch gelöscht werden.

### 7.2 Registerkarte 2: Fragen (Questions)
- **Fragenkatalog filtern:** Dropdown-Menü zur Filterung der Fragen nach Fach.
- **Neue Frage verfassen (`+ Add Question`):**
  1. Wählen Sie das Fach und den Schwierigkeitsgrad (*Easy*, *Medium*, *Hard*).
  2. Geben Sie die Fragestellung ein (mindestens 5 Zeichen).
  3. Befüllen Sie die **vier Antwortmöglichkeiten**.
  4. Markieren Sie per **Radio-Button** genau die Option, die fachlich zutrifft.
  5. Formulieren Sie eine aussagekräftige **pädagogische Begründung**.
  6. Tippen Sie auf **Save Question**.
- **Strikte Invariantenprüfung:** Die App verifiziert vor dem Speichern:
  - Keine leeren Felder oder reine Leerzeichen.
  - Genau 4 Antwortoptionen.
  - Keine doppelten Antworttexte unter den 4 Optionen.
  - Gültiger Index der korrekten Antwort (0 bis 3).
  Ungültige Eingaben werden mit verständlichen Fehlermeldungen abgewiesen.

### 7.3 Registerkarte 3: Import & Web-Download (Import)
Hier können vollständige Fragenkataloge ausgetauscht oder von Dozenten bereitgestellt werden.

#### A. Lokaler Datei-Import
1. Tippen Sie auf **Browse JSON File**.
2. Wählen Sie eine `.json`-Datei aus lokalen Dokumenten oder der iCloud Drive aus.
3. Die App validiert das Schema und importiert Fächer und Fragen atomar.

#### B. Download über Web-URL
1. Fügen Sie eine HTTPS-URL in das Eingabefeld ein (z. B. eine GitHub Raw-URL oder universitäre Quelle).
2. Tippen Sie auf **Download & Import**.
3. Die App ruft die Daten asynchron über `URLSession` ab und validiert sie vor der Übernahme.

#### C. Datensicherheit & Rollback-Garantie
- **Atomare Validierung:** Schlägt auch nur eine einzige Frage im Importkatalog fehl, bricht der gesamte Vorgang ab. Der bestehende Datenbestand bleibt zu 100% unberührt.
- **UUID-Kollisionsschutz:** Kollidiert die ID einer importierten Frage mit einer Basiskatalog-Frage, vergibt die App automatisch eine neue eindeutige UUID, sodass die Frage editierbar bleibt.
- **Notfall-Backup:** Bei Lesefehlern oder defekten Dateien auf dem Dateisystem wird vorab automatisch eine verifizierte Kopie (`custom_catalog.json.bak`) angelegt.

---

## 8. Barrierefreiheit (Accessibility) & Ergonomie

Train Your Brain erfüllt die internationalen Richtlinien für Barrierefreiheit (WCAG 2.1 AA und relevante AAA-Kriterien) sowie die Apple Accessibility Guidelines:

### 8.1 Seh- und Lesbarkeit
- **Dynamic Type:** Alle Texte, Buttons und Karten passen sich automatisch der Systemeinstellung für Schriftgrößen an (vollständig getestet bis zur Stufe **XXXL**). Texte brechen mehrzeilig um, ohne abgeschnitten zu werden.
- **Dunkelmodus (Dark Mode):** Vollständige Unterstützung mit adaptiven Farb-Tokens (`Color.adaptiveSuccessText`, `Color.adaptiveErrorText`, etc.).
- **Geprüfte Kontrastverhältnisse:**
  - Smaragdgrünes Erfolgs-Badge (`#1B5E20`) auf Weiß: **7,87:1** (übertrifft WCAG AAA 7,0:1).
  - Karmesinrotes Fehler-Badge (`#B71C1C`) auf Weiß: **6,57:1** (übertrifft WCAG AA 4,5:1).
  - Dark Mode Kontraste: Durchweg zwischen **6,03:1** und **10,39:1**.

### 8.2 Screenreader (VoiceOver)
- Alle interaktiven Elemente besitzen semantische Labels, Hints und Traits.
- Der Timer besitzt das Trait `.updatesFrequently` und liest Dringlichkeitsstufen vor.
- Antwort-Feedbacks ("Correct!", "Incorrect") werden nach der Auswahl automatisch als Live-Speech-Announcement ausgegeben.

### 8.3 Ergonomie & Touch-Flächen
- Alle primären Aktionsflächen (Antwort-Buttons, Start-Karten) besitzen eine Touch-Target-Höhe von mindestens **56 pt** (Mindestvorgabe von Apple: 44 pt).
- 640-pt-Begrenzung im Querformat verhindert Daumenüberdehnungen auf großen iPad-Bildschirmen.

---

## 9. Datenverwaltung & Speicherorte

Alle Anwendungsdaten werden lokal und sicher auf dem Gerät gespeichert:
- **Benutzerdefinierter Katalog:**
  `~/Library/Application Support/TrainYourBrain/custom_catalog.json`
- **Sicherheits-Backup bei Korruption:**
  `~/Library/Application Support/TrainYourBrain/custom_catalog.json.bak`
- **Spielhistorie & Highscores:**
  `UserDefaults` (Schlüssel: `train_your_brain_score_history_v1`)

---

## 10. Bilddokumentation (Screenshots-Referenz)

Die nachfolgende Tabelle verweist auf die offiziellen, aus den automatisierten Testläufen auf nativen Simulatoren exportierten Bildschirmaufnahmen:

| Bildschirm / Funktion | iPad (10.2") | iPhone (17) |
|---|:---:|:---:|
| **Startansicht & Themenauswahl** | [iPad Home](screenshots/report/ipad/home___category_counts.png) | [iPhone Home](screenshots/report/iphone/home___category_counts.png) |
| **Gemischte Runde (Quick Play)** | [iPad Quick Play](screenshots/report/ipad/home___mixed_round.png) | [iPhone Quick Play](screenshots/report/iphone/home___mixed_round.png) |
| **Dunkelmodus (Dark Mode)** | – | [iPhone Dark Mode](screenshots/report/iphone/home___dark_mode.png) |
| **Dynamic Type (XXXL Text)** | [iPad XXXL](screenshots/report/ipad/home___accessibility_xxxl.png) | [iPhone XXXL](screenshots/report/iphone/home___accessibility_xxxl.png) |
| **Richtige Antwort & Didaktik** | [iPad Correct Feedback](screenshots/report/ipad/quiz___answer_feedback.png) | [iPhone Correct Feedback](screenshots/report/iphone/quiz___answer_feedback.png) |
| **Falsche Antwort & Auflösung** | [iPad Incorrect Feedback](screenshots/report/ipad/quiz___incorrect_answer_feedback.png) | [iPhone Incorrect Feedback](screenshots/report/iphone/quiz___incorrect_answer_feedback.png) |
| **Timer-Ablauf (10-Hz Timeout)** | [iPad Timeout](screenshots/report/ipad/quiz___live_countdown_timeout.png) | [iPhone Timeout](screenshots/report/iphone/quiz___live_countdown_timeout.png) |
| **Hintergrund-Wiederaufnahme** | [iPad Lifecycle Resume](screenshots/report/ipad/quiz___resumed_after_background.png) | [iPhone Lifecycle Resume](screenshots/report/iphone/quiz___resumed_after_background.png) |
| **Ergebnisanalyse & Note** | [iPad Results](screenshots/report/ipad/results___completed_round.png) | [iPhone Results](screenshots/report/iphone/results___completed_round.png) |
| **Bestenliste (High Scores)** | [iPad Leaderboard](screenshots/report/ipad/leaderboard___modal_sheet.png) | [iPhone Leaderboard](screenshots/report/iphone/leaderboard___modal_sheet.png) |
| **Lernmaterial-Verwaltung** | [iPad Material Manager](screenshots/report/ipad/study_material___manager_opened.png) | [iPhone Material Manager](screenshots/report/iphone/study_material___manager_opened.png) |
| **Neues Fach erstellen (Modal)** | [iPad Add Subject](screenshots/report/ipad/study_material___add_subject_sheet.png) | [iPhone Add Subject](screenshots/report/iphone/study_material___add_subject_sheet.png) |
| **Querformat 640-pt Ergonomie** | [iPad Landscape Layout](screenshots/report/ipad/quiz___ipad_landscape_layout.png) | [iPhone Landscape Layout](screenshots/report/iphone/quiz___ipad_landscape_layout.png) |
