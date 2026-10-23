# Versioning Strategy & Release Specification

> **Technical Versioning Specification for DLAMSD01 (Train-your-Brain Quiz App).**  
> Defines version naming standards, compatibility with Apple / Xcode build toolchains, and chronological traceability required by IU International University of Applied Sciences.

---

## 1. Analysis of Versioning Approaches

When designing the release and version management pipeline for a native iOS application within an academic degree project, two primary paradigms were evaluated:

### Approach A: Pure Calendar Versioning with Timestamps (`yyyy.MM.dd-HH.mm.sss`)
* **Concept:** Using the exact build compilation date and time as a unique identifier.
* **Advantages:**
  * Immediate chronological traceability: reveals at a glance when a specific build was compiled.
  * Direct structural alignment with IU examination submission naming conventions (`YYYYMMDD_Project_Submission_...`).
  * Mathematical impossibility of build identifier collisions across successive compilations.
* **Technical Constraints within the Apple / iOS Ecosystem:**
  * **Apple Syntax Restriction (`Info.plist`):** Apple mandates that the public marketing version (`CFBundleShortVersionString`) must consist **strictly of period-separated integers** (format `X.Y.Z`). Hyphens (`-`), alphabetic characters, and sub-second fractions (`.sss`) are rejected by Apple validation toolchains (`xcrun altool` and App Store Connect).
  * **Maturity Communication:** Timestamp strings do not express functional maturity levels (e.g. distinguishing an alpha prototype `0.1`, a feature-complete beta `0.8`, or an exam-submission candidate `1.0.0`).

### Approach B: Semantic Versioning (SemVer 2.0.0: `MAJOR.MINOR.PATCH`)
* **Concept:** The de facto software industry standard for signaling backward compatibility and release stability.
* **Advantages:**
  * Methodological clarity: academic evaluators immediately identify the software lifecycle stage.
  * Native compatibility with Xcode project build settings and Swift Package Manager version requirements.
* **Limitations:**
  * Does not inherently encode the exact build timestamp unless supplemented by secondary metadata.

---

## 2. Adopted Architecture: Two-Tier Hybrid Strategy (Apple + IU Standard)

To achieve both academic traceability and native Xcode compatibility, the project adopts a **two-tier hybrid versioning model** strictly adhering to Apple platform guidelines:

```
┌─────────────────────────────────────────────────────────────┐
│                       APP VERSIONING                        │
├──────────────────────────────┬──────────────────────────────┤
│  Marketing Version (SemVer)  │   Build Number (CalVer/Time) │
│  CFBundleShortVersionString  │   CFBundleVersion            │
│  e.g., "1.0.0"               │   e.g., "20261022.0950"      │
└──────────────────────────────┴──────────────────────────────┘
```

### Tier 1: Marketing / Public Version (`CFBundleShortVersionString`)
Uses **Semantic Versioning** (`MAJOR.MINOR.PATCH`) to communicate functional milestones in the user interface and academic deliverables across 10 disciplined sprints:

#### Semantic Progression Criteria (`MAJOR.MINOR.PATCH`)
- **`MAJOR` (Incrementing to `1.0.0`):**
  - Triggered exclusively for the final, feature-complete academic release prepared for IU examination submission.
- **`MINOR` (Incrementing `0.X.0`, e.g., `0.1.0` $\to$ `0.2.0` $\to$ `0.3.0`):**
  - Triggered upon completing a full sprint milestone that introduces an end-to-end user-facing capability, architectural layer, or formal subsystem.
- **`PATCH` (Incrementing `0.X.N` where $N \ge 1$, e.g., `0.1.1`, `0.2.1`):**
  - Triggered for intermediate iterations, hotfixes, refactorings, and maintenance commits within a sprint, specifically:
    1. **Data expansion or content fixes:** Expanding the question bank without altering schema (e.g., expanding `questions.json` from 12 to 24 questions resulted in patch release `0.1.1`).
    2. **Bug fixes & edge-case corrections:** Correcting visual glitches, timer edge cases, or button hit-testing on compact screens.
    3. **Documentation hotfixes:** Clarifications, markdown adjustments, and roadmap updates.
    4. **Test suite refactoring:** Adding edge-case unit assertions without altering public production APIs.
    5. **CI / build pipeline maintenance:** Modifying GitHub Actions YAML workflows or linter rules.

#### 10-Sprint Versioning Roadmap

| Version | Sprint / Milestone | Technical Scope & Deliverables |
| :---: | :--- | :--- |
| **`0.1.0`** | Sprint 1: Architecture Core & Ingestion | Base MVVM structure, `Codable` domain models, `questions.json` decoding (24 questions), and 23 XCTest unit tests. *(Completed)* |
| **`0.2.0`** | Sprint 2: UI/UX Design System & Tokens | Design system in `design/`, semantic color tokens (Dark/Light), 4pt grid, 56pt touch targets, typography scale, and wireframes. *(Completed)* |
| **`0.2.1`** | Sprint 2 Maintenance: Audit Fixes & TDD | Bugfix for "Play Again" state reset, in-place Fisher-Yates $O(1)$ tracking, ScrollView touch recognition, and strict 4 options invariant. *(Completed)* |
| **`0.3.0`** | Sprint 3: Core Interactive UI Components | Modular UI components merged (`AnswerButton`, `QuestionCard`, `CategoryCard`), native iPad 9 UI acceptance verified (4/4 passed), tag `v0.3.0` published. Package coverage: 51 tests, 91.07% coverage (2,385/2,619 lines). *(Completed)* |
| **`0.4.0`** | Sprint 4: Reactive Timer & State Machine | High-precision Combine 10 Hz countdown timer (`interval = 0.1s`) on `@MainActor`, dynamic proportional `TimerBar` chromatic shifts (`UrgencyPhase`: Normal $>50\%$, Warning $20\%-50\%$, Critical $\le 20\%$), anti-cheat `scenePhase` lifecycle deduction, timeout handling with streak reset. 64 tests, 91.88% line coverage (2,512/2,734 lines). *(Completed)* |
| **`0.4.1`** | Sprint 4 Maintenance: Drift & Anti-Cheat Patch | Real-time delta compensation eliminating RunLoop drift, anti-cheat protection against retroactive clock tampering (>500ms backwards skew triggers timeout), regression test suite (67 tests, 91.76% coverage), and native iPad 9 live timeout UI acceptance test. *(Completed)* |
| **`0.4.2`** | Sprint 4 Maintenance: Monotonic Clock & UI Lifecycle | Monotonic continuous hardware clock integration (`systemUptime`) closing device clock rewind loopholes, native UI acceptance for background/foreground lifecycle resumption on iPad 9 (6 tests passed), and empirical coverage reconciliation (69 tests, 91.71% line coverage). *(Completed)* |
| **`0.5.0`** | Sprint 5: Sensory Feedback & Haptics | Multisensory feedback subsystem: immediate Emerald Green/Crimson Red cues with colorblind redundant SF Symbols, touch debouncing (`.disabled(isAnswerRevealed)`), decoupled tactile haptics via `UINotificationFeedbackGenerator` (`HapticFeedbackServiceProtocol`), and native iPad 9 UI acceptance (6 tests passed). *(Completed)* |
| **`0.5.1`** | Sprint 5 Maintenance: Retained Haptic Lifecycle & Doc Reconciliation | Retained `UINotificationFeedbackGenerator` instance across lifecycle with `NSLock` thread safety ensuring preserved pre-warming readiness, empirical coverage reconciliation (79 tests, 91.45% line coverage across production files: 2,599/2,842 lines), documentation alignment, and native iPad 9 UI acceptance (6 tests passed). *(Completed)* |
| **`0.6.0`** | Sprint 6: Results Analytics & Scorecard | Post-game `ResultView` scorecard, official German university grading scale (1.0 to 5.0) matching IU examination regulations (`Prüfungsordnung`), 4-metric grid (Score, Accuracy, Streak, Average Speed), category performance breakdown with mini progress bars, and continuous monotonic elapsed duration tracking. 86 tests, 90.28% line coverage (3,048/3,376 lines across production files). *(Completed)* |
| **`0.7.0`** | Sprint 7: Persistence & High Scores | Lightweight persistence layer via `UserDefaults` + `Codable`, personal bests tracker (`LeaderboardView`), and state recovery. |
| **`0.8.0`** | Sprint 8: iPad 9 Ergonomics & Accessibility | iPad 9 (10.2") regular size class optimization (640pt max container), VoiceOver accessibility labeling, and WCAG 2.1 AA audit. |
| **`0.9.0`** | Sprint 9: Verification & CI Hardening | Boundary testing (0 questions, single question, rapid tapping), test coverage expansion ($\ge 90\%$), SwiftLint compliance. |
| **`1.0.0`** | Sprint 10: Final Academic Release | Final code freeze, production build generation, comprehensive screenshot evidence collection, and final submission release. |

### Tier 2: Internal Build Number (`CFBundleVersion`)
Uses **Monotonic Numeric Calendar Versioning** (`YYYYMMDD.HHmmss`) including date, hours, minutes, and seconds, recorded only when an actual build is executed and approved:

* **Syntax:** `YYYYMMDD.HHmmss`
* **Real Completed Example:** `20261022.120645` (Build generated on October 22, 2026 at 12:06:45).
* **Future Builds:** Explicitly marked as `TBD` until compilation occurs. No speculative or fictitious future timestamps are permitted.
* **Properties:**
  * Strictly monotonically increasing.
  * Validated against Apple App Store Connect and TestFlight verification rules.
  * Precise correlation down to the exact second between Git commits, simulator runs, and physical iPad testing sessions.

---

## 3. Git Tagging Conventions

To mark milestone releases in the Git repository, both identifiers are combined:

```bash
# Tag naming convention
v<SemVer>+<BuildNumber>

# Concrete release example:
git tag -a v0.1.0 -m "Release 0.1.0 (Build 20261022.120645): Initial core logic and domain tests"

# Milestone template for future completed sprints (recorded at build time):
# git tag -a v<SemVer> -m "Release <SemVer> (Build <YYYYMMDD.HHmmss>): <Scope Summary>"
```

---

## 4. Xcode Project Configuration (`Info.plist`)

Within target build settings (`project.pbxproj` / Target General Settings):

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>20261022.0950</string>
```

In the app footer or settings screen, the version string displays as:
```text
Train-your-Brain v1.0.0 (Build 20261022.0950)
```

---

## 5. Methodological Justification for the Projektbericht

In the **Implementation and Configuration Management** chapter of the academic project report, this architecture is justified formally:

> *"To manage software releases, a two-tier hybrid versioning model was implemented in strict accordance with Apple Human Interface Guidelines and App Store packaging standards. A semantic versioning scheme (SemVer) was assigned to `CFBundleShortVersionString` to classify lifecycle maturity (from initial prototype `0.1.0` to final delivery `1.0.0`), complemented by a monotonic calendar-based build number (`CFBundleVersion`, format `YYYYMMDD.HHmm`). This strategy guarantees absolute chronological traceability for each test build while fully respecting the syntax validation constraints of the iOS operating system."*
