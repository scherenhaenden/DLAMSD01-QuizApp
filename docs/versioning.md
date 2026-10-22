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
| **`0.2.0`** | Sprint 2: UI/UX Design System & Tokens | Design system in `design/`, semantic color tokens (Dark/Light), 4pt grid, 56pt touch targets, typography scale, and wireframes. *(In Progress)* |
| **`0.3.0`** | Sprint 3: Core Interactive UI Components | Production SwiftUI atomic components (`QuestionCard`, `AnswerButton`), Dynamic Type scaling, squircle borders, and category chips. |
| **`0.4.0`** | Sprint 4: Reactive Timer & State Machine | Combine 10 Hz countdown timer on `@MainActor`, dynamic `TimerBar` with chromatic shifts, pause/resume, and timeout penalty. |
| **`0.5.0`** | Sprint 5: Sensory Feedback & Haptics | 1.0s pedagogical pause with inline explanation, visual check/cross icons, tactile haptics via `UINotificationFeedbackGenerator`. |
| **`0.6.0`** | Sprint 6: Results Analytics & Scorecard | Post-game `ResultView`, mathematical accuracy percentage, German university grading scale translation, and category metrics. |
| **`0.7.0`** | Sprint 7: Persistence & High Scores | Lightweight persistence layer via `UserDefaults` + `Codable`, personal bests tracker (`LeaderboardView`), and state recovery. |
| **`0.8.0`** | Sprint 8: iPad 9 Ergonomics & Accessibility | iPad 9 (10.2") regular size class optimization (640pt max container), VoiceOver accessibility labeling, and WCAG 2.1 AA audit. |
| **`0.9.0`** | Sprint 9: Verification & CI Hardening | Boundary testing (0 questions, single question, rapid tapping), test coverage expansion ($\ge 90\%$), SwiftLint compliance. |
| **`1.0.0`** | Sprint 10: Final Academic Release | Final code freeze, production build generation, comprehensive screenshot evidence collection, and final submission release. |

### Tier 2: Internal Build Number (`CFBundleVersion`)
Uses **Monotonic Numeric Calendar Versioning** (`YYYYMMDD.HHmm`), satisfying granular timestamp tracking while complying 100% with Apple syntax:

* **Syntax:** `YYYYMMDD.HHmm`
* **Example:** `20261022.0950` (Build generated on October 22, 2026 at 09:50).
* **Properties:**
  * Strictly monotonically increasing (each subsequent compilation produces a higher integer value).
  * Validated against Apple App Store Connect and TestFlight verification rules.
  * Unambiguous correlation between code commits, simulator runs, and physical iPad testing sessions.

---

## 3. Git Tagging Conventions

To mark milestone releases in the Git repository, both identifiers are combined:

```bash
# Tag naming convention
v<SemVer>+<BuildNumber>

# Concrete release examples:
git tag -a v0.1.0 -m "Release 0.1.0 (Build 20261022.1000): Initial core logic and domain tests"
git tag -a v1.0.0 -m "Release 1.0.0 (Build 20261025.1830): Final submission candidate for IU examination"
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
