# Sprint 8 Technical Report: Multi-Device iPad Ergonomics & VoiceOver Accessibility (`v0.8.0` / `v0.8.1` / `v0.8.2`)

**Maintainer:** `scherenhaenden`
**Project:** DLAMSD01 – Apple Mobile Solution Development I (Train-your-Brain iOS)  
**Target Release:** `v0.8.2` (Build `20261024.134000`)  
**Curriculum Stages:** Stage 63 (Adaptive Layout), Stage 64 (VoiceOver & Accessibility)  
**Architecture Reference:** ADR-10: Multi-Device-Optimierung und Barrierefreiheit/Apple%20Mobile%20Solution%20Development%20I%20(DLAMSD01)/06_Architekturentscheidungen_und_Variantenvergleich_ADR.md)

---

## 1. Executive Summary & Sprint Scope

Sprint 8 delivers comprehensive multi-device ergonomic adaptation for iPad (specifically the iPad 9th generation, 10.2" display) and deep VoiceOver accessibility integration across the entire application, fulfilling user stories **US-15** and **US-16**:

* **US-15 (iPad Ergonomic Adaptation):** *As an iPad user, I want the quiz interface to adapt seamlessly between portrait and landscape orientations with centered, readable layouts so that content does not stretch excessively across large screens.*
* **US-16 (VoiceOver Accessibility & WCAG Compliance):** *As a user with visual impairments, I want VoiceOver to clearly announce each category, question, timer urgency phase, answer state, and performance metric, backed by rigorous WCAG 2.1 AA contrast compliance.*
* **Residual Storage Hardening:** Fixed capacity pruning in `UserDefaultsScoreStore` and `InMemoryScoreStore` (`records.sorted(by: >).prefix(maxCapacity)`) to guarantee that all-time personal bests survive even under extreme edge-case configurations (e.g. `maxCapacity: 1`).
* **Maintenance & Refinement (`v0.8.1`):** High-contrast solid grade badges in `LeaderboardView` (7.87:1 for passing, 6.57:1 for failing), explicit `.updatesFrequently` trait in `TimerBar`, strict sRGB mathematical contrast formulas, and landscape UI acceptance test skeleton.
* **Dark Mode Contrast Hardening & Landscape Ergonomics Verification (`v0.8.2`):**
  - **ResultView Solid Badge Capsule:** Encapsulated academic grade in a solid pill capsule with pure white text (`.white`) on `Color.quizCorrectFeedback` (`#1B5E20`) / `Color.quizIncorrectFeedback` (`#B71C1C`), guaranteeing invariant **7.87:1** (AAA) and **6.57:1** (AA) contrast in all color appearances.
  - **Dynamic Adaptive Text Tokens:** Introduced `Color.adaptiveSuccessText` and `Color.adaptiveErrorText` in `Color+Adaptive.swift` using dynamic UIKit/AppKit providers. In Light Mode, resolves to `#1B5E20` ($CR = 7.87:1$ on white, $7.05:1$ on canvas) and `#B71C1C` ($CR = 6.57:1$ on white, $5.89:1$ on canvas). In Dark Mode, resolves to bright mint `#30D158` ($CR = 10.39:1$ on OLED black `#000000`, $8.42:1$ on card `#1C1C1E`) and bright coral red `#FF6961` ($CR = 7.45:1$ on OLED black, $6.03:1$ on card), completely eliminating the previous 2.67:1 / 2.16:1 Dark Mode contrast deficiency.
  - **UI Control Contrast Benchmark:** Corrected `#007AFF` on white card to exact sRGB contrast of **4.02 : 1** (exceeding the WCAG 3.0:1 benchmark for graphical UI controls).
  - **Complete Landscape UI Flow & 640pt Constraint Verification:** Expanded `testIPadLandscapeAndPortraitErgonomicAdaptation` to assert `category.frame.width <= 640.0` on iPad 10.2" landscape, complete an entire 6-question quiz round in landscape, verify the landscape `ResultView` header and action buttons, assert $\ge 44 \times 44$ pt touch targets, and return smoothly to the home menu.

---

## 2. Multi-Device Layout & Ergonomics Architecture (US-15)

### 2.1. The 640pt Centered Container Principle

The iPad (9th generation) features a 10.2-inch Retina display ($2160 \times 1620$ physical pixels at 264 ppi), translating to $1080 \times 810$ logical points in landscape and $810 \times 1080$ logical points in portrait. Both dimensions operate within the `.regular` horizontal size class.

Without layout constraints, unconstrained views stretch across the entire viewport ($> 1000$ pt), creating two major usability flaws:
1. **Excessive Line Length:** Exceeds the optimal reading measure recommended by Apple Human Interface Guidelines and typography standards ($50 \text{--} 75$ characters per line), causing ocular fatigue.
2. **Thumb Reach Discomfort:** On a physical tablet held with two hands, action buttons stretched to the edges require unnatural wrist re-positioning.

**Adopted Solution:**
Every major screen (`HomeView`, `QuizView`, `ResultView`, `LeaderboardView`) encapsulates its scrollable content in a centered container constrained to a maximum width of **640 pt**:

```swift
ScrollView {
    VStack(spacing: 20) {
        // Content hierarchy
    }
    .padding(16)
    .frame(maxWidth: 640)
    .frame(maxWidth: .infinity) // Centers horizontally in regular size classes
}
```

### 2.2. Orientation Adaptivity (Portrait & Landscape)

All views dynamically adapt between portrait and landscape modes:
* **Interactive Touch Targets:** All category cards, answer buttons, navigation chips, and dismissal buttons maintain a minimum interactive hit target of $\ge 44 \times 44$ pt (and $\ge 56$ pt for `AnswerButton`), remaining easily tappable in both orientations.
* **Scroll Resilience:** Dynamic Type scaling and landscape aspect ratios are accommodated within scrollable viewports, preventing clipping or truncating on compact heights.

---

## 3. VoiceOver Accessibility Architecture (US-16)

Every visual component implements explicit semantic accessibility contracts:

| Component | Accessibility Label | Traits | Accessibility Hint / Value |
| :--- | :--- | :--- | :--- |
| `AnswerButton` | `"Option [A-D]: [Text]"` | `.isButton`, `.isSelected` | Hint: `"Double tap to select this answer."` / Value: `"Correct answer"`, `"Incorrect answer"`, `"Selected"` |
| `CategoryCard` | `"[Title], [Count] questions. [Description]"` | `.isButton` | Hint: `"Double tap to start this quiz."` |
| `QuestionCard` | `"Question X of Y, Category: [Name], Difficulty: [Tier], time limit: [N] seconds. [Prompt]"` | Default | Compound reading of prompt and metadata |
| `TimerBar` | `"Time remaining: [N] seconds"` | `.updatesFrequently` | Value: `"[normal/warning/critical] urgency phase"` |
| `ResultView` | Metrics: `"[Title]: [Value]"`, Grade: `"Round Completed, Academic Grade: [Grade]"` | `.isStaticText` | Descriptive compound labels |
| `LeaderboardView` | `"Rank [N], [Category]. Score [N] pts, Grade [Grade], Accuracy [N]%, Streak [N], Speed [N]s"` | `.isStaticText` | Full transcript summary for each recorded game |

### 3.1. Live VoiceOver Announcements

In `QuizView`, when an answer is evaluated or the timer expires, the application issues a direct VoiceOver priority announcement via UIKit `UIAccessibility.post(notification:argument:)` / SwiftUI `AccessibilityNotification.Announcement`:

```swift
AccessibilityNotification.Announcement(
    "Correct. Your score is \(viewModel.currentScore) points."
).post()
```

---

## 4. Mathematical WCAG 2.1 AA Contrast Verification

Contrast ratios were audited against the official W3C Web Content Accessibility Guidelines (WCAG 2.1 definition for relative luminance $L$ and contrast ratio $CR = \frac{L_1 + 0.05}{L_2 + 0.05}$):

$$\begin{aligned}
L &= 0.2126 \cdot R_{\text{linear}} + 0.7152 \cdot G_{\text{linear}} + 0.0722 \cdot B_{\text{linear}} \\
\text{where } C_{\text{linear}} &= \begin{cases} \frac{C_{\text{sRGB}}}{12.92} & \text{if } C_{\text{sRGB}} \le 0.03928 \\ \left(\frac{C_{\text{sRGB}} + 0.055}{1.055}\right)^{2.4} & \text{otherwise} \end{cases}
\end{aligned}$$

| Element Pair | Foreground | Background | Computed Ratio | WCAG AA Benchmark | Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Correct Answer Button / Passing Badge | Pure White (`#FFFFFF`) | Emerald Green `RGB(27, 94, 32)` | **7.87 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Incorrect Answer Button / Failing Badge | Pure White (`#FFFFFF`) | Crimson Red `RGB(183, 28, 28)` | **6.57 : 1** | $\ge 4.5 : 1$ (AA) | **PASS (AA)** |
| Primary Text (Light Mode) | Black (`#000000`) | Grouped Background (`#F2F2F7`) | **18.82 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Timer Bar Normal / UI Controls | System Blue (`#007AFF`) | Card Background (`#FFFFFF`) | **4.02 : 1** | $\ge 3.0 : 1$ (UI Controls) | **PASS (AA)** |
| Adaptive Passing Text (Light Card) | Emerald Green (`#1B5E20`) | Card Background (`#FFFFFF`) | **7.87 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Adaptive Passing Text (Light Canvas) | Emerald Green (`#1B5E20`) | Canvas Background (`#F2F2F7`) | **7.05 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Adaptive Failing Text (Light Card) | Crimson Red (`#B71C1C`) | Card Background (`#FFFFFF`) | **6.57 : 1** | $\ge 4.5 : 1$ (AA) | **PASS (AA)** |
| Adaptive Passing Text (Dark Card) | Bright Mint (`#30D158`) | Dark Card (`#1C1C1E`) | **8.42 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Adaptive Passing Text (Dark OLED) | Bright Mint (`#30D158`) | Pure Black (`#000000`) | **10.39 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| Adaptive Failing Text (Dark Card) | Bright Coral Red (`#FF6961`) | Dark Card (`#1C1C1E`) | **6.03 : 1** | $\ge 4.5 : 1$ (AA) | **PASS (AA)** |
| Adaptive Failing Text (Dark OLED) | Bright Coral Red (`#FF6961`) | Pure Black (`#000000`) | **7.45 : 1** | $\ge 4.5 : 1$ (AA), $\ge 7.0 : 1$ (AAA) | **PASS (AAA)** |
| ResultView & Leaderboard Grade Badge | Pure White (`#FFFFFF`) | Solid Feedback Capsule | **7.87 : 1** / **6.57 : 1** | $\ge 4.5 : 1$ (AA) | **PASS (AAA / AA)** |

> [!NOTE]
> In both `LeaderboardView` and `ResultView`, the academic grade badge (`germanGrade.formattedGrade`) utilizes a solid pill capsule filled with `Color.quizCorrectFeedback` (`#1B5E20`) for passing grades and `Color.quizIncorrectFeedback` (`#B71C1C`) for failing grades, paired with crisp white text (`.white`). This guarantees invariant, spectrophotometrically proven contrast ratios of **7.87 : 1** (AAA) and **6.57 : 1** (AA) across both Light and Dark appearances.
> Furthermore, textual indicators that adapt dynamically (e.g., accuracy percentage and scorecard icons) utilize `Color.adaptiveSuccessText` and `Color.adaptiveErrorText`, guaranteeing $\ge 6.03 : 1$ contrast in Dark Mode and completely eliminating the prior 2.67:1 / 2.16:1 Dark Mode deficiency.
> Secondary text in SwiftUI uses dynamic UIKit/SwiftUI vibrancy (`UIColor.secondaryLabel`), which adapts per interface style; fixed body and semantic labels consistently rely on high-contrast semantic tokens.

---

## 5. Verification Evidence & Quality Metrics

### 5.1. Automated Unit Tests (Swift Package)

The test suite contains 9 dedicated tests in `Sprint8AccessibilityAndErgonomicsTests.swift`:
1. `testScoreStoreExtremeCapacity1PreservesBestScoreAcrossSubsequentGames` *(Residual edge-case fix)*
2. `testTimerBarAccessibilityValueAndUrgencyPhases`
3. `testAnswerButtonAccessibilityAttributesAcrossVisualStates`
4. `testCategoryCardAccessibilityLabelsAndDescriptions`
5. `testQuestionCardCombinedAccessibilityLabel`
6. `testResultViewAndScoreRecordAccessibilityData`
7. `testLeaderboardAccessibilitySubviews`
8. `testMathematicalWCAGContrastRatios`
9. `testLeaderboardGradeBadgeAndResultViewHighContrastFills` *(Expanded in v0.8.2 with full Light & Dark mode mathematical luminance assertions)*

**Execution Result:**
* **Total Package Tests:** **113 executed, 0 failures (100% success)**.

### 5.2. Native UI Acceptance Tests (iPad 9th Generation)

Executed via `xcodebuild test` on the native iPad (9th generation) simulator:
* `testCategoryRoundShowsFeedbackResultsAndCanReplay`
* `testMixedRoundStartsAndReturnsToTopics`
* `testIncorrectAnswerMarksTheCorrectOption`
* `testAccessibilityDynamicTypeKeepsCategoryStartAvailable`
* `testLiveCountdownReachesTimeoutAndEnablesAdvance`
* `testBackgroundAndForegroundResumeDeductsTimeAndPreservesGameplay`
* `testLeaderboardAndHistoryOpensAndDismisses`
* `testIPadLandscapeAndPortraitErgonomicAdaptation` *(Expanded in v0.8.2 to verify $\le 640$ pt ergonomic width constraint on iPad landscape, full 6-question gameplay into ResultView, $\ge 44 \times 44$ pt touch targets for Play Again and Return to Menu, and safe return to Home)*

---

### 5.3. Instrumented Code Coverage (`llvm-cov`)

Production line coverage measured across all 22 production source files:

| Production Source File | Executable Lines | Missed Lines | Line Coverage % | Executed Functions |
| :--- | :---: | :---: | :---: | :---: |
| `Models/AppTheme.swift` | 22 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/Difficulty.swift` | 31 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/Question.swift` | 128 | 24 | **81.25%** | 10 / 14 (71.4%) |
| `Models/QuizCategory.swift` | 37 | 0 | **100.00%** | 4 / 4 (100.0%) |
| `Models/QuizSession.swift` | 130 | 6 | **95.38%** | 17 / 18 (94.4%) |
| `Models/ScoreRecord.swift` | 225 | 17 | **92.44%** | 27 / 29 (93.1%) |
| `Services/HapticFeedbackService.swift` | 38 | 0 | **100.00%** | 16 / 16 (100.0%) |
| `Services/LocalQuestionService.swift` | 61 | 3 | **95.08%** | 6 / 6 (100.0%) |
| `Services/QuestionServiceProtocol.swift` | 12 | 3 | **75.00%** | 1 / 1 (100.0%) |
| `Services/ScoreStoreProtocol.swift` | 15 | 3 | **80.00%** | 1 / 2 (50.0%) |
| `Services/UserDefaultsScoreStore.swift` | 155 | 18 | **88.39%** | 23 / 26 (88.5%) |
| `ViewModels/LeaderboardViewModel.swift` | 73 | 2 | **97.26%** | 18 / 18 (100.0%) |
| `ViewModels/QuizViewModel.swift` | 292 | 20 | **93.15%** | 35 / 40 (87.5%) |
| `Views/Components/AnswerButton.swift` | 250 | 19 | **92.40%** | 17 / 18 (94.4%) |
| `Views/Components/CategoryCard.swift` | 239 | 9 | **96.23%** | 18 / 20 (90.0%) |
| `Views/Components/Color+Adaptive.swift` | 45 | 13 | **71.11%** | 8 / 11 (72.7%) |
| `Views/Components/QuestionCard.swift` | 141 | 1 | **99.29%** | 13 / 13 (100.0%) |
| `Views/Components/TimerBar.swift` | 116 | 22 | **81.03%** | 9 / 11 (81.8%) |
| `Views/Screens/HomeView.swift` | 521 | 43 | **91.75%** | 19 / 29 (65.5%) |
| `Views/Screens/LeaderboardView.swift` | 704 | 26 | **96.31%** | 38 / 46 (82.6%) |
| `Views/Screens/QuizView.swift` | 584 | 74 | **87.33%** | 12 / 22 (54.5%) |
| `Views/Screens/ResultView.swift` | 695 | 98 | **85.90%** | 14 / 21 (66.7%) |
| **TOTAL (All 22 Production Files)** | **4,514** | **401** | **91.12%** | **314 / 373 (84.2%)** |
