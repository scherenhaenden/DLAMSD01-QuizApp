# Train Your Brain

Native SwiftUI quiz developed for DLAMSD01 Apple Mobile Solution Development I at IU.

## Current development stage

Version **0.4.1** (Build `20261023.134700`), Sprint 4 maintenance patch and defect resolution. High-frequency reactive timer (10 Hz), dynamic proportional urgency alerting in `TimerBar`, real-time drift compensation, and anti-cheat `ScenePhase` lifecycle management with backwards clock tampering protection are implemented and verified.

### Implemented

- Local JSON catalog with 24 German questions in four categories; the interface is currently English.
- Validated question model, Fisher-Yates shuffled question and option order, and a separate quiz session state machine.
- Category and mixed rounds, immediate pedagogical answer explanation, manual next action, and result analytics.
- High-frequency 10 Hz Combine reactive countdown timer (`0.1s` interval) on `@MainActor` with real-time delta compensation preventing RunLoop drift.
- Deterministic time-stepping API (`tickTimer(delta:)`) allowing instant, deterministic unit testing without asynchronous delays.
- Proportional chromatic shifts in `TimerBar` (`UrgencyPhase`: Normal $> 50\%$, Warning $20\%-50\%$, Critical $\le 20\%$) dynamically scaling across Easy (20s), Medium (15s), and Hard (12s) difficulty tiers.
- Application scene lifecycle (`ScenePhase`) anti-cheat protection: background exit timestamp tracking, elapsed time deduction upon resume, and immediate timeout on expired duration or retroactive clock tampering ($> 500\text{ms}$ backwards clock jumps).
- Reusable `CategoryCard`, `QuestionCard`, and `AnswerButton` components with 56 pt minimum touch targets and `.buttonStyle(.plain)` to prevent `ScrollView` gesture stealing.
- Programmatic answer-feedback VoiceOver announcements for correct, incorrect, and timeout states.
- Appearance selection stored through `@AppStorage`. Round history and high scores belong to Sprint 7.

Question content can be changed in `src/Resources/questions.json`. New categories also require updating `QuizCategory`. There is no question editor or import feature in the app.

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
src/Services/              Question service protocol and local JSON implementation
src/ViewModels/            Quiz state and timer coordination
src/Views/Components/      AnswerButton, CategoryCard, QuestionCard, TimerBar, colors
src/Views/Screens/         HomeView, QuizView and ResultView
src/Resources/             Bundled questions
src/Tests/                 Existing XCTest suites
design/                    Design specifications and planned acceptance checks
docs/                      Sprint reports and versioning notes
```

## Evidence and limits

The package test suite executes 67 unit tests with 0 failures and measures 92.1% instrumented production line coverage on macOS via `llvm-cov`, excluding tests and the app entry point. Native UI acceptance tests in `ui-tests/` verify category flows, mixed rounds, incorrect option marking, Dynamic Type XXXL, and live countdown timeout on iPad (9th generation).

See the [Sprint 4 technical report](docs/sprint4_reactive_timer_and_lifecycle_report.md) for architectural details, coverage breakdowns, and the technical incident retrospective.

## Remaining roadmap

| Milestone | Planned work |
| --- | --- |
| **0.1.0** | Domain core, Codable models, bundled question service *(Completed)* |
| **0.2.0** | UI design system, color tokens, typography, 4pt grid *(Completed)* |
| **0.2.1** | Sprint 2 bugfixes: Play Again state reset, ScrollView gesture fix *(Completed)* |
| **0.3.0** | Modular UI components, iPad 9 acceptance, and tag release *(Completed)* |
| **0.4.0** | Reactive 10 Hz timer, proportional urgency, and anti-cheat lifecycle *(Completed)* |
| **0.4.1** | Sprint 4 maintenance patch: drift compensation, retrograde clock fix, UI timeout test *(Current)* |
| 0.5.0 | Feedback animations and optional haptics |
| 0.6.0 | Extend and review the existing result screen and score calculations |
| 0.7.0 | Local result history and personal bests |
| 0.8.0 | iPhone/iPad accessibility and orientation checks |
| 0.9.0 | Verification and CI hardening |
| 1.0.0 | Final app release and completed academic deliverables |

The roadmap is a plan. Future milestones are not completion evidence. See [versioning](docs/versioning.md) and the [Sprint 2 incident report](docs/sprint2_incident_and_bugfix_report.md).

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
