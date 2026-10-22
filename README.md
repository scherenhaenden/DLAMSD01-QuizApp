# Train-your-Brain (iOS Quiz App)

> **An interactive, pedagogical iOS quiz application engineered with Swift and SwiftUI.**

**Train-your-Brain** is a native iOS mobile application designed to reinforce factual knowledge and stimulate cognitive training through gamified learning. Developed as part of the **Apple Mobile Solution Development I (DLAMSD01)** module at **IU International University of Applied Sciences**, the application applies modern iOS engineering patterns, declarative UI with **SwiftUI**, and strict adherence to Apple's **Human Interface Guidelines (HIG)** and **Swift API Design Guidelines**.

The project is being developed across a disciplined 10-sprint agile lifecycle, providing a verifiable codebase alongside the accompanying academic project report (*Projektbericht*).

---

## 🚀 Features & Incremental Delivery

### 📱 Active Capabilities (Sprint 1, Sprint 2 & Sprint 3)
*   **Domain-Driven Core**: Clean DDD models (`Question`, `QuizCategory`, `Difficulty`, `ScoreRecord`, `QuizSession`) enforcing strict invariants (4 non-empty options, UUID tracking, validated correct answer mapping).
*   **True In-Place Fisher-Yates Randomization**: Algorithmic shuffling of answer choices and question orders tracking the correct index in $O(1)$ space during swaps.
*   **Local Decodable Datastore**: Resilient JSON parsing (`questions.json`, 24 verified questions across 4 academic domains) with bundle lookups and test fixtures.
*   **Design System & Dual Theming**: Complete Dark Mode and Light Mode support with OLED black (`#000000`) canvas, semantic elevated cards, and an in-app theme switcher (Auto / Light / Dark) persisted in `@AppStorage`.
*   **Modular Interactive Components**: Atomic presentation widgets (`QuestionCard`, `AnswerButton`, `CategoryCard`) engineered with continuous squircles, 56pt touch target minimums, and multiline Dynamic Type wrapping (`.fixedSize(horizontal: false, vertical: true)`).
*   **Reactive Game Loop & View State**: `@MainActor`-bound `QuizViewModel` coordinating `.idle`, `.loading`, `.playing`, `.answered`, and `.finished` states.
*   **Multi-Device Ergonomics**: Centered max-width constraints (550 pt / 640 pt) designed for comfortable one-handed use on iPhone and ergonomic reading on iPad (9th generation, 10.2").
*   **Verified by TDD**: 45 automated XCTest unit and view interaction tests achieving **90.94% line coverage**.

### 🗓 Planned Capabilities (Sprints 4 to 10 Roadmap)
*   **Sprint 4**: 10 Hz reactive Combine countdown timer and color-shifting `TimerBar`.
*   **Sprint 5**: Sensory feedback engine with 1.0s pedagogical feedback pause and iPhone tactile haptics (`UIImpactFeedbackGenerator`).
*   **Sprint 6**: Comprehensive post-game analytics scorecard and German university grading conversion (*Sehr Gut* to *Nicht Ausreichend*).
*   **Sprint 7**: Local persistent leaderboard and round history using `UserDefaults` and `Codable`.
*   **Sprint 8**: Dedicated physical iPad 9 (10.2") testing, landscape/portrait verification, and VoiceOver accessibility audit.
*   **Sprint 9**: Formal boundary tests, edge-case hardening, and CI workflow pipeline verification.
*   **Sprint 10**: Final code freeze, production release (`v1.0.0`), screenshot evidence collection, and *Projektbericht* synchronization.

---

## 🛠 Tech Stack

### iOS / iPadOS Client (`/src`)
*   **Language**: Swift 5.9+
*   **UI Framework**: SwiftUI (Declarative UI)
*   **Architecture**: Model-View-ViewModel (MVVM)
*   **State Management**: Observable State (`@Observable` / `@StateObject` & `@Published`)
*   **Persistence**: Foundation (`UserDefaults`, FileSystem JSON)
*   **Design Standards**: Apple Human Interface Guidelines (HIG)
*   **Testing**: XCTest Suite (Unit testing, edge-case coverage)
*   **IDE**: Xcode 15 / 16 (macOS)
*   **Target Platform**: iOS 17.0+ / iPadOS 17.0+ (Universal iPhone & iPad)
*   **Primary Physical Test Device**: **Apple iPad (9th generation)** (10.2" Retina display, A13 Bionic, iPadOS 17+)
*   **Simulated Test Devices**: iPhone 15 Pro, iPhone SE (3rd gen)

---

## 📂 Project Structure

```bash
├── src/                                  # 📱 Native iOS Application Source
│   ├── App/                              # App Lifecycle & Entry Point (@main)
│   ├── Models/                           # Domain Entities (Question, Category, QuizSession)
│   ├── ViewModels/                       # Observable Business Logic (QuizViewModel, ScoreViewModel)
│   ├── Views/                            # SwiftUI Views & Subcomponents
│   │   ├── Components/                   # Reusable UI widgets (AnswerButton, CardView, TimerBar)
│   │   ├── Screens/                      # Main screen views (HomeView, QuizView, ResultView)
│   │   └── Navigation/                   # NavigationStack & Coordinator logic
│   ├── Services/                         # Data layer (JSONLoader, ScoreManager, AudioHaptics)
│   ├── Resources/                        # Assets.xcassets, questions.json, Localized Strings
│   └── Tests/                            # XCTest Unit & Integration Test Suites
│
├── docs/                                 # 📄 Academic Deliverables & Specifications
│   ├── architecture/                     # Class diagrams, state charts, and wireframes
│   ├── requirements/                     # Requirements traceability matrix
│   └── report/                           # Projektbericht preparation and drafts
│
├── .gitignore                            # Swift / Xcode build exclusions
└── README.md                             # Project Documentation
```

---

## ⚙️ Getting Started

Follow these instructions to clone, build, and run the project in your local development environment.

### Prerequisites
*   **macOS Sonoma (14.0+)** or newer
*   **Xcode 15.0+** (with iOS 17 SDK)
*   **Git**

### 1. Clone the Repository
```bash
git clone https://github.com/scherenhaenden/DLAMSD01-QuizApp.git
cd DLAMSD01-QuizApp
```

### 2. Open in Xcode
1.  Navigate to the `src/` directory.
2.  Open the `.xcodeproj` file in **Xcode** (or open the root directory in Xcode).
3.  Allow Xcode to index the Swift project and resolve dependencies (if any).

### 3. Run the Application
1.  Select an active target scheme (e.g., `QuizApp`).
2.  Choose your execution destination:
    *   **Physical Device (iPad 9th Generation)**: Connect your iPad via USB or Wi-Fi. In Xcode, select **iPad (9th generation)** from the destination menu. Ensure Developer Mode is activated on the iPad (*Settings > Privacy & Security > Developer Mode*).
    *   **iOS / iPadOS Simulator**: Select **iPad (9th generation)** or **iPhone 15 Pro** from the simulator list.
3.  Press **Run** (`Cmd + R`) to compile, deploy, and launch.

### 4. Execute Automated Tests
To run the automated `XCTest` suite verifying domain logic, JSON decoding, and scoring algorithms:
*   Press **Test** (`Cmd + U`) in Xcode.
*   Inspect results in the **Test Navigator** (`Cmd + 6`).

---

## 🔍 Architecture & Design

### Model-View-ViewModel (MVVM)
The project rigorously enforces the **MVVM** pattern to decouple visual representation from game mechanics and data handling:

*   **Model**: Pure, immutable Swift structs (`Question`, `QuizCategory`, `ScoreRecord`) conforming to `Identifiable`, `Codable`, and `Hashable`.
*   **ViewModel (`QuizViewModel`)**: Acts as the single source of truth for the game loop. Orchestrates question sequencing, evaluates user inputs on the `@MainActor`, tracks timer ticks, and updates UI state reactively.
*   **View**: Composable SwiftUI views that bind to ViewModel properties. Views contain zero domain calculation logic, ensuring pure presentation and high previewability in Xcode Canvas.
*   **Services (`LocalQuestionService`)**: Encapsulates external I/O and JSON parsing, isolated behind protocol interfaces for straightforward mocking and dependency injection during testing.

### State Transitions (Finite State Machine)
The core quiz session progresses through well-defined operational phases:
1.  `Idle / Menu`: Selection of category and round configuration.
2.  `QuestionActive`: Rendering current prompt with active countdown timer.
3.  `AnswerEvaluated`: Brief interaction lock showing correct/incorrect answer states.
4.  `RoundSummary`: Aggregation of round metrics, high-score verification, and post-round actions.

---

## 🧪 Testing & Verification

The testing strategy validates responsiveness, business logic, and UI adaptability across multiple tiers:

### Target Device Verification Matrix
*   **Primary Hardware Target**: **Apple iPad (9th generation)**
    *   *Display*: 10.2-inch Retina display (2160 × 1620 resolution at 264 ppi).
    *   *SoC*: Apple A13 Bionic.
    *   *Validation Focus*: Large-canvas layout spacing, touch ergonomics for rapid button interaction, seamless orientation switching (Portrait $\leftrightarrow$ Landscape), and smooth 60 fps timer animations.
*   **Simulator Matrix**:
    *   **iPhone 15 Pro**: Compact size class verification, Dynamic Island clearance, and high-density rendering.
    *   **iPhone SE (3rd gen)**: Smallest supported screen constraint (4.7-inch) testing for text truncations or button overflow.

### Core Test Suites (`XCTest`)
*   **Decoding & Serialization**: Verifying that corrupted or missing JSON fields do not crash the application.
*   **Scoring Correctness**: Mathematical assertions checking percentage computations, streak bonuses, and zero-point handling.
*   **Edge Conditions**: Boundary evaluations for empty question lists, rapid repeated taps on options, and timer expirations.

---

## 🗺 Release Roadmap & Versioning Plan

The project adheres to a hybrid versioning scheme combining **Semantic Versioning (`CFBundleShortVersionString`)** for release maturity across 10 disciplined sprint cycles and **Calendar Versioning (`CFBundleVersion`)** for build-level chronological traceability:

### Version Numbering Principles (`MAJOR.MINOR.PATCH`)
* **MAJOR (`1.0.0`)**: Represents the finalized, feature-complete academic release prepared for IU examination submission.
* **MINOR (`0.X.0`)**: Incremented upon completing each of the **10 formal sprint milestones** delivering end-to-end architectural or user-facing capabilities.
* **PATCH (`0.X.N`)**: Incremented for intermediate iterations, bug fixes, documentation adjustments, test additions, or data expansions within a sprint (e.g., `v0.1.1` for question bank expansion from 12 to 24 questions).

### 10-Sprint Milestone Breakdown

| Version (SemVer) | Build Target (CalVer) | Milestone / Phase | Scope & Premeditated Deliverables | Status |
| :---: | :---: | :--- | :--- | :---: |
| **`v0.1.0`** | `20261022.120645` | Sprint 1: Architecture Core & Ingestion | • DDD domain entities (`Question`, `Category`, `Difficulty`, `ScoreRecord`)<br>• Local JSON decodable pipeline (`questions.json`, 24 questions)<br>• Base `QuizViewModel` state loop and 23 XCTest unit tests<br>• Native Xcode project and GitHub Actions CI workflow | Completed |
| **`v0.2.0`** | `20261022.140000` | Sprint 2: UI/UX Design System, Dark Mode & Tokens | • Design system specification (`design/` directory)<br>• Semantic color tokens (Light/Dark mode) & 4pt grid system<br>• Screen wireframes (Home, Active Quiz, Feedback, Results)<br>• Native Dark Theme implementation & multi-device guidelines | Completed |
| **`v0.2.1`** | `20261022.152326` | Sprint 2 Maintenance: Audit Fixes & TDD Hardening | • Bugfix: "Play Again" state reset & in-place Fisher-Yates $O(1)$ index tracking<br>• UI: Restored touch interaction in ScrollView via plain button style<br>• Invariants: Enforced 4 non-empty options & state machine defenses<br>• Tests: 38 automated tests (89.75% line coverage) & incident reporting | Completed |
| **`v0.3.0`** | `20261022.162811` | Sprint 3: Core Interactive UI Components | • Modular SwiftUI components (`QuestionCard`, `AnswerButton`, `CategoryCard`)<br>• High-contrast feedback states and continuous squircle geometry<br>• Dynamic Type scaling with multiline wrap without clipping<br>• Dedicated test suite (45 tests passing, 90.94% coverage) | Completed |
| **`v0.4.0`** | `TBD` | Sprint 4: Reactive Timer & State Machine | • Combine 10 Hz countdown timer on `@MainActor`<br>• Dynamic `TimerBar` with chromatic shift (Blue $\to$ Orange $\to$ Red)<br>• Pause/resume handling on app lifecycle transitions<br>• Automatic timeout penalty dispatch | Planned |
| **`v0.5.0`** | `TBD` | Sprint 5: Sensory Feedback & Haptics | • 1.0s pedagogical pause revealing explanation callout<br>• Visual validation icons (`checkmark.circle` / `xmark.circle`)<br>• Tactile feedback via `UINotificationFeedbackGenerator`<br>• Answer button double-tap debouncing lock | Planned |
| **`v0.6.0`** | `TBD` | Sprint 6: Results Analytics & Scorecard | • Post-game scorecard view (`ResultView`)<br>• Accuracy percentage computation and time-per-question metrics<br>• Academic grading scale conversion (German university tiers)<br>• Category-specific accuracy breakdown | Planned |
| **`v0.7.0`** | `TBD` | Sprint 7: Persistence & High Scores | • Lightweight persistence with `UserDefaults` and `Codable`<br>• Historical rounds tracking and personal bests (`LeaderboardView`)<br>• Session state restoration and empty-state fallbacks<br>• Reset and clear history utilities | Planned |
| **`v0.8.0`** | `TBD` | Sprint 8: iPad 9 Ergonomics & Accessibility | • iPad 9 (10.2") regular size class optimization (640pt max container)<br>• Full VoiceOver accessibility labeling and status announcements<br>• WCAG 2.1 AA color contrast compliance verification<br>• Dynamic Type testing with extreme accessibility font sizes | Planned |
| **`v0.9.0`** | `TBD` | Sprint 9: Verification & CI Hardening | • Boundary tests (0 questions, single question, rapid tapping)<br>• Test suite expansion reaching $\ge 90\%$ business logic coverage<br>• SwiftLint style validation and clean-up<br>• Xcode build diagnostics and release scheme validation | Planned |
| **`v1.0.0`** | `TBD` | Sprint 10: Final Release & Submission | • Final code freeze and production build generation<br>• Comprehensive screenshot evidence collection for iPad & iPhone<br>• Synchronization with academic *Projektbericht* chapters<br>• Final deliverable package for IU examination submission | Planned |

> For comprehensive architectural rationale, patch progression rules, and Xcode `Info.plist` mapping, consult [docs/versioning.md](docs/versioning.md).  
> For technical incident retrospectives, audit resolutions, and simulator debugging guidelines, consult [docs/sprint2_incident_and_bugfix_report.md](docs/sprint2_incident_and_bugfix_report.md).  
> For Sprint 3 atomic components, coverage report (90.94%), and simulator verification evidence, consult [docs/sprint3_interactive_ui_components_report.md](docs/sprint3_interactive_ui_components_report.md).

---

## 📜 Academic Deliverable & Credits

*   **Author**: scherenhaenden
*   **Course**: Apple Mobile Solution Development I (DLAMSD01)
*   **Degree Program**: B.Sc. Softwareentwicklung
*   **Institution**: IU International University of Applied Sciences
*   **Supervisor / Tutor**: IU Faculty Advisory

*Developed with Swift and passion.* 🍏
