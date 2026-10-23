# Train Your Brain

Native SwiftUI quiz developed for DLAMSD01 Apple Mobile Solution Development I at IU.

## Current development stage

Version **0.3.0**, Sprint 3 implementation merged to `master` by PR #8. The follow-up branch `test/sprint-3-ui-acceptance` adds native XCTest UI acceptance and CI coverage; it is not yet a release. There is no 0.3.x Git tag yet.

### Implemented

- Local JSON catalog with 24 German questions in four categories; the interface is currently English.
- Validated question model, shuffled question and option order, and a separate quiz session state machine.
- Category and mixed rounds, immediate answer explanation, manual next action, and a basic result screen.
- A one-second Combine timer; the 10 Hz timer and lifecycle work belong to Sprint 4.
- Reusable `CategoryCard`, `QuestionCard`, and `AnswerButton` components.
- Category cards start their round with one action. Displayed counts come from the question service rather than fixed 24/6 labels.
- Adaptive metadata layouts, multiline text, minimum 56 pt answer controls, and programmatic answer-feedback announcements. UI automation checks category and mixed flows, feedback, results, replay, 56 pt answer height, and Dynamic Type XXXL. VoiceOver traversal, timeout UI, broader device sizes, and Light/Dark review remain separate checks.
- Appearance selection stored through `@AppStorage`. Round history and high scores are not persisted yet.

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

The 0.3.0 package baseline passed 50 Swift Package tests. The follow-up branch adds one accessibility-state regression; its package suite passes 51 tests and measures 2,385/2,619 instrumented production lines (91.07%) on macOS, excluding tests and the app entry point. The four-test iPad 9 UI run passed and captured XCTest attachments. CI for that follow-up and its merge are still pending. These measurements do not prove spoken VoiceOver traversal, timeout presentation, or every device/layout combination.

See [the Sprint 3 report](docs/sprint3_interactive_ui_components_report.md) for the implementation and pending checks. Accessibility targets and coverage percentages are project choices, not additional requirements imposed by the IU quiz assignment.

## Remaining roadmap

| Milestone | Planned work |
| --- | --- |
| 0.3.0 | Sprint 3 implementation merged; close with UI acceptance, CI, and release traceability |
| 0.4.0 | 10 Hz timer, timeout and lifecycle handling |
| 0.5.0 | Feedback and optional haptics |
| 0.6.0 | Extend and review the existing result screen and score calculations |
| 0.7.0 | Local result history and personal bests |
| 0.8.0 | iPhone/iPad accessibility and orientation checks |
| 0.9.0 | Verification and CI hardening |
| 1.0.0 | Final app release and completed academic deliverables |

The roadmap is a plan. Future milestones are not completion evidence. See [versioning](docs/versioning.md) and the [Sprint 2 incident report](docs/sprint2_incident_and_bugfix_report.md).

Maintainer: `scherenhaenden`
