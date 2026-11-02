# Verifiable Execution & Coverage Evidence Summary (2026-10-30)

**Project:** Train-your-Brain (`v1.0.0`, Build `20261025.100000`)  
**Branch:** `fix/history-robustness-and-docs`  
**Date:** 2026-10-30  
**Maintainer:** `scherenhaenden`  

---

## 1. Automated SwiftPM Unit & Integration Test Evidence (152 / 152 Passed)

- **Command Executed:**
  ```bash
  swift test --enable-code-coverage
  ```
- **Target Platform:** `arm64e-apple-macos14.0` (Apple Silicon Host)
- **Archived Artifacts in this Directory:**
  - [`llvm_cov_report.txt`](./llvm_cov_report.txt): Tabular coverage report generated via `xcrun llvm-cov report` (`152 tests, 0 failures in 0.961s`).
  - [`llvm_cov_export_summary.json`](./llvm_cov_export_summary.json): Sanitized JSON coverage summary exported via `xcrun llvm-cov export --summary-only`.
  - [`SHA256SUMS.txt`](./SHA256SUMS.txt): SHA-256 checksums for the tracked summary files in this folder. *(Raw console logs and full `.xcresult` bundles are archived offline outside the public repository to avoid exposing local machine paths and device identifiers).*

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
- **Archived Artifact in this Directory:**
  - [`xcresult_12_uitests_summary.json`](./xcresult_12_uitests_summary.json): Native test result summary exported via `xcrun xcresulttool get test-results summary` (`result: Passed`, `passedTests: 12`, `failedTests: 0`, `skippedTests: 0`).

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

## 4. Technical Note on Runtime Warning: `Invalid frame dimension (negative or non-finite)`

- **Observation:** During XCUITest runs on the iPad (9th generation) Simulator, 4 occurrences of `Invalid frame dimension (negative or non-finite)` appear right after the first tap on a text field when the software keyboard is presented. All 12 tests pass without assertion failures.
- **Investigation:** All fixed `.frame(...)` modifiers in `StudyMaterialManagerView.swift` use positive constants (32/44 pt) or `maxWidth/minHeight`. In an isolated simulator test run with the three `ToolbarItemGroup(placement: .keyboard)` toolbars temporarily disabled, `testEditCustomQuestionContentAndDifficulty` completed with 0 warnings, indicating that the message originates from system keyboard-accessory toolbar layout on iPadOS rather than custom view geometry.
