# Sprint 9 Engineering & Academic Report: Dynamic Study Material, In-App Authoring & External Import

## Executive Summary

Sprint 9 completes the implementation of **Dynamic Study Material Expansion**, directly fulfilling the core pedagogical vision of **Train-your-Brain** and adhering to **IU Aufgabenstellung 1 (Page 2)**:
> *"Entwickeln Sie eine iOS-Applikation als Quiz-App für einen Themenbereich Ihrer Wahl. Begründen Sie die gewählten Funktionen und das Design..."*

While the foundational curriculum includes 24 verified questions across 4 core B.Sc. Softwareentwicklung domains, true academic utility requires that students can personalize their learning by defining custom subjects, creating examination questions directly on-device, and importing external study packages from local files or remote university URLs.

Sprint 9 transitions Train-your-Brain from a static questionnaire into an extensible, student-centric academic learning system without sacrificing domain invariants, thread safety, or accessibility.

---

## Pedagogical & Functional Scope

In alignment with university guidelines, the following capabilities have been engineered, formally verified, and integrated into the application lifecycle:

| Capability | Educational & Technical Rationale | Implementation |
|---|---|---|
| **Custom Subject Creation** | Allows students to categorize study material beyond standard curriculum topics (e.g., Cloud Computing, Cybersecurity, Machine Learning). | `QuizCategory` open struct + thread-safe `CategoryRegistry`. |
| **In-App Question Authoring** | Reinforces active learning and knowledge recall by allowing learners to formulate their own exam questions with pedagogical rationales. | Form in `StudyMaterialManagerView` with strict invariant validation and radio button answer marking. |
| **Content Administration** | Enables iterative refinement, editing, and deletion of custom questions and subjects while keeping core curriculum reference questions immutable. | Full CRUD via `LocalQuestionService` and `QuizViewModel` with cascade deletion for categories. |
| **External Material Import** | Facilitates knowledge sharing and distribution of curated study sets from educators or peers via local JSON files or public URLs. | Two-way import: `.fileImporter` (local/iCloud) and `URLSession` async streaming (`NetworkCatalogImporter`). |
| **Robust Invariant Protection** | Prevents data corruption: any malformed external payload or invalid question is rejected transactionally with atomic rollback. | Dry-run validation of prompt, 4 options, unique choices, valid correct index, and explanation before commit. |
| **Sandbox Persistence** | Preserves all user-created content across app launches and system restarts without cloud dependency. | Atomic JSON persistence in `Application Support/TrainYourBrain/custom_catalog.json`. |
| **Integrated Study & Grading** | Custom subjects are fully integrated into regular quiz gameplay, German academic grading (1.0–5.0), and Leaderboard tracking. | Seamless propagation through `QuizSession`, `ScoreRecord`, `GermanAcademicGrade`, and `LeaderboardView`. |

---

## Architectural Design & Implementation

```
┌────────────────────────────────────────────────────────────────────────┐
│                          SwiftUI Presentation Layer                    │
│  ┌───────────────────────┐  ┌────────────────────────────────────────┐ │
│  │       HomeView        │  │        StudyMaterialManagerView        │ │
│  │ (Dynamic Topic Cards) │  │   (Subjects / Questions / Import Tabs) │ │
│  └───────────┬───────────┘  └───────────────────┬────────────────────┘ │
└──────────────┼──────────────────────────────────┼──────────────────────┘
               ▼                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        QuizViewModel (@MainActor)                      │
│ - allCategories: [QuizCategory]                                        │
│ - addCustomCategory() / deleteCustomCategory()                         │
│ - addCustomQuestion() / updateCustomQuestion() / deleteCustomQuestion()│
│ - importStudyMaterial(data) / importStudyMaterial(url)                 │
└───────────────────────┬─────────────────────────┬──────────────────────┘
                        │                         │
                        ▼                         ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│        LocalQuestionService          │  │    NetworkCatalogImporter    │
│ (QuestionServiceProtocol, Sendable)  │  │ (URLSession async streaming) │
│ - Bundled JSON (Read-Only Seed)      │  └──────────────────────────────┘
│ - Sandbox JSON (Application Support) │
│ - Atomic Transactional Writes        │
└───────────────────────┬──────────────┘
                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      Domain Entities & Registries                      │
│  ┌───────────────────────┐  ┌────────────────────────────────────────┐ │
│  │      QuizCategory     │  │            CategoryRegistry            │ │
│  │  (Open Struct, Ident) │  │       (Thread-Safe In-Memory Lock)     │ │
│  └───────────────────────┘  └────────────────────────────────────────┘ │
│  ┌───────────────────────┐  ┌────────────────────────────────────────┐ │
│  │       Question        │  │        CustomCatalogPayload            │ │
│  │  (Domain Invariants)  │  │   (Codable Container for Storage)      │ │
│  └───────────────────────┘  └────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Extensible Domain: `QuizCategory` & `CategoryRegistry`
Previously, `QuizCategory` was a closed Swift `enum`. In Sprint 9, it was refactored into an open struct conforming to `RawRepresentable, Codable, CaseIterable, Identifiable, Hashable, Sendable`.
- System defaults remain accessible as static constants (`.softwareEngineering`, `.swiftAndApple`, `.algorithmsAndDataStructures`, `.testingAndQuality`).
- `QuizCategory.allCases` dynamically queries `CategoryRegistry.shared.allCategories`, combining system defaults with registered user subjects.
- Single-value Codable encoding preserves 100% backward compatibility with existing score records and bundled curriculum JSON files.

### 2. Sandbox Persistence & Transactional Storage
User-created and imported content is persisted in:
`FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)/TrainYourBrain/custom_catalog.json`
- **Protection of Core Curriculum:** Bundled questions and core categories are immutable reference assets; deletion requests against system IDs throw `QuestionServiceError.systemCategoryDeletionNotAllowed` or `.systemQuestionDeletionNotAllowed`.
- **Atomic Rollback:** During file or URL import, every question is validated against domain invariants prior to mutating storage. If any question fails, the transaction aborts with zero modification to disk state.

### 3. Remote URL Streaming: `NetworkCatalogImporter`
Implemented using native `URLSession` async/await streaming:
- Validates HTTP/HTTPS scheme and ensures HTTP status code `200...299`.
- Rejects empty payloads and network timeouts cleanly.
- Injects into `QuizViewModel` via `NetworkCatalogImporterProtocol` for seamless testability with mock URL protocols.

### 4. User Interface: `StudyMaterialManagerView`
Integrated via the "Material" capsule button in `HomeView` header actions:
- **Tab 1 (Subjects):** Lists all categories with distinct badges (`Curriculum` vs `Custom`), question counts, and "+ Add New Subject" modal with SF Symbol selector.
- **Tab 2 (Questions):** Filterable list of questions with "+ Add Question" modal featuring 4 choice fields, radio buttons to mark the correct choice, difficulty selector, and explanation input.
- **Tab 3 (Import):** Dual import pane featuring local `.fileImporter` JSON selection and direct URL input with loading indicators and accessible status banners.
- Adheres strictly to the 640 pt maximum width container and min 44 pt touch targets.

---

## Verification & Test Results

### 1. Package Test Suite
The package test suite was expanded with `Sprint9DynamicCatalogTests.swift`, adding 13 comprehensive test cases:
1. `testCustomCategoryCreationAndRegistry`: Verifies dynamic registration, metadata retrieval, and case iteration.
2. `testInAppQuestionAuthoringAndInvariants`: Validates invariant enforcement (empty prompt, choice count != 4, duplicate choices, out-of-range correct index).
3. `testCustomStudyMaterialCRUDAndPersistence`: Verifies full save/relaunch cycle from disk sandbox, editing, cascade deletion, and system question protection.
4. `testTransactionalImportPayloadAndDryRunRollback`: Tests both full catalog format and array-only format, and verifies zero-corruption rollback on malformed input.
5. `testNetworkCatalogImporter`: Tests invalid URLs, HTTP 200 success, HTTP 404 handling, and empty responses using `MockURLProtocol`.
6. `testEndToEndGameplayWithCustomStudyMaterial`: Executes an end-to-end round with a custom category ("Quantum Computing"), verifies 100% accuracy yielding German grade 1.0 (Sehr Gut), confirms breakdown in `ScoreRecord`, and verifies Leaderboard filtering.
7. `testCustomCatalogModelsCodable`: Verifies lossless Codable serialization.
8. `testSaveFailureRollsBackInMemoryStateAndRegistry`: Verifies complete atomic rollback of in-memory payloads and CategoryRegistry snapshot restoration if disk persistence fails.
9. `testCategoryMetadataPreservedAcrossServiceRelaunch`: Verifies that custom category display name, icon, and description are preserved across fresh service instantiations and in `QuizSession.categoryBreakdown` without falling back to raw capitalized strings.
10. `testUnreadableCorruptedCatalogGeneratesEmergencyBackup`: Verifies that encountering an unreadable or corrupt catalog creates an emergency `.bak` backup copy before initializing, preventing accidental data erasure.
11. `testCategoryUpdateAndCRUDOperations`: Verifies full CRUD (create, update, delete) for custom categories via `EditCategorySheet` and cascading metadata updates to existing questions.
12. `testDuplicateCategoryIDsInImportDoesNotCrash`: Verifies that importing or decoding JSON containing duplicate category IDs (`"id": "same"`) does not crash with a fatal error, deduplicates gracefully, and successfully links questions to the category.
13. `testCorruptedCatalogWithFailedBackupBlocksSaveOperation`: Verifies that when a corrupted catalog is detected and its backup cannot be created or verified, the service sets `isCatalogSaveBlockedToPreventDataLoss` to true and blocks writes with `customCatalogSaveFailed`, preserving the corrupted file untouched.

**Execution Result:**
- **127 / 127 tests passed (100% success)** in 0.55s.

### 2. Native UI Acceptance Testing (iPad 9.ª Gen 10.2")
`TrainYourBrainUITests.swift` includes dedicated interactive verification:
- Full 9-test UI test suite executed on iPad (9th generation, 10.2" display) in simulator:
  1. `testHomeScreenUIElementsExist`
  2. `testCategorySelectionStartsQuiz`
  3. `testGameplayAnsweringAndResultsFlow`
  4. `testQuickPlayFlow`
  5. `testLeaderboardSheetFlow`
  6. `testSettingsSheetFlow`
  7. `testCategoryFilterOnLeaderboard`
  8. `testLandscapeLayoutAndErgonomicsOnIPad`
  9. `testStudyMaterialManagerSheetCanOpenAndClose`: Non-conditional mandatory assertions verifying navigation through all three segmented tabs (*Subjects*, *Questions*, *Import*), "+ Add Question" and "Browse JSON File" controls, opening the "+ Add New Subject" modal sheet, inspecting form fields, canceling, and dismissing back to `HomeView`. All 9 tests passed cleanly (`** TEST SUCCEEDED **`).

### 3. Code Coverage
Measured with `xcrun llvm-cov` across all 26 production files:
- `LocalQuestionService.swift`: **90.09%**
- `LeaderboardViewModel.swift`: **97.26%**
- `QuizSession.swift`: **95.38%**
- `ScoreRecord.swift`: **92.44%**
- `AnswerButton.swift`: **92.40%**
- `HomeView.swift`: **91.40%**
- `QuizViewModel.swift`: **86.43%**
- `ResultView.swift`: **85.90%**
- `CustomCatalogPayload.swift`: **100.00%**
- `CategoryRegistry.swift`: **74.47%**
- `QuizCategory.swift`: **87.63%**

---

## Conclusion & Version Increment

Sprint 9 successfully delivers the user-mandated material expansion feature, establishing an open learning ecosystem backed by rigorous domain validation, local sandbox persistence, and accessible SwiftUI management interfaces.

- **Current Version:** `0.9.0` (Build `20261024.150000`)
- **Git Branch:** `feat/dynamic-study-material-and-catalog-v090`
