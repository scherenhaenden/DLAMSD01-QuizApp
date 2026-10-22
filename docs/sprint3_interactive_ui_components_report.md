# Sprint 3 Technical Report: Core Interactive UI Components (`v0.3.0`)

> **Academic Technical Deliverable for DLAMSD01 (Apple Mobile Solution Development I)**  
> **Course:** DLAMSD01 – IU International University of Applied Sciences  
> **Maintainer:** `scherenhaenden`
> **Version Target:** `v0.3.0` | **Build Number:** `20261022.162811`  
> **Test Target:** iPad (9th generation, 10.2" Retina, iPadOS 27.0 Simulator `SIMULATOR-IPAD-9TH-GEN`)

---

## 1. Executive Summary & Sprint Objectives

The primary objective of **Sprint 3 (`v0.3.0`)** was to extract, modularize, and harden the core interactive presentation layer of the *Train-your-Brain* application in SwiftUI. While Sprint 1 focused on domain models and ingestion logic (`v0.1.0`), and Sprint 2 established the design system tokens and theme switching (`v0.2.0` / `v0.2.1`), Sprint 3 delivers production-grade atomic UI components with strict adherence to Apple's Human Interface Guidelines (HIG) and WCAG 2.1 AA accessibility standards.

### User Stories Addressed
* **US-05 (Ergonomic Touch Targets):**  
  *As a quiz player on both iPhone and iPad, I want large, unambiguous answer buttons ($\ge 56\,\text{pt}$ touch height) with continuous squircle corners and responsive visual feedback so that I can tap accurately even under time pressure.*
* **US-06 (Dynamic Type & Multiline Scaling):**  
  *As a user with enlarged system text sizes or Accessibility Dynamic Type enabled, I want answer choices and question prompts to wrap seamlessly across multiple lines without truncation (`...`), text overlap, or clipping.*

---

## 2. Component Engineering & Architectural Refactoring

### 2.1. `AnswerButton.swift` (Atomic Component)
* **Location:** `src/Views/Components/AnswerButton.swift`
* **Coverage:** **92.8%** (193 / 208 lines)
* **Key Capabilities:**
  1. **Visual State Machine (`VisualState` enum):**
     * `.idle`: Standard unselected card with subtle border (`Color.borderNeutral`), primary text, and circular badge (`A`, `B`, `C`, `D`).
     * `.selected`: Accent blue stroke (`Color.accentBlue`) with 10% translucent background tint and emphasized badge.
     * `.correct`: Accessible green (`Color.feedbackCorrect`) fill and stroke, accompanied by a checkmark icon.
     * `.wrong`: Accessible red (`Color.feedbackWrong`) fill and stroke, accompanied by an X-mark icon.
     * `.dimmed`: Reduced opacity ($0.45$) for non-selected options during answer evaluation, focusing cognitive attention on the resolution.
  2. **Ergonomic Touch Geometry:**
     * Implements `.frame(minHeight: 56)` to exceed the Apple HIG baseline of 44 pt and satisfy the 56 pt target established in `design/ui_guidelines_and_tokens.md`.
     * Styled with continuous squircle geometry: `RoundedRectangle(cornerRadius: 14, style: .continuous)`.
  3. **Zero Text Clipping / Multiline Resilience:**
     * Configured with `.fixedSize(horizontal: false, vertical: true)` and `.lineLimit(nil)`, allowing multiline prompts to expand vertically without bounds compression.
  4. **Hit-Testing Shielding:**
     * Decorator borders and overlays use `.allowsHitTesting(false)`, preventing gesture capture issues previously diagnosed in Sprint 2.
  5. **VoiceOver Accessibility:**
     * Consolidated element: `.accessibilityElement(children: .combine)`.
     * Explicit accessibility label: `"Option \(letter): \(text)"`.
     * Contextual hint indicating current state and interaction outcome.

### 2.2. `QuestionCard.swift` (Atomic Component)
* **Location:** `src/Views/Components/QuestionCard.swift`
* **Coverage:** **99.4%** (154 / 155 lines)
* **Key Capabilities:**
  1. **Difficulty Indicators & Time Badges:**
     * Chromatic difficulty pills (`Easy` in green, `Medium` in yellow/orange, `Hard` in purple/red) combined with active round countdown limits (`12s`, `15s`, `20s`).
  2. **Category Chips:**
     * Contextual SF Symbols mapped to each domain:
       * Software Engineering: `gearshape.2.fill`
       * Swift & Apple Platform: `swift`
       * Data Structures & Algorithms: `network`
       * Testing & Quality Assurance: `checkmark.shield.fill`
  3. **Typography & Readability:**
     * Question prompt formatted in `.title3.weight(.bold)` with dynamic line spacing (`4pt`) on elevated background canvas (`Color.cardBackground`).
     * Integrated screen-reader accessibility description combining category, difficulty, and prompt text.

### 2.3. `CategoryCard.swift` (New Standalone Component)
* **Location:** `src/Views/Components/CategoryCard.swift`
* **Coverage:** **100.0%** (202 / 202 lines)
* **Key Capabilities:**
  1. **Modular Extraction:** Decoupled card presentation from `HomeView.swift` to facilitate reuse across home, settings, and category review screens.
  2. **Dual-Mode Construction:**
     * Domain-specific mode: Initialized with a `QuizCategory` instance, displaying localized domain title, description, question count badge (`6 Questions`), and domain icon.
     * Mixed-play mode: Initialized with `.allTopics`, featuring high-contrast blue boundary highlight and aggregate count badge (`24 Questions (6 per Domain)`).
  3. **Decoupled CTA Interaction:**
     * Integrated `[Start ▶]` capsule button with min-width constraint ($72\,\text{pt}$) and `.buttonStyle(.plain)` to prevent tap conflict inside parent `ScrollView`.

### 2.4. `HomeView.swift` (Screen Refactoring)
* **Location:** `src/Views/Screens/HomeView.swift`
* **Coverage:** **90.2%** (899 / 997 lines)
* **Improvements:**
  * Clean declarative layout utilizing the extracted `CategoryCard` components.
  * Removal of legacy helper functions and obsolete gesture styles.
  * Preserved full adaptive layout for both compact (iPhone) and regular (iPad) size classes.

---

## 3. Test-Driven Development (TDD) Evidence

A new dedicated test suite [`src/Tests/Sprint3InteractiveUITests.swift`](src/Tests/Sprint3InteractiveUITests.swift) was authored prior to completing component integration, following the strict Red $\to$ Green $\to$ Refactor cycle.

### New Test Cases in `Sprint3InteractiveUITests`

| Test Method | Target Component | Verifications & Assertions |
| :--- | :--- | :--- |
| `testAnswerButtonStateResolution` | `AnswerButton` | Verifies correct visual state resolution (`idle`, `selected`, `correct`, `wrong`, `dimmed`) for all index combinations. |
| `testAnswerButtonErgonomicTouchTargetHeight` | `AnswerButton` | Asserts that minimum button height is strictly $\ge 56\,\text{pt}$ conforming to HIG / Sprint 2 specifications. |
| `testAnswerButtonAccessibilityStrings` | `AnswerButton` | Asserts that `accessibilityLabel` contains option letter and text, and `accessibilityHint` reflects evaluation states. |
| `testAnswerButtonRenderingWithLongText` | `AnswerButton` | Renders a multi-paragraph technical prompt to assert multiline wrapping without text clipping or exception. |
| `testQuestionCardMetadataAndDifficultyBadges` | `QuestionCard` | Verifies badge labels (`Easy`, `Medium`, `Hard`), category chip SF symbols, and accessibility label composition. |
| `testCategoryCardRenderingAndProperties` | `CategoryCard` | Validates title, subtitle, question count badge, and domain icon rendering for all 4 academic categories. |
| `testMixedDomainCardRendering` | `CategoryCard` | Asserts rendering of the mixed domain card, 24 questions badge, and selection boundary highlight. |

### Overall Test Suite Execution Metrics
* **Total Executed Tests:** **45 tests** across 6 test suites.
* **Failures:** **0 failures** (0 unexpected).
* **Execution Time:** **0.252 seconds**.
* **Framework:** Swift Package Manager / XCTest (`swift test --enable-code-coverage`).

---

## 4. Code Coverage Analysis

Code coverage was measured via LLVM coverage tools (`TrainYourBrain.json` generated from `swift test --enable-code-coverage`):

```text
=============================================================================
File                                | Covered / Total Lines  | Percentage
=============================================================================
AppTheme.swift                      | Lines:   22 /   22     | 100.0%
Difficulty.swift                    | Lines:   31 /   31     | 100.0%
QuizCategory.swift                  | Lines:   37 /   37     | 100.0%
CategoryCard.swift                  | Lines:  202 /  202     | 100.0%
Color+Adaptive.swift                | Lines:   15 /   15     | 100.0%
QuestionCard.swift                  | Lines:  154 /  155     |  99.4%
ScoreRecord.swift                   | Lines:   35 /   36     |  97.2%
LocalQuestionService.swift          | Lines:   58 /   61     |  95.1%
QuizSession.swift                   | Lines:   85 /   91     |  93.4%
ResultView.swift                    | Lines:  250 /  269     |  92.9%
AnswerButton.swift                  | Lines:  193 /  208     |  92.8%
HomeView.swift                      | Lines:  899 /  997     |  90.2%
QuizView.swift                      | Lines:  467 /  523     |  89.3%
QuizViewModel.swift                 | Lines:  112 /  132     |  84.8%
Question.swift                      | Lines:  104 /  128     |  81.2%
QuestionServiceProtocol.swift       | Lines:    9 /   12     |  75.0%
TimerBar.swift                      | Lines:   68 /   95     |  71.6%
=============================================================================
TOTAL PRODUCTION CODE COVERAGE      | Lines: 2741 / 3014     |  90.94%
=============================================================================
```

> **Target Exceeded:** Total production line coverage stands at **90.94%**, exceeding the academic requirement of $\ge 85\%$ and the stretch goal of $\ge 90\%$.

---

## 5. Visual Simulator Verification on Target Hardware

The updated application package (`TrainYourBrain.app`) was compiled with `xcodebuild` and deployed to the primary hardware target: **Apple iPad (9th generation)** simulator (OS 27.0, Device ID: `SIMULATOR-IPAD-9TH-GEN`).

### 5.1. Light Mode Verification
* **Screenshot File:** `ipad_sprint3_home_light.png`
* **Observations:**
  * Clean, off-white background with distinct white cards.
  * Squircles render with crisp borders (`#D1D5DB`).
  * High-contrast primary action button (`Start Mixed Quiz`) and domain category cards.
  * Category chips render with appropriate SF symbols.

### 5.2. Dark Mode Verification
* **Screenshot File:** `ipad_sprint3_home_dark.png`
* **Observations:**
  * True OLED black canvas (`#000000`) with elevated dark gray cards (`#1E222B`).
  * Category card text exhibits high contrast (white on dark), fully compliant with WCAG 2.1 AA (contrast ratio $\ge 7.0:1$).
  * Selection borders and primary button blue (`#0A84FF`) maintain vivid accessibility without glare.

---

## 6. Definition of Done (DoD) Checklist for Sprint 3

| DoD Requirement | Status | Verification Evidence |
| :--- | :---: | :--- |
| Modular `QuestionCard` component | ✅ Done | Implemented in `src/Views/Components/QuestionCard.swift`, 99.4% coverage. |
| Modular `AnswerButton` component with $\ge 56\,\text{pt}$ touch target | ✅ Done | Implemented in `src/Views/Components/AnswerButton.swift`, 56pt constraint verified. |
| Modular `CategoryCard` component | ✅ Done | Implemented in `src/Views/Components/CategoryCard.swift`, 100.0% coverage. |
| Multiline Dynamic Type wrapping | ✅ Done | Configured with `.fixedSize(horizontal: false, vertical: true)` and tested in unit tests. |
| Screen reader / VoiceOver integration | ✅ Done | `.accessibilityElement(children: .combine)` and contextual labels tested. |
| Automated XCTest suite expansion | ✅ Done | 45 tests passing in 0.252 seconds with zero failures. |
| Code coverage $\ge 90\%$ | ✅ Done | Total coverage measured at **90.94%** (2,741 / 3,014 lines). |
| Native Xcode Project Integration | ✅ Done | `TrainYourBrain.xcodeproj` builds cleanly with `** BUILD SUCCEEDED **`. |
| Simulator verification on iPad (9th gen) | ✅ Done | Deployed and verified in both Light and Dark mode with screenshots. |
| Clean Git commit and tagging | ✅ Done | Ready for merge to `master` and tag `v0.3.0`. |
