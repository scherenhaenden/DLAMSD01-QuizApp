import XCTest
import SwiftUI
@testable import TrainYourBrainCore

/// Sprint 10 Final Academic Release Tests (v1.0.0)
/// Comprehensive verification of StudyMaterialManagerView subviews, sheet flows,
/// corruption warning banners, and edge cases.
@MainActor
final class Sprint10FinalReleaseTests: XCTestCase {
    
    private var tempDirectory: URL!
    private var catalogFileURL: URL!
    private var service: LocalQuestionService!
    private var viewModel: QuizViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Sprint10FinalTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        catalogFileURL = tempDirectory.appendingPathComponent("custom_catalog.json")
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
    
    // MARK: - 1. StudyMaterialManagerView & Tabs Interaction Tests
    
    func testStudyMaterialManagerViewTabsAndSubviews() throws {
        let view = StudyMaterialManagerView(viewModel: viewModel)
        XCTAssertNotNil(view.body)
        
        // Add a custom category to populate Subjects and Questions tabs
        try viewModel.addCustomCategory(name: "Robotics", iconName: "cpu", description: "Robotics Engineering")
        XCTAssertTrue(viewModel.allCategories.contains(where: { $0.displayName == "Robotics" }))
        
        // Add a custom question to populate Questions tab
        try viewModel.addCustomQuestion(
            prompt: "What does ROS stand for?",
            options: ["Robot Operating System", "Random Optical Sensor", "Remote Open Server", "Realtime Output Suite"],
            correctAnswerIndex: 0,
            explanation: "ROS stands for Robot Operating System.",
            category: QuizCategory(id: "robotics", displayName: "Robotics"),
            difficulty: .medium
        )
        XCTAssertEqual(viewModel.customQuestions.count, 1)
        
        // Instantiate manager view with populated content
        let populatedView = StudyMaterialManagerView(viewModel: viewModel)
        XCTAssertNotNil(populatedView.body)
    }
    
    // MARK: - 2. AddCategorySheet Verification
    
    func testAddCategorySheetLifecycleAndValidation() throws {
        var completedSuccess: Bool?
        let sheet = AddCategorySheet(viewModel: viewModel) { success, _ in
            completedSuccess = success
        }
        XCTAssertNotNil(sheet.body)
        XCTAssertNil(completedSuccess)
        
        // Verify saving via ViewModel
        try viewModel.addCustomCategory(name: "Quantum Computing", iconName: "atom", description: "Qubits and superposition")
        XCTAssertTrue(viewModel.allCategories.contains(where: { $0.displayName == "Quantum Computing" }))
    }
    
    // MARK: - 3. EditCategorySheet Verification
    
    func testEditCategorySheetLifecycleAndValidation() throws {
        try viewModel.addCustomCategory(name: "Cybersec", iconName: "shield.fill", description: "Security")
        let category = viewModel.allCategories.first(where: { $0.displayName == "Cybersec" })!
        
        var completedSuccess: Bool?
        let editSheet = EditCategorySheet(viewModel: viewModel, category: category) { success, _ in
            completedSuccess = success
        }
        XCTAssertNotNil(editSheet.body)
        XCTAssertNil(completedSuccess)
        
        // Update category via ViewModel
        try viewModel.updateCustomCategory(id: category.rawValue, displayName: "Cybersecurity Lab", iconName: "shield.lefthalf.filled", description: "Ethical hacking and defense")
        let updated = viewModel.allCategories.first(where: { $0.rawValue == category.rawValue })!
        XCTAssertEqual(updated.displayName, "Cybersecurity Lab")
        XCTAssertEqual(updated.iconName, "shield.lefthalf.filled")
    }
    
    // MARK: - 4. QuestionEditorSheet Creation & Editing Verification
    
    func testQuestionEditorSheetCreationAndEditing() throws {
        try viewModel.addCustomCategory(name: "Mobile Dev", iconName: "laptopcomputer", description: "iOS development")
        let category = viewModel.allCategories.first(where: { $0.displayName == "Mobile Dev" })!
        
        // 1. New Question Sheet
        var newCompleted = false
        let newQuestionSheet = QuestionEditorSheet(viewModel: viewModel, editingQuestion: nil) { success, _ in
            newCompleted = success
        }
        XCTAssertNotNil(newQuestionSheet.body)
        XCTAssertFalse(newCompleted)
        
        try viewModel.addCustomQuestion(
            prompt: "What is Swift?",
            options: ["A compiled language", "A script", "A database", "An OS"],
            correctAnswerIndex: 0,
            explanation: "Swift is a general-purpose compiled programming language developed by Apple.",
            category: category,
            difficulty: .easy
        )
        let createdQ = viewModel.customQuestions.first!
        XCTAssertEqual(createdQ.prompt, "What is Swift?")
        
        // 2. Edit Question Sheet
        var editCompleted = false
        let editQuestionSheet = QuestionEditorSheet(viewModel: viewModel, editingQuestion: createdQ) { success, _ in
            editCompleted = success
        }
        XCTAssertNotNil(editQuestionSheet.body)
        XCTAssertFalse(editCompleted)
        
        try viewModel.updateCustomQuestion(
            id: createdQ.id,
            prompt: "What is Swift by Apple?",
            options: ["A compiled programming language", "A script", "A database", "An OS"],
            correctAnswerIndex: 0,
            explanation: "Swift is compiled.",
            category: category,
            difficulty: .medium
        )
        let updatedQ = viewModel.customQuestions.first!
        XCTAssertEqual(updatedQ.prompt, "What is Swift by Apple?")
        XCTAssertEqual(updatedQ.difficulty, .medium)
    }
    
    // MARK: - 5. Corruption Warning Banner Display Verification
    
    func testCorruptionWarningBannerTriggersInViewModelAndManagerView() throws {
        // Deterministically create a corrupted catalog file in sandbox
        let catalogFile = tempDirectory.appendingPathComponent("custom_catalog.json")
        try "CORRUPTED_NON_JSON_CONTENT{{{".write(to: catalogFile, atomically: true, encoding: .utf8)
        
        // Reinstantiate service pointing to corrupted file
        let corruptedService = LocalQuestionService(customCatalogURL: catalogFile)
        let corruptedVM = QuizViewModel(questionService: corruptedService)
        corruptedVM.loadQuestionCatalog()
        
        // Verify service generated emergency backup and posted warning
        XCTAssertNotNil(corruptedVM.lastLoadWarning, "ViewModel must receive warning from corrupted service")
        XCTAssertTrue(corruptedVM.lastLoadWarning!.contains("backup") || corruptedVM.lastLoadWarning!.contains("Corrupted"), "Warning must explain backup creation")
        
        // Verify backup file exists in temp directory
        let backupFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            .filter { $0.path.contains(".bak") }
        XCTAssertFalse(backupFiles.isEmpty, "An emergency backup file must exist in directory")
        
        // Verify manager view renders with corruption warning
        let managerView = StudyMaterialManagerView(viewModel: corruptedVM)
        XCTAssertNotNil(managerView.body)
    }
    
    // MARK: - 6. Cascading Deletion Verification
    
    func testDeleteCategoryCascadesToItsCustomQuestions() throws {
        try viewModel.addCustomCategory(name: "AI & ML", iconName: "cpu", description: "Artificial Intelligence")
        let category = viewModel.allCategories.first(where: { $0.displayName == "AI & ML" })!
        
        try viewModel.addCustomQuestion(
            prompt: "What is backpropagation?",
            options: ["Gradient calculation algorithm", "A hardware chip", "A database index", "A UI framework"],
            correctAnswerIndex: 0,
            explanation: "Backpropagation calculates gradients for gradient descent.",
            category: category,
            difficulty: .hard
        )
        XCTAssertEqual(viewModel.customQuestions.count, 1)
        
        // Delete category and verify cascade
        try viewModel.deleteCustomCategory(id: category.rawValue)
        XCTAssertFalse(viewModel.allCategories.contains(where: { $0.rawValue == category.rawValue }))
        XCTAssertEqual(viewModel.customQuestions.count, 0, "Questions belonging to deleted category must be removed")
    }
    
    // MARK: - 7. Empty Filter State in Questions Tab
    
    func testQuestionsTabFiltering() throws {
        try viewModel.addCustomCategory(name: "Subject Alpha", iconName: "book.fill", description: "Alpha")
        try viewModel.addCustomCategory(name: "Subject Beta", iconName: "laptopcomputer", description: "Beta")
        
        let alpha = viewModel.allCategories.first(where: { $0.displayName == "Subject Alpha" })!
        let beta = viewModel.allCategories.first(where: { $0.displayName == "Subject Beta" })!
        
        try viewModel.addCustomQuestion(
            prompt: "Alpha Question 1?",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Explanation",
            category: alpha,
            difficulty: .easy
        )
        
        XCTAssertEqual(viewModel.questionCount(for: alpha), 1)
        XCTAssertEqual(viewModel.questionCount(for: beta), 0)
    }
    
    // MARK: - 8. Score Store Save Failure Handling (C01)
    
    func testScoreSaveFailureExposesErrorAndRetainsFinishedState() throws {
        struct FailingScoreStore: ScoreStoreProtocol, @unchecked Sendable {
            func save(record: ScoreRecord) throws {
                throw ScoreStoreError.persistenceFailed("Disk quota exceeded in sandbox")
            }
            func loadRecords() -> [ScoreRecord] { [] }
            func loadHighScores(limit: Int) -> [ScoreRecord] { [] }
            func bestScore(for category: QuizCategory?) -> ScoreRecord? { nil }
            func clearAll() throws {}
        }
        
        let failingStore = FailingScoreStore()
        let vm = QuizViewModel(questionService: service, scoreStore: failingStore)
        
        try vm.addCustomCategory(name: "TestCat", iconName: "star", description: "Test")
        let cat = vm.allCategories.first(where: { $0.displayName == "TestCat" })!
        try vm.addCustomQuestion(
            prompt: "Test Question?",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Explanation",
            category: cat,
            difficulty: .easy
        )
        
        vm.startQuiz(category: cat)
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertNil(vm.lastScoreSaveError)
        
        let correctIdx = vm.currentQuestion?.correctAnswerIndex ?? 0
        vm.selectAnswer(at: correctIdx)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: correctIdx, isCorrect: true))
        
        // Advance to end of quiz
        vm.nextQuestion()
        
        if case .finished(let record) = vm.viewState {
            XCTAssertEqual(record.score, 10)
            XCTAssertNotNil(vm.lastScoreSaveError, "Save error must be captured")
            XCTAssertTrue(vm.lastScoreSaveError!.contains("Disk quota exceeded"))
        } else {
            XCTFail("ViewState should be finished even when saving fails")
        }
        
        // Resetting to menu clears the error
        vm.resetToMenu()
        XCTAssertNil(vm.lastScoreSaveError)
    }
}
