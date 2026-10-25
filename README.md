# Train Your Brain

Native SwiftUI quiz developed for DLAMSD01 Apple Mobile Solution Development I at IU.

## Current development stage

Version **1.0.0** (Build `20261025.100000`), Sprint 10: Final Academic Release (Final code freeze, hardened non-conditional UI assertions, corruption warning UI verification, 135 unit/integration tests with 100% success, 9 native UI acceptance tests on iPhone 17 and iPad 9, 20-screenshot operational suite, and comprehensive Word user manual `docs/user_manual.md`).

### Implemented

- Final Academic Release Gate (Sprint 10): Version 1.0.0 code freeze, monotonic build number 20261025.100000, 135 XCTest unit/integration tests (100% passing in 0.66s), 9 native UI tests on iPhone 17 and iPad 9 (100% passing), hardened non-conditional UI deletion verification, and verified corruption alert rendering.

- Dynamic Study Material & Extensible Categories: `QuizCategory` is an open struct supported by thread-safe in-memory `CategoryRegistry`, combining foundational B.Sc. curriculum subjects with user-defined or imported subjects.
- In-App Question Authoring: Direct on-device question creation with prompt, 4 options, radio-picker to designate the single correct choice, pedagogical rationale, category classification, and difficulty rating (`Easy`, `Medium`, `Hard`).
- Robust Domain Invariant Validation: Questions enforce non-empty prompt/explanation, exactly 4 unique options, and a valid correct answer index (0..<4). Malformed entries are rejected before saving.
- Persistent Sandbox Storage: User-created categories and questions are persisted atomically to `Application Support/TrainYourBrain/custom_catalog.json`, surviving app terminations and device restarts. Core curriculum questions remain immutable.
- Dual External Material Import:
  - Local JSON import via `.fileImporter` (local storage and iCloud Drive).
  - Remote web download via `URLSession` (`NetworkCatalogImporterProtocol`).
  - Transactional rollback, duplicate-key resilience, and verified emergency backup: corrupt or invalid question payloads abort cleanly without modifying in-memory state or disk, duplicate category keys are deduplicated without fatal errors, imported questions colliding with base curriculum IDs receive new unique UUIDs, and corrupted local files generate a verified emergency `.bak` backup copy (blocking subsequent overwrites if backup cannot be protected).
- Comprehensive Management UI (`StudyMaterialManagerView`): Modal sheet accessible from HomeView with 3 segmented tabs: *Subjects* (with system vs custom badges, in-app editing via `EditCategorySheet`, and swipe-to-delete), *Questions* (filterable by subject with edit/delete actions), and *Import* (file browsing and URL download with accessible status feedback and corruption/backup warning display).
- Multi-device ergonomic layout: 640 pt centered container across all primary screens (`HomeView`, `QuizView`, `ResultView`, `LeaderboardView`), ensuring optimal reading line length (50-75 characters) and thumb-reach comfort on iPad (9th generation, 10.2" display) in both Portrait and Landscape orientations (US-15).
- Deep VoiceOver accessibility: semantic labels, hints, and traits on `AnswerButton`, `CategoryCard`, `QuestionCard`, `TimerBar` (with `.updatesFrequently` trait), `ResultView`, and `LeaderboardView`, supplemented by live speech feedback announcements for evaluations and timeouts (US-16).
- Mathematical WCAG 2.1 AA contrast audit: Emerald green feedback fill and passing badge (`#1B5E20`) achieve 7.87:1 contrast on white (exceeding WCAG AAA 7:1), Crimson red feedback fill and failing badge (`#B71C1C`) achieve 6.57:1 (WCAG AA 4.5:1).
- Solid High-Contrast Grade Badges & Adaptive Color Tokens: Academic grades in `LeaderboardView` and `ResultView` use solid pill capsules with white text (7.87:1 passing, 6.57:1 failing). Text, category breakdown tallies, scorecard icons, and progress indicators dynamically adapt via `Color.adaptiveSuccessText`, `Color.adaptiveErrorText`, `Color.adaptiveScoreIcon`, `Color.adaptiveStreakIcon`, and `Color.adaptiveSpeedIcon` (Light mode: `#1B5E20` / `#B71C1C` / `#B45309` / `#C2410C` / `#1D4ED8`; Dark mode: bright mint `#30D158`, bright coral red `#FF6961`, warm gold `#FBBF24`, tangerine `#FB923C`, and cyan sky `#38BDF8`), guaranteeing $\ge 5.58:1$ on light surfaces and $\ge 6.03:1$ to $10.39:1$ in Dark Mode.
- Storage capacity boundary hardening: `pruneRecordsWithBestProtection` sorts protected records by canonical `Comparable` ordering (`records.sorted(by: >).prefix(maxCapacity)`), ensuring all-time personal bests strictly survive even under extreme edge-case configurations (`maxCapacity: 1`).
- Local JSON catalog with 24 German questions in four categories; the interface is currently English.
- Validated question model, Fisher-Yates shuffled question and option order, and a separate quiz session state machine.
- Category and mixed rounds, immediate pedagogical answer explanation, manual next action, and result analytics.
- Results analytics and academic scorecard: Post-game `ResultView` with unified German university grading scale (`1.0` Sehr Gut to `5.0` Nicht Bestanden) matching standard linear grading (§ 15 APO), accuracy percentage, 4-metric grid (Score, Accuracy, Streak, Average Speed), category performance breakdown with mini progress bars, continuous session duration (`durationSeconds`), and decoupled active response speed (`averageResponseTime`).
- Strict domain invariant enforcement on `ScoreRecord` decoding preventing corrupted or impossible scores (e.g. negative values or correct answers exceeding total questions).
- Local persistence and high score tracking (`ScoreStoreProtocol`, `UserDefaultsScoreStore`): Thread-safe (`NSLock`) JSON serialization with ISO8601 timestamps, automatic quiz session saving upon completion, 100-record capacity cap with all-time personal best and category best retention protection (`pruneRecordsWithBestProtection`), and resilient recovery against corrupted payloads (ADR-07).
- Canonical tie-breaking (`ScoreRecord: Comparable`): Centralized four-tier ordering logic (score, accuracy, streak, completion date) ensuring 1:1 identity between the #1 leaderboard card and personal best metrics.
- Leaderboard & History screen (`LeaderboardView`, `LeaderboardViewModel`): Accessible modal sheet with dual view modes ("High Scores" vs "Recent Games"), category filtering chips, summary metrics bar (total games, average accuracy, personal best), podium rank badges, German grade indicators, empty state representation, and destructive history clearing with confirmation dialog.
- Multisensory feedback coordination: emerald green (`quizCorrectFeedback`) with `checkmark.circle.fill` and `.success` haptic for correct answers; crimson red (`quizIncorrectFeedback`) with `xmark.circle.fill` and `.error` haptic for errors; amber/crimson with `.warning` haptic on countdown timeout.
- Decoupled haptic architecture (`HapticFeedbackServiceProtocol`) retaining a thread-safe `UINotificationFeedbackGenerator` instance across calls (`prepare()` and `trigger()`), ensuring the Taptic Engine retains its prepared state without premature deallocation.
- Immediate touch debouncing and locking (`.disabled(isAnswerRevealed)` and `guard viewState == .playing`) preventing race conditions from rapid successive taps.
- Micro-interactions: `EvaluationButtonStyle` with press scaling (`0.98`) via `.easeOut(duration: 0.12)` and spring-damped view transitions in `QuizView`.
- High-frequency 10 Hz Combine reactive countdown timer (`0.1s` interval) on `@MainActor` with real-time delta compensation preventing RunLoop drift.
- Deterministic time-stepping API (`tickTimer(delta:)`) allowing instant, deterministic unit testing without asynchronous delays.
- Proportional chromatic shifts in `TimerBar` (`UrgencyPhase`: Normal $> 50\%$, Warning $20\%-50\%$, Critical $\le 20\%$) dynamically scaling across Easy (20s), Medium (15s), and Hard (12s) difficulty tiers.
- Application scene lifecycle (`ScenePhase`) anti-cheat protection: monotonic continuous clock (`systemUptime`) tracking across background transitions, elapsed time deduction upon resume, and immediate timeout on expired duration or device clock tampering.
- Reusable `CategoryCard`, `QuestionCard`, and `AnswerButton` components with 56 pt minimum touch targets and `.buttonStyle(.plain)` to prevent `ScrollView` gesture stealing.
- Programmatic answer-feedback VoiceOver announcements for correct, incorrect, and timeout states.
- Appearance selection stored through `@AppStorage`. Dedicated "Scores" button in HomeView header opening the Leaderboard modal sheet.

Question content is pre-seeded with 24 reference curriculum questions in `src/Resources/questions.json`. Users can expand the catalog by creating custom subjects and authoring questions directly in the app or importing JSON banks locally or via URL.

## Open and build

Open **`TrainYourBrain.xcodeproj` at the repository root**, select the **TrainYourBrain** scheme, and choose an iPhone or iPad simulator. Deployment target: iOS 17. The Xcode project uses Swift language mode 5.0; `Package.swift` declares tools version 5.9.

```sh
xcodebuild -project TrainYourBrain.xcodeproj -scheme TrainYourBrain \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The separate Swift Package contains the core and presentation code; it excludes the app entry point. Package tests can be run with `swift test --enable-code-coverage`. Native UI acceptance tests are in `ui-tests/TrainYourBrainUITests.swift` and run through the shared `TrainYourBrain` scheme with `xcodebuild test`.

## Source layout

```text
TrainYourBrain.xcodeproj/   Native app project
Package.swift              Core package and XCTest target
src/App/                   App entry and root routing
src/Models/                Questions, categories, sessions and score records
src/Services/              Question and haptic feedback service protocols and implementations
src/ViewModels/            Quiz state, haptics, and timer coordination
src/Views/Components/      AnswerButton, CategoryCard, QuestionCard, TimerBar, colors
src/Views/Screens/         HomeView, QuizView and ResultView
src/Resources/             Bundled questions
src/Tests/                 Existing XCTest suites
design/                    Design specifications and planned acceptance checks
docs/                      Sprint reports and versioning notes
```

## Evidence and limits

The package test suite executes 113 unit tests with 0 failures and measures **90.86%** instrumented production line coverage on macOS via `llvm-cov` (4,134 / 4,550 lines across all 22 production files), excluding tests and the app entry point. Native UI acceptance tests in `ui-tests/` verify category flows, mixed rounds, incorrect option marking, Dynamic Type XXXL, live countdown timeout, background-to-foreground lifecycle resumption, scorecard dashboard metrics, Leaderboard modal presentation/dismissal, and iPad 10.2" landscape/portrait ergonomic rotation with touch target bounds (8/8 tests passed in 204.101s on iPad 9th generation simulator).

Hardware qualification: While the software protocol and conditional compilation are 100% verified via automated tests, physical tactile vibration requires a physical iPhone device equipped with a Taptic Engine.

Accessibility and Ergonomics (Sprint 8): Evaluated and verified with formal mathematical WCAG 2.1 AA contrast calculations (7.87:1 on correct feedback and passing badges, 6.57:1 on incorrect feedback and failing badges), comprehensive VoiceOver accessibility labels/hints/traits, and 640 pt centered container layout for iPadOS regular size classes.

See the [Sprint 8 technical report](docs/sprint8_ipad_ergonomics_and_accessibility_report.md) for architectural details, contrast ratios, and layout specifications.

## Remaining roadmap

| Milestone | Planned work |
| --- | --- |
| **0.1.0** | Domain core, Codable models, bundled question service *(Completed)* |
| **0.2.0** | UI design system, color tokens, typography, 4pt grid *(Completed)* |
| **0.2.1** | Sprint 2 bugfixes: Play Again state reset, ScrollView gesture fix *(Completed)* |
| **0.3.0** | Modular UI components, iPad 9 acceptance, and tag release *(Completed)* |
| **0.4.0** | Reactive 10 Hz timer, proportional urgency, and anti-cheat lifecycle *(Completed)* |
| **0.4.1** | Sprint 4 maintenance patch: drift compensation, retrograde clock fix, UI timeout test *(Completed)* |
| **0.4.2** | Monotonic hardware clock anti-cheat, background/resume UI test, exact coverage reconciliation *(Completed)* |
| **0.5.0** | Multisensory feedback: visual cues, touch debouncing, and decoupled haptics *(Completed)* |
| **0.5.1** | Retained haptic generator lifecycle persistence, exact coverage reconciliation (91.45%), documentation alignment *(Completed)* |
| **0.6.0** | Results analytics, scorecard dashboard, German academic grading scale (1.0–5.0), continuous monotonic timing, category performance breakdown *(Completed)* |
| **0.6.1** | Sprint 6 maintenance patch: unified grade badge, active response speed decoupling, decoder invariants, and UI dashboard assertions *(Completed)* |
| **0.7.0** | Local persistence layer (`UserDefaultsScoreStore`), game history logging, high score ranking, and accessible Leaderboard modal view *(Completed)* |
| **0.7.1** | Sprint 7 maintenance patch: personal best retention protection, centralized 4-tier tie breaking *(Completed)* |
| **0.8.0** | Multi-device iPad layout, 640pt container, VoiceOver semantics *(Completed)* |
| **0.8.1** | Solid high-contrast grade badges, TimerBar trait, contrast formulas *(Completed)* |
| **0.8.2** | Dark Mode contrast fix, adaptive color tokens, 640pt landscape UI gameplay verification *(Completed)* |
| **0.8.3** | Category breakdown contrast hardening, adaptive progress pills, and VoiceOver protocol alignment *(Completed)* |
| **0.8.4** | Adaptive metric icons, full native iPad UI evidence verification, and accessibility audit polish *(Current)* |
| 0.9.0 | Verification and CI hardening |
| 1.0.0 | Final app release and completed academic deliverables |

The roadmap is a plan. Future milestones are not completion evidence. See [versioning](docs/versioning.md) and the [Sprint 2 incident report](docs/sprint2_incident_and_bugfix_report.md).

Maintainer: `scherenhaenden`
