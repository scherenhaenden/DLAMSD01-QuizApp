# Sprint 2 – Technical Incident, Audit & Bugfix Report

**Project**: Train-your-Brain (iOS / iPadOS Quiz Application)  
**Module**: Apple Mobile Solution Development I (DLAMSD01) – IU International University of Applied Sciences  
**Milestone**: Sprint 2 (`v0.2.0`)  
**Methodology**: Test-Driven Development (TDD) with XCTest  

---

## 1. Executive Summary

During the development and testing of Sprint 2 (`v0.2.0`), rigorous quality gates, an external technical audit (Codex), and real-time simulator interaction testing revealed critical software and tooling issues. In adherence to academic integrity and professional software engineering principles, all incidents, root causes, corrective actions, and preventative measures are documented in this report.

---

## 2. Technical Incidents & Root Cause Analysis

### Incident 1: Simulator Window Unresponsiveness & Event Deferral Lock
* **Symptom**: Clicks inside the iOS Simulator / DeviceHub window produced no interaction; the user could neither trigger button actions, switch themes, nor return to the Home Screen (swipe-up / Home button failed to respond).
* **Investigation**:
  1. Process analysis (`ps aux`) revealed that `TrainYourBrain` (PID 66965) was in process state `SXs` (Mach kernel task suspended / stopped by debugger).
  2. Xcode's `debugserver` (PID 67019) was attached to the process and had intercepted a thread trap / pause (`svc #0x80`), freezing the application's main runloop.
  3. SpringBoard's event deferral subsystem (`_UIEventDeferringManager`, environment `keyboardFocus`) had granted the event token to `TrainYourBrain`. Because the process was suspended at the kernel level, it could not drain the event queue. Consequently, all pointer, click, and system gesture events were blocked.
  4. Inspection of booted devices revealed three concurrent runtimes running simultaneously (iPhone 15 Pro, iPhone 15 Pro Max, and iPad 9th Gen) alongside high-CPU streaming background tasks (`STExtractionService` at 42.5%, `diagnosticd`).
  5. The iPad simulator had an outdated Sprint 1 build (`v0.1.0`, build `20261022.1000`) installed rather than the updated Sprint 2 build.
* **Resolution**:
  1. Terminated `debugserver` (PID 67019) and the suspended process (PID 66965) via `SIGKILL`.
  2. SpringBoard executed a clean display identity reset, returning to the Home Screen.
  3. Shut down unnecessary simulator instances (`iPhone 15 Pro`, `iPhone 15 Pro Max`), leaving exclusively the primary target device: **iPad (9th generation)**.
  4. Freshly rebooted the iPad simulator to clear stale Mach ports and framebuffer locks.
  5. Built and deployed the updated Sprint 2 binary directly via `xcrun simctl install` and launched via `xcrun simctl launch` without debugger suspension (verified in active running state `Ss`).
* **Preventative Developer Guidelines**:
  - Do not leave detached LLDB sessions running across multiple booted simulators.
  - When testing interactive touch flows, launch the app directly or continue execution in LLDB (`c` / Continue) rather than remaining halted on thread traps.
  - Ensure the DeviceHub / Simulator window is brought to primary focus before clicking.

---

### Incident 2: SwiftUI Touch Recognition & Tap Cancellation in ScrollView
* **Symptom**: Clicking on category cards or domain selectors in `HomeView` failed to transition to the quiz.
* **Root Cause**:
  1. A custom `ButtonStyle` (`CardPressButtonStyle`) using `.scaleEffect` and drag-like animation states was nested inside a `ScrollView`. SwiftUI's internal `UIScrollViewPanGestureRecognizer` interpreted initial click movements as scroll drags, swallowing the touch events.
  2. Rounded rectangle stroke overlays (`.overlay(...)`) were intercepting hit testing because SwiftUI overlays receive pointer events unless explicitly disabled.
* **Resolution**:
  1. Replaced the custom gesture-sensitive `ButtonStyle` with `.buttonStyle(.plain)`.
  2. Defined explicit hit-testing geometry using `.contentShape(Rectangle())`.
  3. Added `.allowsHitTesting(false)` to all decorative stroke overlays to ensure touches pass directly to the underlying button.
  4. Embedded an explicit, unambiguous `[Start ▶]` visual control with $\ge 44 \times 44\,\text{pt}$ minimum tap target on each category card.
  5. Verified behavior through programmatic unit and view interaction tests in `ViewInteractionTests.swift`.

---

### Incident 3: CoreSimulator Runtime Storage & simctl Runtime Deletion
* **Objective**: Remove the bulky legacy iOS 17.5 simulator runtime (~8 GB disk footprint) to reclaim storage and test with modern active runtimes (iOS 27.0 / 27.1).
* **Observed Issues**:
  1. **CoreSimulator Daemon Access**: Initial queries from automated tools encountered connection restrictions with `CoreSimulatorService` and `simdiskimaged`, and permission constraints accessing simulator log files.
  2. **Device Deletion vs. Runtime Disk Image Deletion**: The command `xcrun simctl delete unavailable` only purges simulated device registrations marked unavailable, but does not delete installed runtime disk images from disk.
  3. **Runtime Family ID vs. Disk UUID Mismatch**: Attempting to delete using the runtime type bundle identifier (`com.apple.CoreSimulator.SimRuntime.iOS-17-5`) failed because `xcrun simctl runtime delete` requires the specific runtime volume UUID.
  4. **Correct UUID Identification**: Inspecting runtimes with `xcrun simctl runtime list` identified the exact iOS 17.5 runtime build (`21F79`) under UUID `0AD0E810-35D2-44B1-BAC0-4E113522C35E`. Verification via `--dry-run` confirmed targeted deletion.
  5. **Asynchronous Deletion Cycle**: Following execution, the runtime briefly entered state `Deleting` before macOS and CoreSimulator completed the unmount and deletion of the underlying APFS disk image.
* **Verified Final State**:
  - **iOS 17.5**: Successfully purged from system runtime catalog.
  - **Active Runtimes**: Modern platform runtimes (iOS 27.0 and 27.1) remain operational.
  - **Storage Reclaimed**: Total runtime image allocation dropped from **21.7 GB** to **14.8 GB**, reclaiming **6.9 GB** of disk space.
  - **Ergonomics & Touch Verification**: With the simulator updated to modern runtimes and the app built clean, the user confirmed all buttons, interactive controls, and theme switches are fully responsive.

---

## 3. Codex Audit Findings & Resolutions

| Priority | Finding | Code Location | Corrective Action & Verification |
| :--- | :--- | :--- | :--- |
| **High** | "Play Again" retained `selectedAnswerIndex` from previous game, disabling options immediately. | `QuizViewModel.swift` | Explicitly reset `selectedAnswerIndex = nil`, `questionIndex = 0`, `currentScore = 0`, `streak = 0` in `startQuiz()`. Verified in `Sprint2TDDRegressionTests.testPlayAgainResetsSelectedAnswerIndexAndGameState`. |
| **High** | Fisher-Yates algorithm discrepancy: docs described in-place algorithm with index tracking, but code used naive `shuffled()`. | `Question.swift` | Implemented true in-place Fisher-Yates shuffle with $O(1)$ index tracking: `fisherYatesShuffled(using:)`. Verified in `Sprint2TDDRegressionTests.testFisherYatesShufflePreservesCorrectAnswerTracking`. |
| **High** | Question model invariants allowed $<4$ options or empty strings. | `Question.swift` | Enforced strict `options.count == 4` and empty option rejection (`ValidationError.emptyOption`). Verified in `Sprint2TDDRegressionTests.testQuestionRequiresExactlyFourNonEmptyOptions`. |
| **High** | Premature completion claims and speculative future timestamps in documentation. | `README.md`, `docs/versioning.md` | Removed all speculative future dates (converted to `TBD`). Separated implemented Sprint 1–2 features from Sprint 3–10 roadmap. |
| **Medium** | State machine allowed advancing without answering and restarting active sessions. | `QuizSession.swift` | Guarded `advanceToNext()` with `guard case .questionAnswered = state` and `start()` with `guard state == .idle`. Verified in `Sprint2TDDRegressionTests`. |
| **Medium** | Dynamic `TimerBar` scaling was hardcoded to 15 seconds. | `QuizView.swift`, `TimerBar.swift` | Dynamically injected `totalTime: viewModel.currentQuestion?.difficulty.timeLimitSeconds ?? 15.0`. Verified in `ViewInteractionTests.testTimerBarProgressProportionForDifferentDifficulties`. |
| **Medium** | Accessibility contrast claims and iPad haptics discrepancy. | `accessibility_and_ergonomics.md` | Calculated exact WCAG 2.1 AA contrast ratios (OLED 21:1, Card 16.2:1). Explicitly documented that **iPad 9 lacks a Taptic Engine** (haptics are iPhone-only, iPad relies on audio-visual feedback). |
| **Medium** | "100% test pass" confused with "100% line coverage". | Academic draft, README | Measured exact line coverage via `llvm-cov`: **89.75% across entire codebase** (100% in `AppTheme`, `Difficulty`, `QuizCategory`, `QuestionCard`, `Color+Adaptive`; 97.2% in `ScoreRecord`; 93.4% in `QuizSession`; 95.1% in `LocalQuestionService`). |

---

## 4. Test Suite & Quality Gates

The test suite was expanded following strict TDD discipline:
* **Total Automated Tests**: **38 tests** (100% passing in 0.135s).
* **Test Classes**:
  1. `QuestionTests` (7 tests): Invariants, Codable, Fisher-Yates mapping.
  2. `QuizSessionTests` (6 tests): State transitions, scoring, streaks.
  3. `QuizViewModelTests` (4 tests): Asynchronous loading, error handling, session reset.
  4. `LocalQuestionServiceTests` (5 tests): JSON parsing, US-01 validation (24 questions).
  5. `ScoreRecordTests` (1 test): Percentage grading and university tier calculation.
  6. `AppThemeAndCategoryTests` (4 tests): Theme cases, display properties, category metadata.
  7. `Sprint2TDDRegressionTests` (5 tests): Play Again reset, strict 4 options, in-place Fisher-Yates, state machine defenses.
  8. `ViewInteractionTests` (6 tests): AnswerButton state changes, domain selection, Quick Play flow, timer bar scaling, scorecard rendering.

---

## 5. Scope Alignment & 10-Sprint Roadmap

To avoid scope creep while ensuring a fully functional, verifiable product at every milestone, the responsibilities across the 10 sprints are strictly bounded:

```
[v0.1.0] Sprint 1: Domain Core & Decodable Data Engine (DONE)
[v0.2.0] Sprint 2: Design System, Theming & Multi-Device Layout (CURRENT - GREEN)
[v0.3.0] Sprint 3: Modular SwiftUI Interactive Components & Dynamic Type
[v0.4.0] Sprint 4: Reactive Combine Countdown Timer (10 Hz) & Color-Shifting TimerBar
[v0.5.0] Sprint 5: Sensory Feedback Engine & Pedagogical Pause
[v0.6.0] Sprint 6: Academic Scorecard, Grading Schema & Round Analytics
[v0.7.0] Sprint 7: Local Leaderboard Persistence (UserDefaults & Codable)
[v0.8.0] Sprint 8: iPad 9 Ergonomics & VoiceOver Accessibility Audit
[v0.9.0] Sprint 9: Boundary Testing, Stress Testing & CI Hardening
[v1.0.0] Sprint 10: Final Code Freeze, Academic Evidence & Release Build
```
