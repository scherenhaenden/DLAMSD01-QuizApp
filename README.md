# Train Your Brain

Native SwiftUI quiz developed for DLAMSD01 Apple Mobile Solution Development I at IU.

## Current development stage

Version **0.3.0**, Sprint 3 in progress. The current branch contains modular UI components; final interaction and accessibility acceptance remains open. The academic Bericht is also a partial draft.

### Implemented

- Local JSON catalog with 24 German questions in four categories; the interface is currently English.
- Validated question model, shuffled question and option order, and a separate quiz session state machine.
- Category and mixed rounds, immediate answer explanation, manual next action, and a basic result screen.
- A one-second Combine timer; the 10 Hz timer and lifecycle work belong to Sprint 4.
- Reusable `CategoryCard`, `QuestionCard`, and `AnswerButton` components.
- Category cards start their round with one action. Displayed counts come from the question service rather than fixed 24/6 labels.
- Adaptive metadata layouts, multiline text, minimum 56 pt answer controls, and programmatic answer-feedback announcements. VoiceOver traversal and extreme Dynamic Type acceptance still require device checks.
- Appearance selection stored through `@AppStorage`. Round history and high scores are not persisted yet.

Question content can be changed in `src/Resources/questions.json`. New categories also require updating `QuizCategory`. There is no question editor or import feature in the app.

## Open and build

Open **`TrainYourBrain.xcodeproj` at the repository root**, select the **TrainYourBrain** scheme, and choose an iPhone or iPad simulator. Deployment target: iOS 17. The Xcode project uses Swift language mode 5.0; `Package.swift` declares tools version 5.9.

```sh
xcodebuild -project TrainYourBrain.xcodeproj -scheme TrainYourBrain \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The separate Swift Package contains the core and presentation code; it excludes the app entry point. Existing package tests can be run explicitly with `swift test --enable-code-coverage`. They are not an Xcode UI test target.

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

Before this continuation, commit `52a2e45` passed 45 tests in nine XCTest classes and an iOS Simulator build. Its macOS Swift Package coverage was 2,741/3,014 instrumented production lines (90.94%), excluding tests and the app entry point. Those figures do not measure real touch handling, VoiceOver navigation or layout clipping, and do not describe the subsequent untested edits.

See [the Sprint 3 report](docs/sprint3_interactive_ui_components_report.md) for the implementation and pending checks. Accessibility targets and coverage percentages are project choices, not additional requirements imposed by the IU quiz assignment.

## Remaining roadmap

| Milestone | Planned work |
| --- | --- |
| 0.3.0 | Complete component interaction and layout acceptance |
| 0.4.0 | 10 Hz timer, timeout and lifecycle handling |
| 0.5.0 | Feedback and optional haptics |
| 0.6.0 | Extend and review the existing result screen and score calculations |
| 0.7.0 | Local result history and personal bests |
| 0.8.0 | iPhone/iPad accessibility and orientation checks |
| 0.9.0 | Verification and CI hardening |
| 1.0.0 | Final app release and completed academic deliverables |

The roadmap is a plan. Future milestones are not completion evidence. See [versioning](docs/versioning.md) and the [Sprint 2 incident report](docs/sprint2_incident_and_bugfix_report.md).

Author: Edward Sergio José Flores Mogollón · B.Sc. Softwareentwicklung · IU.
