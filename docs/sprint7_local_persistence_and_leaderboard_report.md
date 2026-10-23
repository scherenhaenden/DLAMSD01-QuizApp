# Sprint 7 Technical Report: Local Persistence, History Tracking, and Leaderboard (`v0.7.0`)

**Maintainer:** `scherenhaenden`
**Project:** DLAMSD01 – Apple Mobile Solution Development I (Train-your-Brain iOS)  
**Target Release:** `v0.7.0` (Build `20261023.190000`)  
**Architecture Reference:** ADR-07: Highscore-Persistenz und Spielhistorie/Apple%20Mobile%20Solution%20Development%20I%20(DLAMSD01)/06_Architekturentscheidungen_und_Variantenvergleich_ADR.md#L289-L330)

---

## 1. Executive Summary & Sprint Scope

Sprint 7 introduces the local persistence layer, game history logging, and leaderboard tracking into Train-your-Brain, fulfilling the core requirements of **US-13**, **US-14**, and curriculum stages **48** and **62**:

* **US-13 (High Scores Retention):** *As a player, I want my high scores and personal bests retained across app restarts so I can track my improvement over time.*
* **US-14 (Rounds History & Academic Transcripts):** *As a learner, I want to inspect a history of my past quiz attempts, completion dates, German academic grades, accuracy percentages, and active response speeds.*
* **Curriculum Stage 48:** Implementation of the record persistence manager (`ScoreStoreProtocol` / `UserDefaultsScoreStore`).
* **Curriculum Stage 62:** Implementation of the leaderboard and history screen (`LeaderboardView` / `LeaderboardViewModel`).

All implementations comply with **ADR-07** (`UserDefaults` with serialized `Codable` JSON payloads), incorporating strict defensive measures: thread-safe synchronization (`NSLock`), maximum capacity capping (100 records) to prevent unbounded memory growth, automatic session auto-saving upon completion, and resilient recovery against corrupted data payloads.

---

## 2. Architecture & Implementation Details

```
┌────────────────────────────────────────────────────────┐
│                      Presentation Layer                │
│                                                        │
│   HomeView (Header "Scores")  ──(Sheet)──> LeaderboardView
│                                                  │
│                                          LeaderboardViewModel
│                                            (@MainActor)
│                                                  │
│   QuizViewModel (nextQuestion completion) ───────┤
└──────────────────────────────────────────────────┼─────┘
                                                   │
┌──────────────────────────────────────────────────▼─────┐
│                    Persistence Layer (ADR-07)          │
│                                                        │
│                 <<protocol>> ScoreStoreProtocol        │
│                                △                       │
│               ┌────────────────┴────────────────┐      │
│               │                                 │      │
│     UserDefaultsScoreStore              InMemoryScoreStore
│    (Thread-Safe NSLock, ISO8601,        (Unit Test Mock,
│     100 Capacity Cap, Corruption Guard)  Pure Memory)  │
└────────────────────────────────────────────────────────┘
```

### 2.1. Abstract Persistence Contract (`ScoreStoreProtocol.swift`)

The storage layer is decoupled via `ScoreStoreProtocol`, enabling zero-cost dependency injection and deterministic testing without touching `UserDefaults.standard` during automated CI runs:

```swift
public protocol ScoreStoreProtocol: Sendable {
    func save(record: ScoreRecord) throws
    func loadRecords() -> [ScoreRecord]
    func loadHighScores(limit: Int) -> [ScoreRecord]
    func bestScore(for category: QuizCategory?) -> ScoreRecord?
    func clearAll() throws
}
```

### 2.2. Production Storage Service (`UserDefaultsScoreStore.swift`)

* **Thread-Safety:** Protected with an internal `NSLock` to prevent concurrent write and read races between background tasks and the main thread.
* **ISO8601 Date Serialization:** Explicit `JSONEncoder.dateEncodingStrategy = .iso8601` and `JSONDecoder.dateDecodingStrategy = .iso8601` ensure consistent, platform-independent timestamp persistence.
* **Bounded Capacity:** Enforces `maxCapacity = 100`, automatically truncating older entries while keeping the newest and best records intact.
* **Corrupted Payload Recovery:** When decoding fails due to corrupted or tampered data, the store catches the failure, deletes the invalid key, and returns an empty list gracefully, preventing fatal startup crashes.

### 2.3. Presentation ViewModel (`LeaderboardViewModel.swift`)

* **Dual View Modes:**
  * `.highScores` ("High Scores"): Sorted primarily by score descending, secondarily by accuracy percentage descending, streak record descending, and completion date descending.
  * `.history` ("Recent Games"): Sorted strictly chronologically descending by `completedAt`.
* **Category Filtering:** Supports filtering by any specific `QuizCategory` or viewing all categories combined.
* **Aggregate Metrics:** Dynamically computes total games played, average accuracy percentage, and personal best record matching the active filter.
* **Destructive Deletion:** Coordinates history clearing via a two-step `confirmationDialog` to prevent accidental loss of user achievements.

### 2.4. Accessible SwiftUI View (`LeaderboardView.swift`)

* **Ergonomics & Layout:** Wrapped in a responsive `ScrollView` with `maxWidth: 550` to maintain comfortable readability and touch ergonomics on iPad (9th generation) and in landscape orientation.
* **Visual Hierarchy:**
  * Top summary bar with 3 statistics tiles (Games Played, Avg Accuracy, Best Score).
  * Segmented control switching seamlessly between High Scores and Recent Games.
  * Horizontal scrolling filter chips for category selection with minimum 44 pt touch targets.
  * Distinctive podium badges (#1 Gold, #2 Silver, #3 Bronze) for top rankings.
  * Official German grade badge (e.g. `1.3 · Sehr Gut`) color-coded green for passing ($\le 4.0$) and red for fail ($5.0$).
  * Empty state view with SF Symbol illustration (`trophy.circle`) when no records exist.
* **Accessibility:** All actionable elements feature explicit accessibility identifiers (`leaderboard.segmentPicker`, `leaderboard.dismiss`, `leaderboard.clearButton`, `leaderboard.emptyState`) and VoiceOver-compatible combined labels.

---

## 3. Verification & Test Evidence

### 3.1. Automated Unit Tests (Swift Package)

The test suite was extended with 13 dedicated unit tests in `Sprint7PersistenceAndLeaderboardTests.swift`:
1. `testUserDefaultsScoreStoreSavesAndLoadsRecordsChronologically`
2. `testUserDefaultsScoreStoreSortsHighScoresWithTieBreakers`
3. `testScoreStoreEnforcesCapacityCap`
4. `testBestScoreRetrievalByCategoryAndGlobal`
5. `testCorruptedDataRecoveryInUserDefaultsScoreStore`
6. `testClearAllRemovesStoredRecords`
7. `testQuizViewModelAutoSavesRecordOnSessionCompletion`
8. `testLeaderboardViewModelFilteringAndAggregation`
9. `testLeaderboardViewModelClearHistory`
10. `testLeaderboardViewRendersWithoutCrashing`
11. `testScoreStoreErrorDescriptionsAndProtocolExtension`
12. `testLeaderboardViewModelTabPropertiesAndHistorySorting`
13. `testLeaderboardViewSubviewsDirectEvaluation`

**Execution Result:**
* **Total Unit Tests:** **102 executed, 0 failures (100% success)** in 0.321 s.

### 3.2. Native UI Acceptance Tests (iPad 9th Generation)

Executed via `xcodebuild test` on the native iPad (9th generation) simulator:
* `testCategoryRoundShowsFeedbackResultsAndCanReplay`
* `testMixedRoundStartsAndReturnsToTopics`
* `testIncorrectAnswerMarksTheCorrectOption`
* `testCountdownTimerTimeoutTriggersImmediateFeedback`
* `testAccessibilityDynamicTypeKeepsCategoryStartAvailable`
* `testBackgroundTransitionPreservesRemainingTimeOnReturn`
* `testLeaderboardAndHistoryOpensAndDismisses` *(New in Sprint 7)*

**Execution Result:**
* **Total UI Tests:** **7 executed, 0 failures (`** TEST SUCCEEDED **`)** in 155.1 s.

---

## 4. Instrumented Code Coverage (`llvm-cov`)

Production line coverage across all 22 production source files measured via `llvm-cov report`:

| Production Source File | Executable Lines | Missed Lines | Line Coverage % | Executed Functions |
| :--- | :---: | :---: | :---: | :---: |
| `Models/AppTheme.swift` | 22 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/Difficulty.swift` | 31 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/Question.swift` | 128 | 24 | **81.25%** | 10 / 14 (71.4%) |
| `Models/QuizCategory.swift` | 37 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/QuizSession.swift` | 130 | 6 | **95.38%** | 17 / 18 (94.4%) |
| `Models/ScoreRecord.swift` | 209 | 16 | **92.34%** | 25 / 26 (96.2%) |
| `Services/HapticFeedbackService.swift` | 38 | 0 | **100.00%** | 16 / 16 (100.0%) |
| `Services/LocalQuestionService.swift` | 61 | 3 | **95.08%** | 6 / 6 (100.0%) |
| `Services/QuestionServiceProtocol.swift` | 12 | 3 | **75.00%** | 1 / 1 (100.0%) |
| `Services/ScoreStoreProtocol.swift` | 15 | 3 | **80.00%** | 1 / 2 (50.0%) |
| `Services/UserDefaultsScoreStore.swift` | 177 | 33 | **81.36%** | 20 / 24 (83.3%) |
| `ViewModels/LeaderboardViewModel.swift` | 106 | 10 | **90.57%** | 19 / 19 (100.0%) |
| `ViewModels/QuizViewModel.swift` | 292 | 20 | **93.15%** | 35 / 40 (87.5%) |
| `Views/Components/AnswerButton.swift` | 250 | 20 | **92.00%** | 17 / 18 (94.4%) |
| `Views/Components/CategoryCard.swift` | 239 | 9 | **96.23%** | 18 / 20 (90.0%) |
| `Views/Components/Color+Adaptive.swift` | 21 | 6 | **71.43%** | 5 / 7 (71.4%) |
| `Views/Components/QuestionCard.swift` | 141 | 1 | **99.29%** | 13 / 13 (100.0%) |
| `Views/Components/TimerBar.swift` | 114 | 22 | **80.70%** | 9 / 11 (81.8%) |
| `Views/Screens/HomeView.swift` | 521 | 43 | **91.75%** | 19 / 29 (65.5%) |
| `Views/Screens/LeaderboardView.swift` | 702 | 26 | **96.30%** | 38 / 46 (82.6%) |
| `Views/Screens/QuizView.swift` | 583 | 74 | **87.31%** | 12 / 22 (54.5%) |
| `Views/Screens/ResultView.swift` | 630 | 94 | **85.08%** | 14 / 21 (66.7%) |
| **TOTAL (All 22 Production Files)** | **4,459** | **413** | **90.74%** | **307 / 365 (84.1%)** |

---

## 5. Architectural Alignment & Limitations

* **Empirical Line Coverage:** Meets and exceeds the university benchmark requirement of $\ge 90\%$ (**90.74%** line coverage across 4,459 production lines).
* **ADR-07 Compliance:** Lightweight key-value persistence with `Codable` is completely sufficient for individual quiz logs (< 100 entries, < 250 KB) without introducing heavy CoreData or CloudKit synchronization overhead.
* **Catalog Management Extension (ADR-09 Proposal):** The proposal to allow in-app creation and editing of questions/topics remains an optional post-MVP enhancement. The persistence model established in Sprint 7 uses string-based category IDs (`categoryId: String`), providing direct structural compatibility whenever catalog authoring is scheduled.
