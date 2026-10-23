# Sprint 3 component implementation and remaining acceptance

Course: DLAMSD01 Apple Mobile Solution Development I
Maintainer: `scherenhaenden`
Working version: 0.3.0
Status: in progress; this report records implementation, not final acceptance.

## Handoff and baseline

Development continued on `feat/sprint-3-interactive-ui-components` after commit `52a2e45`. The existing report had treated component construction tests as proof of layout and accessibility compliance. Those claims have been narrowed to the evidence actually available. The academic Bericht remains a draft through the current development stage.

The baseline contains `QuestionCard`, `AnswerButton` and the extracted `CategoryCard`. The existing package has 45 XCTest methods in nine classes. A saved macOS run of the baseline passed all 45 methods and reported 2,741/3,014 instrumented production lines covered (90.94%). A separate baseline iOS Simulator build succeeded. These historical values are not measurements of the continuation changes.

## Continuation changes

### Direct category actions and catalog metadata

`HomeView` now starts a category or mixed round with one action. There is no select-then-tap-again behavior. The Start pill belongs to one card button, avoiding nested controls. Its accessibility hint describes the same action.

The duplicate mixed-round action was removed; the `All Topics (Mixed)` card is the single mixed-round entry point. Empty category cards show “No questions available” and remain disabled.

`QuizViewModel.loadQuestionCatalog()` loads catalog counts separately from the active session. The home screen uses the total and per-category counts, so a valid content change no longer requires editing hardcoded 24/6 labels. Catalog load errors provide a reload action. Loading metadata does not start a round or its timer. A failed round load can retry the same category, or return to topics explicitly.

### Components and text layout

`CategoryCard` no longer truncates its description after two lines. The count and Start label move to separate rows for accessibility text sizes. Appearance selection uses a labelled menu rather than three horizontally competing controls.

`QuestionCard` falls back from a horizontal metadata row to stacked badges when space is insufficient, and always stacks at accessibility text sizes. Its single accessibility label includes category, difficulty, time limit, question number and prompt.

`AnswerButton` retains the five visual states and minimum 56 pt height. The option badge scales with text. Correct and incorrect answers use deep solid feedback fills with white text and check/X indicators; the selected state keeps a subtle accent tint. Text is not shrunk to make enlarged content fit. Negative or out-of-range public option indices use a fallback badge rather than indexing the letter array. The question, answer, and metadata styles now follow the typography tokens.

When an answer is evaluated, `QuizView` posts a SwiftUI accessibility announcement with correctness, the correct answer when needed, and the updated score. Timeout announcements also identify the correct answer.

### Answer action boundary

`QuizViewModel.selectAnswer(at:)` rejects an invalid option index before stopping the timer or changing presentation state. A malformed action therefore leaves the current question active rather than showing feedback for an answer the session rejected.

## Acceptance status

| Criterion | Current evidence | Remaining work |
| --- | --- | --- |
| Standalone components | Source implementation present | Review the installed continuation build |
| One-action category start | Home and card actions aligned in source | Operate each card on iPhone and iPad |
| Counts reflect data | Metadata read through the injected service | Check an altered catalog and load error recovery |
| 56 pt answer target | Minimum-height constraint present | Device hit testing and enlarged text review |
| Large text | Stacked metadata and multiline layout implemented | Small-screen and accessibility-size screenshots |
| Screen reader descriptions | Explicit labels and hints present | VoiceOver traversal and announcement review |
| Feedback readability | White on `#1B5E20` computes to 7.87:1; white on `#B71C1C` to 6.57:1 | Review rendered states in Light and Dark appearance |
| Screen reader feedback | Correct/incorrect/timeout announcements are implemented in source | VoiceOver traversal, focus order and announcement review |
| Automated checks | The current package tree was tested on 23 October 2026: 48 tests passed, including three new ViewModel regressions | Runtime interaction, accessibility and layout checks remain open |
| Release | Working version stays 0.3.0 | No final acceptance, merge or release tag yet |

## Scope boundaries

The timer still ticks once per second. Lifecycle handling and a 10 Hz timer remain Sprint 4 work. Haptics, saved result history and final result analytics are outside this component continuation. No universal WCAG compliance, proven learning gain, full TDD history, or final project completion is claimed.

The build identifier is updated only for an actual new build. Detailed continuation build output is recorded separately after compilation.

## Technical references

- [Apple ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits) describes choosing a layout that fits the available axes.
- [Apple DynamicTypeSize isAccessibilitySize](https://developer.apple.com/documentation/swiftui/dynamictypesize/isaccessibilitysize) identifies accessibility text sizes for the stacked layout.
- [Apple AccessibilityNotification.Announcement](https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement) documents posting assistive-technology announcements.

## Continuation build evidence on 22 October 2026

- Marketing version: `0.3.0`.
- Earlier build: `20261022.180310` completed and launched on an iPad (9th generation), iPadOS 27.0 simulator. Its captured Home screen showed 24 questions and six questions for visible topics.
- Interactive review build: `20261022.202425` was installed on the iPad 9 simulator. Category and mixed rounds both started; correct and incorrect answers displayed their explanation and next action. The visual review showed SwiftUI dimming the disabled feedback buttons, so the final source adds a custom button style to retain the specified contrast.
- Latest build: `20261022.202656` (Europe/Berlin), built with Xcode 27 against the iOS 27.1 Simulator SDK.
- Command: `xcodebuild -quiet -project TrainYourBrain.xcodeproj -scheme TrainYourBrain -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dlamsd01-sprint3-final/DerivedData CURRENT_PROJECT_VERSION=20261022.202656 CODE_SIGNING_ALLOWED=NO build`.
- Result: exit code `0` (successful build). Xcode emitted a supported-destination warning because this scheme has no declared supported platform, and a metadata-extraction warning because the app does not depend on AppIntents.framework.
- Build `20261022.202656` has not been installed or launched after the continuation edits. Full-round interaction, accessibility font-size matrix, rendered feedback review and VoiceOver traversal remain pending.
- Changes remain local on the existing Sprint 3 branch; no merge or release tag was created.

## Verification of the continuation tree on 23 October 2026

The checkout was tested after adding three targeted regressions to `QuizViewModelTests`:

- Catalog counts are derived from the loaded questions, a successful catalog is cached for the ViewModel lifetime, and catalog loading does not start a round.
- A failed catalog load can be retried and clears its error after successful recovery.
- Negative and out-of-range answer indices leave the active round, answer selection and timer value unchanged.

Command: `swift test --scratch-path /private/tmp/dlamsd01-audit-20261023/spm2 --cache-path /private/tmp/dlamsd01-audit-20261023/cache2 --disable-sandbox` (with Clang and Swift module caches redirected under `/private/tmp`). Result: **48 tests passed, 0 failures**, across the package test target. SwiftPM warned that user-level configuration/security caches were inaccessible and disabled those cache features. Existing SwiftUI component tests also warn when reading `Environment` values from an unmounted view; those tests pass but do not constitute rendered-layout or device-interaction verification.

The native simulator target was built separately on 23 October 2026 with `xcodebuild` into `/private/tmp/dlamsd01-audit-20261023/DerivedData`; the command exited 0 and produced an `.app` whose metadata reports marketing version `0.3.0`, build `20261022.202656`, minimum iOS `17.0` and SDK `iphonesimulator27.1`. Xcode reported that Simulator services were unavailable in this environment. The build was not installed or launched, and its existing build number was not advanced. This build occurred before the three test-only additions above.

The continuation remains **in progress**. The current test run does not prove the card tap flow, Dynamic Type rendering, the 56 pt target in runtime, appearance-specific feedback, VoiceOver navigation or a complete round on a device. A coverage-enabled run on 23 October 2026 passed all 48 tests and measured 2,350 of 2,587 instrumented production lines (90.84%) in the macOS Swift Package. This excludes tests and the app entry point and is not UI/runtime coverage. The 90.94% figure above remains the separate baseline measurement for commit `52a2e45`.
