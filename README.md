# Train-your-Brain (iOS Quiz App)

> **An interactive, pedagogical iOS quiz application engineered with Swift and SwiftUI.**

**Train-your-Brain** is a native iOS mobile application designed to reinforce factual knowledge and stimulate cognitive training through gamified learning. Developed as part of the **Apple Mobile Solution Development I (DLAMSD01)** module at **IU International University of Applied Sciences**, the application applies modern iOS engineering patterns, declarative UI with **SwiftUI**, and strict adherence to Apple's **Human Interface Guidelines (HIG)** and **Swift API Design Guidelines**.

The project fulfills all requirements of the official IU academic assignment, providing a robust codebase alongside the accompanying project report (*Projektbericht*).

---

## 🚀 Features

### 📱 Core Gameplay & User Experience
Designed for intuitive interaction, immediate feedback, and cognitive engagement:

*   **Dynamic Question Flow**: Presenting randomized multiple-choice trivia and academic questions across varied categories and difficulty levels.
*   **Immediate Visual & Haptic Feedback**: Color-coded response indicators (green for correct, red for incorrect) paired with subtle tactile feedback (`UIImpactFeedbackGenerator`).
*   **Paced Challenge (Timer Mode)**: Configurable countdown timer per question to challenge time-critical decision-making.
*   **Comprehensive Scoreboard & Analytics**: Detailed performance metrics at round completion, including percentage accuracy, response velocity, and category breakdowns.
*   **High-Score Persistence**: Local record tracking using `UserDefaults`, ensuring personal achievements persist across app sessions.
*   **Adaptive Design & Accessibility**: Full support for Dark Mode, Dynamic Type text scaling, and high-contrast color palettes complying with WCAG and HIG standards.

### 🧩 Data & Content Engine
*   **Local Decodable Datastore**: Resilient JSON-based question bank parsed via Swift's `Codable` protocols with safe fallback handling.
*   **Fisher-Yates Randomization**: Algorithmic shuffling for both question sequences and answer choices to prevent pattern memorization while preserving correct index resolution.
*   **Extensible Schema**: Domain models designed to support multimedia prompts, custom categories, and future remote API synchronizations.

---

## 🛠 Tech Stack

### iOS Client (`/src`)
*   **Language**: Swift 5.9+
*   **UI Framework**: SwiftUI (Declarative UI)
*   **Architecture**: Model-View-ViewModel (MVVM)
*   **State Management**: Observable State (`@Observable` / `@StateObject` & `@Published`)
*   **Persistence**: Foundation (`UserDefaults`, FileSystem JSON)
*   **Design Standards**: Apple Human Interface Guidelines (HIG)
*   **Testing**: XCTest Suite (Unit testing, edge-case coverage)
*   **IDE**: Xcode 15 / 16 (macOS)
*   **Target Platform**: iOS 17.0+ (iPhone & iPad)

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
2.  Choose an iOS Simulator (e.g., **iPhone 15 Pro**) or a connected physical iOS device.
3.  Press **Run** (`Cmd + R`) to compile and launch.

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

The test suite covers critical core workflows:
*   **Decoding & Serialization**: Verifying that corrupted or missing JSON fields do not crash the application.
*   **Scoring Correctness**: Mathematical assertions checking percentage computations, streak bonuses, and zero-point handling.
*   **Edge Conditions**: Boundary evaluations for empty question lists, rapid repeated taps on options, and timer expirations.

---

## 🗺 Release Roadmap & Versioning Plan

The project adheres to a hybrid versioning scheme combining **Semantic Versioning (`CFBundleShortVersionString`)** for release maturity and **Calendar Versioning (`CFBundleVersion`)** for build-level chronological traceability:

| Version (SemVer) | Build Target (CalVer) | Milestone / Phase | Scope & Premeditated Deliverables | Status |
| :---: | :---: | :--- | :--- | :---: |
| **`v0.1.0`** | `20261022.1000` | Sprint 1: Architecture & Data Core | • Domain entities (`Question`, `Category`, `QuizSession`)<br>• Local JSON decodable pipeline (`questions.json`)<br>• Base `QuizViewModel` state loop<br>• Initial `XCTest` suite for data validation | Planned |
| **`v0.5.0`** | `20261023.1200` | Sprint 2: Core Gameplay UI | • Declarative SwiftUI interface (`QuizView`, `AnswerButton`)<br>• Real-time countdown timer (15s per question)<br>• Immediate visual (color-coded) & tactile feedback<br>• Question sequencing and answer verification | Planned |
| **`v0.8.0`** | `20261024.1500` | Sprint 3: Persistence & Flow Polish | • Final results screen (`ResultView`) with percentage analytics<br>• Local high-score persistence via `UserDefaults`<br>• NavigationStack flow (Menu $\leftrightarrow$ Quiz $\leftrightarrow$ Results)<br>• Dark Mode and Dynamic Type accessibility support | Planned |
| **`v1.0.0`** | `20261025.1800` | Sprint 4: Final Academic Release | • Code freeze & complete `XCTest` test suite execution<br>• Full compliance with Apple Human Interface Guidelines<br>• Evidence collection (screenshots & test logs)<br>• Final deliverable for IU Projektbericht submission | Planned |

> For comprehensive architectural rationale and Xcode `Info.plist` mapping, consult [docs/versioning.md](docs/versioning.md).

---

## 📜 Academic Deliverable & Credits

*   **Author**: Edward Sergio José Flores Mogollón
*   **Course**: Apple Mobile Solution Development I (DLAMSD01)
*   **Degree Program**: B.Sc. Softwareentwicklung
*   **Institution**: IU International University of Applied Sciences
*   **Supervisor / Tutor**: IU Faculty Advisory

*Developed with Swift and passion.* 🍏
