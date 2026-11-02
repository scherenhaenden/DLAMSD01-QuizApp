# Verifiable Execution & Coverage Evidence Summary (2026-10-30)

**Project:** Train-your-Brain (`v1.0.0`, Build `20261025.100000`)  
**Branch:** `master`  
**Date:** 2026-10-30 (Consolidated: 2026-11-02)  
**Maintainer:** `scherenhaenden`  

---

## 1. Automated SwiftPM Unit & Integration Test Evidence (152 / 152 Passed)

- **Command Executed:**
  ```bash
  swift test --enable-code-coverage
  ```
- **Target Platform:** `arm64e-apple-macos14.0` (Apple Silicon Host)
- **Tracked Sanitized Artifacts:**
  - [`swiftpm_test_152_passed.log`](./swiftpm_test_152_passed.log): Full test execution log (`152 tests, 0 failures in 0.961s`). Sanitized to replace local machine paths with relative paths.
  - [`llvm_cov_report.txt`](./llvm_cov_report.txt): Tabular coverage report generated via `xcrun llvm-cov report`.
  - [`llvm_cov_export_summary.json`](./llvm_cov_export_summary.json): Sanitized JSON coverage summary exported via `xcrun llvm-cov export --summary-only`.
  - [`SHA256SUMS.txt`](./SHA256SUMS.txt): SHA-256 checksums covering all sanitized files in this directory.

### Summary of `llvm-cov` Metrics (26 Production Files in `src/`):
- **Lines:** `90.84%` (`7,862 / 8,655` lines executed, `793` missed)
- **Functions:** `89.12%` (`639 / 717` functions executed, `78` missed)
- **Execution Regions:** `89.10%` (`1,406 / 1,578` regions executed, `172` missed)
- **Branches:** `0 / 0` (Not instrumented by default SwiftPM profile; execution regions measure AST blocks/expressions entered, not combinatorial branch or full path coverage).
- **Per-File Minimum:** All 26 production files exceed the internal project quality goal of `>= 80.0%` across Lines, Functions, and Execution Regions (`StudyMaterialManagerView.swift`: `81.27%` Lines, `81.99%` Functions, `81.23%` Regions).

---

## 2. Native XCUITest End-to-End (E2E) Suite Evidence (12 / 12 Passed)

- **Command Executed:**
  ```bash
  xcodebuild test \
    -project TrainYourBrain.xcodeproj \
    -scheme TrainYourBrain \
    -destination 'platform=iOS Simulator,name=iPad (9th generation)' \
    -only-testing:TrainYourBrainUITests/TrainYourBrainUITests
  ```
- **Target Simulator:** `iPad (9th generation)` (`iPad12,2`, iPadOS Simulator 27.0)
- **Tracked Sanitized Artifacts:**
  - [`xcodebuild_12_uitests_ipad9.log`](./xcodebuild_12_uitests_ipad9.log): Complete console log of all 12 E2E test methods. Sanitized to replace local user paths with relative paths and simulator UDIDs with generic placeholders.
  - [`xcresult_12_uitests_summary.json`](./xcresult_12_uitests_summary.json): Native test result summary exported via `xcrun xcresulttool get test-results summary` (`result: Passed`, `passedTests: 12`, `failedTests: 0`, `skippedTests: 0`).
  - [`UITests_12_iPad9_Sim.xcresult.tar.gz`](./UITests_12_iPad9_Sim.xcresult.tar.gz): Sanitized native `.xcresult` bundle (4.2 MB). System diagnostics containing raw binary logs were stripped to protect machine privacy while fully preserving test activities, summaries, and all 19 native screenshots. *(The unredacted original bundle remains in the private university submission archive).*
  - [`experiment_no_keyboard_toolbar.log`](./experiment_no_keyboard_toolbar.log): Isolated test run verifying that removing `ToolbarItemGroup(placement: .keyboard)` eliminates the system frame warnings.

### 12 Verified XCUITest Methods (`ui-tests/TrainYourBrainUITests.swift`):
1. `testAccessibilityDynamicTypeKeepsCategoryStartAvailable`
2. `testBackgroundAndForegroundResumeDeductsTimeAndPreservesGameplay`
3. `testCategoryRoundShowsFeedbackResultsAndCanReplay`
4. `testEditCustomQuestionContentAndDifficulty` *(Mandatory edit assertion without `if`; updates both prompt text and difficulty `Medium` $\to$ `Hard`; verifies in list; terminates & relaunches app without `--reset-state`; verifies persistence of both updated prompt and `Hard` difficulty after restart)*
5. `testIncorrectAnswerMarksTheCorrectOption`
6. `testIPadLandscapeAndPortraitErgonomicAdaptation`
7. `testLeaderboardAndHistoryOpensAndDismisses`
8. `testLiveCountdownReachesTimeoutAndEnablesAdvance`
9. `testMixedRoundStartsAndReturnsToTopics`
10. `testMultipleCustomSubjectsQuestionIsolation` *(Uses `studyMaterial.categoryFilterPicker` with strict `XCTAssertTrue` / `XCTAssertFalse` isolation checks between custom subjects)*
11. `testQuestionSaveValidationAndErrorAlerts` *(Verifies all 4 modal validation alerts and their exact error strings: empty prompt, missing options, duplicate options, and empty pedagogical explanation; followed by valid save and mandatory deletion verification)*
12. `testStudyMaterialManagerSheetCanOpenAndClose`

---

## 3. Physical Hardware Verification Summary

- **Target Hardware:** Physical iPad (9th generation, Model `iPad12,1`, iPadOS `27.0.1` Build `24A446`).
- **Verification Summary (2026-11-02):** Build `1.0.0` (`20261025.100000`) was deployed and verified on physical iPad (9th generation) hardware via an independent user test plan, confirming that custom question authoring and saving operate as expected on-device.

---

## 4. Technical Notes on Observed Test Logs & Warnings

To ensure 100% academic transparency, all non-fatal runtime warnings observed during testing are explicitly recorded:
1. **`Invalid frame dimension (negative or non-finite)` (XCUITest):**  
   4 occurrences appear in `xcodebuild_12_uitests_ipad9.log` immediately when the iPadOS software keyboard is presented on a text field. An isolated experiment (`experiment_no_keyboard_toolbar.log`) demonstrated that temporarily removing the keyboard accessory toolbar eliminated all 4 warnings, confirming that the notice is emitted by UIKit's internal keyboard accessory layout on iPadOS rather than custom view frames.
2. **`Accessing State's value outside of being installed on a View` (SwiftPM):**  
   Observed in `ViewInteractionTests.swift` when headless unit tests instantiate SwiftUI `State` properties directly in isolated assertions without an active hosting window. This is an expected artifact of unit-testing standalone view structs outside a running UI application context.
3. **Simulator Diagnostics Timeout (XCUITest):**  
   At the conclusion of the automated suite, `xcodebuild` records a timeout while collecting background daemon diagnostics (`simctl_diagnostics`). All 12 test assertions finished with `** TEST SUCCEEDED **` prior to this diagnostic step.
