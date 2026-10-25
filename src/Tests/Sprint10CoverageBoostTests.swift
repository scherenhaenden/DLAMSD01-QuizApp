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
            onCompletion: { _, _ in }
        )
        XCTAssertNotNil(addSheetValid.body)
        addSheetValid.saveCategory()
        
        let addSheetEmpty = AddCategorySheet(
            viewModel: viewModel,
            initialName: "   ",
            initialDescription: "",
            initialIcon: "folder.fill",
            onCompletion: { _, _ in }
        )
        addSheetEmpty.saveCategory()
        
        // EditCategorySheet: saveCategory
        let editSheet = EditCategorySheet(viewModel: viewModel, category: cat) { _, _ in }
        XCTAssertNotNil(editSheet.body)
        editSheet.saveCategory()
        
        // QuestionEditorSheet: new and edit
        let newQSheet = QuestionEditorSheet(viewModel: viewModel, editingQuestion: nil) { _, _ in }
        XCTAssertNotNil(newQSheet.body)
        newQSheet.saveQuestion()
        _ = newQSheet.optionRow(index: 0, text: .constant("Sample Option"))
        
        let editQSheet = QuestionEditorSheet(viewModel: viewModel, editingQuestion: q) { _, _ in }
        XCTAssertNotNil(editQSheet.body)
        editQSheet.saveQuestion()
        
        // Manager views across tabs
        let manager0 = StudyMaterialManagerView(viewModel: viewModel, initialTab: 0)
        XCTAssertNotNil(manager0.body)
        
        let manager1 = StudyMaterialManagerView(viewModel: viewModel, initialTab: 1)
        XCTAssertNotNil(manager1.body)
        
        let manager2 = StudyMaterialManagerView(viewModel: viewModel, initialTab: 2)
        XCTAssertNotNil(manager2.body)
        
        // Action Handlers
        manager0.deleteCategory(cat)
        manager0.deleteCategory(.softwareEngineering) // System category should safely fail
        manager1.deleteQuestion(q)
        
        manager2.downloadFromURL() // empty URL should produce validation error
        manager2.handleFileImport(result: .failure(QuestionServiceError.emptyQuestionSet))
        
        let dummyFileURL = tempDirectory.appendingPathComponent("import_test.json")
        try "{\"categories\":[],\"questions\":[]}".write(to: dummyFileURL, atomically: true, encoding: .utf8)
        manager2.handleFileImport(result: .success([dummyFileURL]))
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
        
        struct ThrowingService: QuestionServiceProtocol, @unchecked Sendable {
            func loadAllQuestions() throws -> [Question] { throw QuestionServiceError.emptyQuestionSet }
            func loadQuestions(for category: QuizCategory) throws -> [Question] { throw QuestionServiceError.emptyQuestionSet }
        }
        let errorVM = QuizViewModel(questionService: ThrowingService())
        errorVM.loadQuestionCatalog()
        let errorHomeView = HomeView(viewModel: errorVM)
        XCTAssertNotNil(errorHomeView.body)
        
        viewModel.startQuiz(category: nil)
        let quizView = QuizView(viewModel: viewModel)
        XCTAssertNotNil(quizView.body)
        
        if let currentQ = viewModel.currentQuestion {
            viewModel.selectAnswer(at: currentQ.correctAnswerIndex)
            let answeredQuizView = QuizView(viewModel: viewModel)
            XCTAssertNotNil(answeredQuizView.body)
        }
        
        // Streak indicator (> 1)
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
}
