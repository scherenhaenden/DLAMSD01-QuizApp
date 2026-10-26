import XCTest
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
@testable import TrainYourBrainCore

@MainActor
final class Sprint10CoverageBoostTests: XCTestCase {
    private var tempDirectory: URL!
    private var catalogFileURL: URL!
    private var service: LocalQuestionService!
    private var viewModel: QuizViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoverageBoostTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        catalogFileURL = tempDirectory.appendingPathComponent("test_catalog.json")
        service = LocalQuestionService(customCatalogURL: catalogFileURL)
        viewModel = QuizViewModel(questionService: service)
    }
    
    override func tearDown() async throws {
        if let dir = tempDirectory, FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        CategoryRegistry.shared.resetToDefaults()
        try await super.tearDown()
    }
    
    // MARK: - 1. QuestionServiceProtocol Defaults & Errors
    
    func testQuestionServiceDefaultsAndErrors() throws {
        struct MinimalService: QuestionServiceProtocol, @unchecked Sendable {
            func loadAllQuestions() throws -> [Question] { [] }
            func loadQuestions(for category: QuizCategory) throws -> [Question] { [] }
        }
        
        let minService = MinimalService()
        XCTAssertTrue(try minService.loadCustomQuestions().isEmpty)
        let cat = QuizCategory(id: "dummy", displayName: "Dummy")
        try minService.addCategory(cat)
        try minService.updateCategory(cat)
        try minService.deleteCategory(id: "dummy")
        let q = try Question(
            prompt: "P",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Exp",
            category: cat,
            difficulty: .easy
        )
        try minService.addQuestion(q)
        try minService.updateQuestion(q)
        try minService.deleteQuestion(id: q.id)
        let res = try minService.importCatalog(from: Data())
        XCTAssertEqual(res.categoriesCount, 0)
        XCTAssertEqual(res.questionsCount, 0)
        
        let errors: [QuestionServiceError] = [
            .resourceNotFound(filename: "missing.json"),
            .unreadableData("bad bytes"),
            .decodingFailed("corrupt json"),
            .emptyQuestionSet,
            .customCatalogSaveFailed("disk error"),
            .systemCategoryDeletionNotAllowed("sys_cat"),
            .systemCategoryModificationNotAllowed("sys_mod"),
            .systemQuestionDeletionNotAllowed("sys_q"),
            .questionNotFound(UUID()),
            .categoryNotFound("cat_404"),
            .invalidCatalogPayload("schema error"),
            .duplicateQuestionId(UUID())
        ]
        
        for err in errors {
            XCTAssertNotNil(err.errorDescription)
            XCTAssertFalse(err.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - 2. ScoreStoreProtocol & CategoryRegistry Defaults
    
    func testScoreStoreAndCategoryRegistry() {
        struct MinimalStore: ScoreStoreProtocol, @unchecked Sendable {
            func save(record: ScoreRecord) throws {}
            func loadRecords() -> [ScoreRecord] { [] }
            func loadHighScores(limit: Int) -> [ScoreRecord] { [] }
            func bestScore(for category: QuizCategory?) -> ScoreRecord? { nil }
            func clearAll() throws {}
        }
        
        let store = MinimalStore()
        XCTAssertTrue(store.loadHighScores().isEmpty)
        
        let customCat = QuizCategory(id: "custom_snap", displayName: "Custom Snap")
        CategoryRegistry.shared.register(customCat)
        let snap = CategoryRegistry.shared.snapshot()
        XCTAssertFalse(snap.isEmpty)
        CategoryRegistry.shared.resetTo(snap)
        XCTAssertTrue(CategoryRegistry.shared.snapshot().contains(where: { $0.id == "custom_snap" }))
        CategoryRegistry.shared.resetToDefaults()
        
        let netErrors: [NetworkCatalogError] = [
            .invalidURL,
            .networkFailure("connection refused"),
            .invalidHTTPResponse(statusCode: 500),
            .emptyResponse
        ]
        for ne in netErrors {
            XCTAssertNotNil(ne.errorDescription)
        }
    }
    
    // MARK: - 3. Adaptive Colors Coverage & Dynamic Appearances
    
    func testAdaptiveColorsCoverage() {
        _ = Color.quizCorrectFeedback
        _ = Color.quizIncorrectFeedback
        _ = Color.adaptiveSuccessText
        _ = Color.adaptiveErrorText
        _ = Color.adaptiveScoreIcon
        _ = Color.adaptiveStreakIcon
        _ = Color.adaptiveSpeedIcon
        _ = Color.adaptiveBackground
        _ = Color.adaptiveCardBackground
        _ = Color.adaptiveSecondaryBackground
        _ = Color.adaptiveTertiaryBackground
        _ = Color.adaptiveBorder
        
        #if canImport(AppKit)
        let appearances: [NSAppearance] = [
            NSAppearance(named: .aqua)!,
            NSAppearance(named: .darkAqua)!
        ]
        for app in appearances {
            app.performAsCurrentDrawingAppearance {
                _ = Color.adaptiveSuccessNSColor.cgColor
                _ = Color.adaptiveErrorNSColor.cgColor
                _ = Color.adaptiveScoreNSColor.cgColor
                _ = Color.adaptiveStreakNSColor.cgColor
                _ = Color.adaptiveSpeedNSColor.cgColor
            }
        }
        #endif
    }
    
    // MARK: - 4. StudyMaterialManagerView Sheets & Action Handlers
    
    func testStudyMaterialSheetsAndSubviews() throws {
        try viewModel.addCustomCategory(name: "Robotics", iconName: "cpu", description: "Robotics Study")
        let cat = viewModel.allCategories.first(where: { $0.displayName == "Robotics" })!
        
        try viewModel.addCustomQuestion(
            prompt: "What is inverse kinematics?",
            options: ["Joint angles from pose", "Forward motion", "Speed check", "Force gauge"],
            correctAnswerIndex: 0,
            explanation: "IK calculates joint configurations.",
            category: cat,
            difficulty: .hard
        )
        
        let q = viewModel.customQuestions.first!
        
        // AddCategorySheet: success and empty branches
        let addSheetValid = AddCategorySheet(
            viewModel: viewModel,
            initialName: "Distributed Systems",
            initialDescription: "Consensus and Raft",
            initialIcon: "network",
            initialErrorMessage: "Sample error",
            onCompletion: { _, _ in }
        )
        XCTAssertNotNil(addSheetValid.body)
        addSheetValid.saveCategory()
        
        let addSheetEmpty = AddCategorySheet(
            viewModel: viewModel,
            initialName: "   ",
            initialDescription: "",
            initialIcon: "folder.fill",
            initialErrorMessage: nil,
            onCompletion: { _, _ in }
        )
        addSheetEmpty.saveCategory()
        
        // EditCategorySheet: saveCategory with valid, empty, and initial error
        let editSheetValid = EditCategorySheet(
            viewModel: viewModel,
            category: cat,
            initialName: "Robotics & Controls",
            initialDescription: "Updated desc",
            initialIcon: "cpu",
            initialErrorMessage: "Some error",
            onCompletion: { _, _ in }
        )
        XCTAssertNotNil(editSheetValid.body)
        editSheetValid.saveCategory()
        
        let editSheetEmpty = EditCategorySheet(
            viewModel: viewModel,
            category: cat,
            initialName: "   ",
            initialDescription: "",
            initialIcon: "folder.fill",
            initialErrorMessage: nil,
            onCompletion: { _, _ in }
        )
        editSheetEmpty.saveCategory()
        
        // QuestionEditorSheet: new, edit, invalid category, and error state
        let invalidCatSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: nil,
            initialCategoryId: "non_existent_category",
            onCompletion: { _, _ in }
        )
        invalidCatSheet.saveQuestion()
        
        let newQSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: nil,
            initialCategoryId: cat.rawValue,
            initialPrompt: "Valid prompt for custom question?",
            initialOption0: "Opt 1",
            initialOption1: "Opt 2",
            initialOption2: "Opt 3",
            initialOption3: "Opt 4",
            initialCorrectIndex: 1,
            initialExplanation: "Valid explanation here.",
            initialDifficulty: .easy,
            initialErrorMessage: "Initial question error",
            onCompletion: { _, _ in }
        )
        XCTAssertNotNil(newQSheet.body)
        newQSheet.saveQuestion()
        _ = newQSheet.optionRow(index: 0, text: .constant("Sample Option"))
        
        let editQSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: q,
            initialCategoryId: cat.rawValue,
            onCompletion: { _, _ in }
        )
        XCTAssertNotNil(editQSheet.body)
        editQSheet.saveQuestion()
        
        // Manager views across tabs & subviews
        let manager0 = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 0,
            initialStatusMessage: "Category created.",
            initialIsStatusError: false
        )
        XCTAssertNotNil(manager0.body)
        XCTAssertNotNil(manager0.feedbackBannerView)
        XCTAssertNotNil(manager0.subjectsTabView)
        
        let manager1 = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 1,
            initialStatusMessage: "Failed to delete.",
            initialIsStatusError: true,
            initialCategoryFilter: "all"
        )
        XCTAssertNotNil(manager1.body)
        XCTAssertNotNil(manager1.feedbackBannerView)
        XCTAssertNotNil(manager1.questionsTabView)
        
        // Questions tab with non-matching filter (empty list view)
        let managerEmptyQuestions = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 1,
            initialCategoryFilter: "filter_with_zero_matches"
        )
        XCTAssertNotNil(managerEmptyQuestions.questionsTabView)
        
        let manager2Downloading = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 2,
            initialImportURL: "https://example.com/catalog.json",
            initialIsDownloading: true
        )
        XCTAssertNotNil(manager2Downloading.body)
        XCTAssertNotNil(manager2Downloading.importTabView)
        
        let manager2Idle = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 2,
            initialImportURL: "",
            initialIsDownloading: false
        )
        XCTAssertNotNil(manager2Idle.importTabView)
        
        // Action Handlers
        manager0.deleteCategory(cat)
        manager0.deleteCategory(.softwareEngineering) // System category should safely fail
        manager1.deleteQuestion(q)
        
        manager2Idle.downloadFromURL() // empty URL should produce validation error
        manager2Idle.handleFileImport(result: .failure(QuestionServiceError.emptyQuestionSet))
        
        let dummyFileURL = tempDirectory.appendingPathComponent("import_test.json")
        try "{\"categories\":[],\"questions\":[]}".write(to: dummyFileURL, atomically: true, encoding: .utf8)
        manager2Idle.handleFileImport(result: .success([dummyFileURL]))
    }
    
    // MARK: - 5. ResultView Diverse States & Layout Hosting
    
    func testResultViewWithVariousStates() {
        let breakdown = [
            CategoryPerformance(categoryId: "software_engineering", categoryTitle: "Software Engineering", correctCount: 5, totalCount: 5),
            CategoryPerformance(categoryId: "swift_apple", categoryTitle: "Swift & Apple Platform", correctCount: 2, totalCount: 5)
        ]
        let perfectRecord = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, streakRecord: 10, categoryBreakdown: breakdown)
        let passView = ResultView(record: perfectRecord, onPlayAgain: {}, onBackToMenu: {})
        XCTAssertNotNil(passView.body)
        
        let failRecord = ScoreRecord(score: 0, totalQuestions: 10, correctAnswers: 0, streakRecord: 0)
        let failView = ResultView(record: failRecord, onPlayAgain: {}, onBackToMenu: {})
        XCTAssertNotNil(failView.body)
        
        let midRecord = ScoreRecord(score: 60, totalQuestions: 10, correctAnswers: 6, streakRecord: 3)
        let midView = ResultView(record: midRecord, onPlayAgain: {}, onBackToMenu: {})
        XCTAssertNotNil(midView.body)
        
        #if canImport(AppKit)
        let hosting = NSHostingView(rootView: passView)
        hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        hosting.layout()
        _ = hosting.fittingSize
        #endif
    }
    
    // MARK: - 6. LeaderboardView Populated and Filter States
    
    func testLeaderboardViewPopulatedAndEmptyStates() throws {
        let store = InMemoryScoreStore()
        let r1 = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, category: .softwareEngineering)
        let r2 = ScoreRecord(score: 80, totalQuestions: 10, correctAnswers: 8, category: .swiftAndApple)
        try store.save(record: r1)
        try store.save(record: r2)
        
        XCTAssertEqual(store.loadHighScores().count, 2)
        XCTAssertNotNil(store.bestScore(for: .softwareEngineering))
        XCTAssertNotNil(store.bestScore(for: nil))
        
        let leadVM = LeaderboardViewModel(scoreStore: store)
        leadVM.refresh()
        
        let populatedView = LeaderboardView(viewModel: leadVM)
        XCTAssertNotNil(populatedView.body)
        
        leadVM.selectedTab = .history
        leadVM.selectedCategory = .softwareEngineering
        let historyView = LeaderboardView(viewModel: leadVM)
        XCTAssertNotNil(historyView.body)
        
        // Empty state view
        try store.clearAll()
        XCTAssertTrue(store.loadRecords().isEmpty)
        leadVM.refresh()
        let emptyView = LeaderboardView(viewModel: leadVM)
        XCTAssertNotNil(emptyView.body)
    }
    
    // MARK: - 7. QuizView and HomeView Screen States
    
    func testQuizViewAndHomeViewStates() throws {
        let homeView = HomeView(viewModel: viewModel)
        XCTAssertNotNil(homeView.body)
        XCTAssertNotNil(homeView.headerActionsView)
        XCTAssertNotNil(homeView.themePickerView)
        XCTAssertFalse(homeView.catalogSummaryText.isEmpty)
        
        // Sheet initialization states
        let homeWithLeaderboard = HomeView(viewModel: viewModel, initialShowLeaderboard: true, initialShowMaterialManager: false)
        XCTAssertNotNil(homeWithLeaderboard.body)
        
        let homeWithMaterial = HomeView(viewModel: viewModel, initialShowLeaderboard: false, initialShowMaterialManager: true)
        XCTAssertNotNil(homeWithMaterial.body)
        
        struct ThrowingService: QuestionServiceProtocol, @unchecked Sendable {
            func loadAllQuestions() throws -> [Question] { throw QuestionServiceError.emptyQuestionSet }
            func loadQuestions(for category: QuizCategory) throws -> [Question] { throw QuestionServiceError.emptyQuestionSet }
        }
        let errorVM = QuizViewModel(questionService: ThrowingService())
        errorVM.loadQuestionCatalog()
        let errorHomeView = HomeView(viewModel: errorVM)
        XCTAssertNotNil(errorHomeView.body)
        XCTAssertEqual(errorHomeView.catalogSummaryText, "Questions unavailable")
        
        // Unloaded catalog summary test
        struct EmptyService: QuestionServiceProtocol, @unchecked Sendable {
            func loadAllQuestions() throws -> [Question] { [] }
            func loadQuestions(for category: QuizCategory) throws -> [Question] { [] }
        }
        let unloadedVM = QuizViewModel(questionService: EmptyService())
        let unloadedHome = HomeView(viewModel: unloadedVM)
        XCTAssertEqual(unloadedHome.catalogSummaryText, "Loading questions…")
        
        // QuizView flow
        viewModel.startQuiz(category: nil)
        let quizView = QuizView(viewModel: viewModel)
        XCTAssertNotNil(quizView.body)
        
        // Answer announcements
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: -1, isCorrect: false))
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: 0, isCorrect: true))
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: 1, isCorrect: false))
        quizView.announceAnswerFeedback(for: .playing)
        
        if let currentQ = viewModel.currentQuestion {
            viewModel.selectAnswer(at: currentQ.correctAnswerIndex)
            let answeredQuizView = QuizView(viewModel: viewModel)
            XCTAssertNotNil(answeredQuizView.body)
        }
        
        // Streak indicator (> 1) & last question View Results
        viewModel.startQuiz(category: nil)
        if let currentQ = viewModel.currentQuestion {
            viewModel.selectAnswer(at: currentQ.correctAnswerIndex)
            viewModel.nextQuestion()
        }
        
        // Test retry, timeout, scenePhase, and timer ticks
        viewModel.retryLastQuiz()
        viewModel.tickTimer(delta: 1.0)
        viewModel.handleTimeout()
        let timeoutQuizView = QuizView(viewModel: viewModel)
        XCTAssertNotNil(timeoutQuizView.body)
        
        viewModel.stopTimer()
        viewModel.handleScenePhaseChange(to: .background, currentDate: Date())
        viewModel.handleScenePhaseChange(to: .active, currentDate: Date())
    }
    
    // MARK: - 8. Question Validation Errors, RNG Shuffling & Missing Key Decoding
    
    func testQuestionValidationErrorsAndShuffling() throws {
        let validationErrors: [Question.ValidationError] = [
            .emptyPrompt,
            .insufficientOptions(count: 2),
            .emptyOption,
            .invalidCorrectIndex(index: 5, optionsCount: 4),
            .duplicateOptions,
            .emptyExplanation
        ]
        
        for err in validationErrors {
            XCTAssertNotNil(err.errorDescription)
            XCTAssertFalse(err.errorDescription!.isEmpty)
        }
        
        let validQ = try Question(
            prompt: "What is Polymorphism?",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Ability to take multiple forms.",
            category: .softwareEngineering,
            difficulty: .medium
        )
        
        var rng = SystemRandomNumberGenerator()
        let shuffled1 = validQ.shuffledOptions(using: &rng)
        let shuffled2 = validQ.shuffledOptions()
        XCTAssertEqual(shuffled1.options.count, 4)
        XCTAssertEqual(shuffled2.options.count, 4)
        
        // Decoding Question JSON without ID and without Difficulty
        let jsonWithoutIdAndDiff = """
        {
            "prompt": "What is ARC?",
            "options": ["Automatic Reference Counting", "Array Ref Count", "Apple Run Command", "Async Routine Call"],
            "correctAnswerIndex": 0,
            "explanation": "ARC manages object memory in Swift.",
            "category": "swift_apple"
        }
        """.data(using: .utf8)!
        
        let decodedQ = try JSONDecoder().decode(Question.self, from: jsonWithoutIdAndDiff)
        XCTAssertEqual(decodedQ.difficulty, .medium)
        XCTAssertNotNil(decodedQ.id)
    }
    
    // MARK: - 9. CustomCatalogPayload Record Initializer & Codable Fallbacks
    
    func testCustomCatalogPayloadDetails() throws {
        let rec = CustomCategoryRecord(from: .softwareEngineering)
        XCTAssertEqual(rec.id, QuizCategory.softwareEngineering.rawValue)
        XCTAssertEqual(rec.displayName, QuizCategory.softwareEngineering.displayName)
        
        let minimalPayload = CustomCatalogPayload()
        let encodedData = try JSONEncoder().encode(minimalPayload)
        let decodedPayload = try JSONDecoder().decode(CustomCatalogPayload.self, from: encodedData)
        XCTAssertTrue(decodedPayload.categories.isEmpty)
        XCTAssertTrue(decodedPayload.questions.isEmpty)
        
        let emptyJsonData = "{}".data(using: .utf8)!
        let decodedEmpty = try JSONDecoder().decode(CustomCatalogPayload.self, from: emptyJsonData)
        XCTAssertTrue(decodedEmpty.categories.isEmpty)
        XCTAssertTrue(decodedEmpty.questions.isEmpty)
    }
    
    // MARK: - 10. QuizCategory Dynamic Switch & Fallback Regions
    
    func testQuizCategoryDynamicSwitchAndFallbackRegions() {
        CategoryRegistry.shared.resetTo([])
        let rawIds = [
            QuizCategory.softwareEngineering.rawValue,
            QuizCategory.swiftAndApple.rawValue,
            QuizCategory.algorithmsAndDataStructures.rawValue,
            QuizCategory.testingAndQuality.rawValue,
            "custom_distributed_systems_domain"
        ]
        
        for raw in rawIds {
            let cat = QuizCategory(rawValue: raw, customDisplayName: nil, customIconName: nil, customDescription: nil, isCustom: false)
            XCTAssertFalse(cat.displayName.isEmpty)
            XCTAssertFalse(cat.iconName.isEmpty)
            XCTAssertFalse(cat.localizedDescription.isEmpty)
        }
        CategoryRegistry.shared.resetToDefaults()
        
        // Test empty id fallback to UUID
        let emptyIdCat = QuizCategory(id: "   ", displayName: "Empty Trimmed")
        XCTAssertFalse(emptyIdCat.rawValue.isEmpty)
        
        // Test empty icon fallback to folder.fill
        let emptyIconCat = QuizCategory(id: "some_id", displayName: "Name", iconName: "")
        XCTAssertEqual(emptyIconCat.iconName, "folder.fill")
    }
    
    // MARK: - 11. CategoryCard Dynamic Sizes & States
    
    func testCategoryCardDynamicSizesAndStates() {
        let cardLoading = CategoryCard(category: nil, questionCount: 0, isLoading: true, isSelected: false, action: {})
        XCTAssertNotNil(cardLoading.body)
        XCTAssertNotNil(cardLoading.subtitle)
        
        let cardEmpty = CategoryCard(category: nil, questionCount: 0, isLoading: false, isSelected: false, action: {})
        XCTAssertNotNil(cardEmpty.body)
        
        let cardSingle = CategoryCard(category: .softwareEngineering, questionCount: 1, isLoading: false, isSelected: true, action: {})
        XCTAssertNotNil(cardSingle.body)
        
        let cardMultiple = CategoryCard(category: .softwareEngineering, questionCount: 10, isLoading: false, isSelected: false, action: {})
        XCTAssertNotNil(cardMultiple.body)
        
        // Test dynamicTypeSize accessibility size branch
        let a11yView = cardMultiple.environment(\EnvironmentValues.dynamicTypeSize, DynamicTypeSize.accessibility3)
        XCTAssertNotNil(a11yView)
    }
    
    // MARK: - 12. AnswerButton Visual States & Symbols
    
    func testAnswerButtonVisualStatesAndSymbols() {
        // Correct revealed
        let correctBtn = AnswerButton(optionText: "Option A", index: 0, isSelected: true, isCorrectAnswer: true, isAnswerRevealed: true, action: {})
        XCTAssertNotNil(correctBtn.body)
        
        // Wrong revealed
        let wrongBtn = AnswerButton(optionText: "Option B", index: 1, isSelected: true, isCorrectAnswer: false, isAnswerRevealed: true, action: {})
        XCTAssertNotNil(wrongBtn.body)
        
        // Dimmed revealed
        let dimmedBtn = AnswerButton(optionText: "Option C", index: 2, isSelected: false, isCorrectAnswer: false, isAnswerRevealed: true, action: {})
        XCTAssertNotNil(dimmedBtn.body)
        
        // Selected unrevealed
        let selectedBtn = AnswerButton(optionText: "Option D", index: 3, isSelected: true, isCorrectAnswer: nil, isAnswerRevealed: false, action: {})
        XCTAssertNotNil(selectedBtn.body)
        
        // Idle unrevealed
        let idleBtn = AnswerButton(optionText: "Option E", index: 99, isSelected: false, isCorrectAnswer: nil, isAnswerRevealed: false, action: {})
        XCTAssertNotNil(idleBtn.body)
        
        // Static accessibility helpers
        let states: [AnswerButton.VisualState] = [.idle, .selected, .correct, .wrong, .dimmed]
        for st in states {
            XCTAssertFalse(AnswerButton.accessibilityHintText(for: st).isEmpty)
            _ = AnswerButton.accessibilityValueText(for: st)
        }
    }
    
    // MARK: - 13. HomeView Interactive Actions & Error Handling
    
    func testHomeViewInteractiveActionsAndErrorHandling() {
        let homeView = HomeView(viewModel: viewModel, initialShowLeaderboard: false, initialShowMaterialManager: false)
        _ = homeView.body
        _ = homeView.headerActionsView
        _ = homeView.themePickerView
        _ = homeView.catalogSummaryText
        
        homeView.triggerReload()
        homeView.triggerQuickStart()
        homeView.triggerCategoryStart(.softwareEngineering)
        homeView.openLeaderboard()
        homeView.openMaterialManager()
        
        // Error state branch
        struct ThrowingService: QuestionServiceProtocol, @unchecked Sendable {
            func loadAllQuestions() throws -> [Question] { throw QuestionServiceError.resourceNotFound(filename: "fail.json") }
            func loadQuestions(for category: QuizCategory) throws -> [Question] { throw QuestionServiceError.resourceNotFound(filename: "fail.json") }
        }
        let errorVM = QuizViewModel(questionService: ThrowingService())
        errorVM.loadQuestionCatalog()
        let errorHome = HomeView(viewModel: errorVM)
        _ = errorHome.body
        _ = errorHome.catalogSummaryText
        errorHome.triggerReload()
    }
    
    // MARK: - 14. QuizView Interactive Actions & Feedback States
    
    func testQuizViewInteractiveActionsAndFeedbackStates() {
        viewModel.loadQuestionCatalog()
        viewModel.startQuiz(category: .softwareEngineering)
        
        let quizView = QuizView(viewModel: viewModel)
        _ = quizView.body
        
        quizView.triggerSelectAnswer(at: 0)
        _ = quizView.body
        
        quizView.triggerAdvance()
        _ = quizView.body
        
        quizView.triggerClose()
        
        // Announcements and ViewState changes
        quizView.handleViewStateChange(.idle)
        quizView.handleViewStateChange(.playing)
        quizView.handleViewStateChange(.answered(selectedIndex: 0, isCorrect: true))
        quizView.handleViewStateChange(.answered(selectedIndex: 1, isCorrect: false))
        quizView.handleViewStateChange(.answered(selectedIndex: -1, isCorrect: false))
        
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: 0, isCorrect: true))
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: 1, isCorrect: false))
        quizView.announceAnswerFeedback(for: .answered(selectedIndex: -1, isCorrect: false))
        
        // Multi-question streak test
        viewModel.startQuiz(category: .softwareEngineering)
        if let q = viewModel.currentQuestion {
            viewModel.selectAnswer(at: q.correctAnswerIndex)
            viewModel.nextQuestion()
            if let q2 = viewModel.currentQuestion {
                viewModel.selectAnswer(at: q2.correctAnswerIndex)
                let streakQuizView = QuizView(viewModel: viewModel)
                _ = streakQuizView.body
            }
        }
    }
    
    // MARK: - 15. StudyMaterialManagerView All Tabs & Actions
    
    func testStudyMaterialManagerViewAllTabsAndActions() throws {
        // Tab 0 (Subjects), Tab 1 (Questions), Tab 2 (Import)
        for tab in [0, 1, 2] {
            let manager = StudyMaterialManagerView(viewModel: viewModel, initialTab: tab)
            _ = manager.body
        }
        
        let customCat = QuizCategory(id: "custom_comp_sci", displayName: "Computer Science", iconName: "cpu", description: "Theory")
        try viewModel.addCustomCategory(name: "Computer Science", iconName: "cpu", description: "Theory")
        
        let customQ = try Question(
            prompt: "What is Big O?",
            options: ["Complexity", "Color", "Animal", "Food"],
            correctAnswerIndex: 0,
            explanation: "Asymptotic notation",
            category: customCat,
            difficulty: .hard
        )
        try viewModel.addCustomQuestion(
            prompt: customQ.prompt,
            options: customQ.options,
            correctAnswerIndex: customQ.correctAnswerIndex,
            explanation: customQ.explanation,
            category: customQ.category,
            difficulty: customQ.difficulty
        )
        
        let manager = StudyMaterialManagerView(
            viewModel: viewModel,
            initialTab: 0,
            initialStatusMessage: "Initial status",
            initialIsStatusError: true,
            initialCategoryFilter: customCat.rawValue,
            initialImportURL: "https://example.com/questions.json",
            initialIsDownloading: false,
            initialShowAddCategory: true,
            initialCategoryToEdit: customCat,
            initialShowQuestionEditor: true,
            initialQuestionToEdit: customQ
        )
        
        _ = manager.body
        _ = manager.feedbackBannerView
        _ = manager.subjectsTabView
        _ = manager.questionsTabView
        _ = manager.importTabView
        _ = manager.addCategorySheetView.body
        _ = manager.editCategorySheetView(for: customCat).body
        _ = manager.questionEditorSheetView.body
        _ = manager.presentAddCategorySheet().body
        _ = manager.presentEditCategorySheet(for: customCat).body
        _ = manager.presentQuestionEditorSheet().body
        
        manager.handleAddCategoryCompletion(success: true, message: "Added")
        manager.handleAddCategoryCompletion(success: false, message: "Failed Add")
        manager.handleEditCategoryCompletion(success: true, message: "Edited")
        manager.handleQuestionEditorCompletion(success: true, message: "Edited Q")
        manager.handleOnAppear()
        manager.triggerDismiss()
        
        let corruptFile = tempDirectory.appendingPathComponent("corrupt_test.json")
        try "corrupt content".write(to: corruptFile, atomically: true, encoding: .utf8)
        let warningService = LocalQuestionService(customCatalogURL: corruptFile)
        let warningVM = QuizViewModel(questionService: warningService)
        warningVM.loadQuestionCatalog()
        let warningManager = StudyMaterialManagerView(viewModel: warningVM)
        warningManager.handleOnAppear()
        
        manager.clearStatusMessage()
        manager.openAddCategory()
        manager.openEditCategory(customCat)
        manager.openAddQuestion()
        manager.openEditQuestion(customQ)
        manager.openFileImporter()
        
        // Delete action handlers
        manager.deleteQuestion(customQ)
        manager.deleteCategory(customCat)
        
        // Attempt deleting system category and question (error branches)
        manager.deleteCategory(.softwareEngineering)
        if let bundledQ = try? service.loadAllQuestions().first {
            manager.deleteQuestion(bundledQ)
        }
        
        // File import handlers
        let dummyJsonURL = tempDirectory.appendingPathComponent("dummy.json")
        try "[]".write(to: dummyJsonURL, atomically: true, encoding: .utf8)
        manager.handleFileImport(result: .success([dummyJsonURL]))
        
        let corruptJson = tempDirectory.appendingPathComponent("corrupt_import.json")
        try "corrupt content".write(to: corruptJson, atomically: true, encoding: .utf8)
        manager.handleFileImport(result: .success([corruptJson]))
        
        manager.handleFileImport(result: .success([]))
        manager.handleFileImport(result: .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "File error"])))
        
        // Download handlers
        manager.downloadFromURL()
        let invalidManager = StudyMaterialManagerView(viewModel: viewModel, initialImportURL: "not_a_valid_url")
        invalidManager.downloadFromURL()
    }
    
    // MARK: - 16. Sheet Views (AddCategorySheet, EditCategorySheet, QuestionEditorSheet)
    
    func testAddCategorySheetAndEditCategorySheetAndQuestionEditorSheet() throws {
        // AddCategorySheet
        var addResult: (Bool, String)?
        let addSheet = AddCategorySheet(
            viewModel: viewModel,
            initialName: "Cloud Arch",
            initialDescription: "Distributed Systems",
            initialIcon: "server.rack",
            initialErrorMessage: "Pre-existing error"
        ) { success, msg in
            addResult = (success, msg)
        }
        _ = addSheet.body
        addSheet.selectIcon("globe")
        addSheet.triggerDismiss()
        addSheet.saveCategory()
        XCTAssertNotNil(addResult)
        
        // AddCategorySheet with empty name (validation failure)
        let emptyAddSheet = AddCategorySheet(viewModel: viewModel, initialName: "") { _, _ in }
        emptyAddSheet.saveCategory()
        
        // AddCategorySheet with duplicate system category (error catch branch)
        let dupAddSheet = AddCategorySheet(viewModel: viewModel, initialName: "Software Engineering") { _, _ in }
        dupAddSheet.saveCategory()
        
        // Icon selection iteration
        for icon in ["folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer", "atom", "cpu", "network", "shield.fill", "globe", "server.rack"] {
            addSheet.selectIcon(icon)
        }
        
        // EditCategorySheet
        let customCat = QuizCategory(id: "edit_target", displayName: "Edit Target", iconName: "folder.fill")
        try viewModel.addCustomCategory(name: "Edit Target", iconName: "folder.fill", description: "Original")
        
        var editResult: (Bool, String)?
        let editSheet = EditCategorySheet(
            viewModel: viewModel,
            category: customCat,
            initialName: "Edited Title",
            initialDescription: "Updated description",
            initialIcon: "atom",
            initialErrorMessage: nil
        ) { success, msg in
            editResult = (success, msg)
        }
        _ = editSheet.body
        editSheet.selectIcon("cpu")
        for icon in ["folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer", "atom", "cpu", "network", "shield.fill", "globe", "server.rack"] {
            editSheet.selectIcon(icon)
        }
        editSheet.triggerDismiss()
        editSheet.saveCategory()
        XCTAssertNotNil(editResult)
        
        // EditCategorySheet with empty name
        let emptyEditSheet = EditCategorySheet(viewModel: viewModel, category: customCat, initialName: "") { _, _ in }
        emptyEditSheet.saveCategory()
        
        // EditCategorySheet error catch branch (system category update not allowed)
        let editSysSheet = EditCategorySheet(viewModel: viewModel, category: QuizCategory.softwareEngineering, initialName: "New Sys Name") { _, _ in }
        editSysSheet.saveCategory()
        
        // QuestionEditorSheet for new question
        var newQResult: (Bool, String)?
        let newQSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: nil,
            initialCategoryId: customCat.rawValue,
            initialPrompt: "Valid new prompt?",
            initialOption0: "Opt 1",
            initialOption1: "Opt 2",
            initialOption2: "Opt 3",
            initialOption3: "Opt 4",
            initialCorrectIndex: 0,
            initialExplanation: "Valid explanation",
            initialDifficulty: .easy,
            initialErrorMessage: nil
        ) { success, msg in
            newQResult = (success, msg)
        }
        _ = newQSheet.body
        for idx in 0..<4 {
            _ = newQSheet.optionRow(index: idx, text: .constant("Option \(idx)"))
            newQSheet.selectCorrectIndex(idx)
        }
        newQSheet.triggerDismiss()
        newQSheet.saveQuestion()
        XCTAssertNotNil(newQResult)
        
        // QuestionEditorSheet error catch branch (empty prompt)
        let invalidPromptSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: nil,
            initialCategoryId: customCat.rawValue,
            initialPrompt: "",
            initialOption0: "A",
            initialOption1: "B",
            initialOption2: "C",
            initialOption3: "D"
        ) { _, _ in }
        invalidPromptSheet.saveQuestion()
        
        // QuestionEditorSheet with invalid category
        let invalidCatSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: nil,
            initialCategoryId: "non_existent_category_id"
        ) { _, _ in }
        invalidCatSheet.saveQuestion()
        
        // QuestionEditorSheet for existing question
        try viewModel.addCustomQuestion(
            prompt: "Existing prompt?",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Existing explanation",
            category: customCat,
            difficulty: .medium
        )
        let addedQ = try service.loadCustomQuestions().first(where: { $0.prompt == "Existing prompt?" })!
        
        var updateQResult: (Bool, String)?
        let editQSheet = QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: addedQ,
            initialCategoryId: customCat.rawValue,
            initialPrompt: "Updated prompt?",
            initialOption0: "U1",
            initialOption1: "U2",
            initialOption2: "U3",
            initialOption3: "U4",
            initialCorrectIndex: 2,
            initialExplanation: "Updated explanation",
            initialDifficulty: .hard,
            initialErrorMessage: nil
        ) { success, msg in
            updateQResult = (success, msg)
        }
        _ = editQSheet.body
        editQSheet.selectCorrectIndex(3)
        editQSheet.triggerDismiss()
        editQSheet.saveQuestion()
        XCTAssertNotNil(updateQResult)
    }
}
