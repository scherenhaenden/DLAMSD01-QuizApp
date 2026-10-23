import XCTest
@testable import TrainYourBrainCore

/// Unit test suite verifying the presentation and state orchestration in `QuizViewModel`.
/// Runs on `@MainActor` to match the ViewModel's thread confinement.
@MainActor
final class QuizViewModelTests: XCTestCase {
    
    /// Test spy conforming to `QuestionServiceProtocol` enabling controlled error injection and fast in-memory execution.
    private final class MockQuestionService: QuestionServiceProtocol, @unchecked Sendable {
        let questions: [Question]
        var shouldThrow: Bool = false
        private(set) var allQuestionsRequestCount = 0
        private(set) var categoryRequests: [QuizCategory] = []
        
        init(questions: [Question]) {
            self.questions = questions
        }
        
        func loadAllQuestions() throws -> [Question] {
            allQuestionsRequestCount += 1
            if shouldThrow {
                throw QuestionServiceError.emptyQuestionSet
            }
            return questions
        }
        
        func loadQuestions(for category: QuizCategory) throws -> [Question] {
            categoryRequests.append(category)
            if shouldThrow {
                throw QuestionServiceError.emptyQuestionSet
            }
            let filtered = questions.filter { $0.category == category }
            if filtered.isEmpty {
                throw QuestionServiceError.emptyQuestionSet
            }
            return filtered
        }
    }
    
    /// Generates a two-question test fixture.
    private func makeMockQuestions() throws -> [Question] {
        return [
            try Question(
                prompt: "ViewModel Test Q1",
                options: ["Correct", "Wrong 1", "Wrong 2", "Wrong 3"],
                correctAnswerIndex: 0,
                explanation: "Explanation 1",
                category: .softwareEngineering,
                difficulty: .easy
            ),
            try Question(
                prompt: "ViewModel Test Q2",
                options: ["Wrong 1", "Correct", "Wrong 2", "Wrong 3"],
                correctAnswerIndex: 1,
                explanation: "Explanation 2",
                category: .softwareEngineering,
                difficulty: .medium
            )
        ]
    }
    
    /// Verifies that calling `startQuiz()` transitions from `.idle` to `.playing` and populates questions.
    func testStartQuizInitializesGameState() throws {
        let questions = try makeMockQuestions()
        let service = MockQuestionService(questions: questions)
        let vm = QuizViewModel(questionService: service)
        
        XCTAssertEqual(vm.viewState, .idle)
        
        vm.startQuiz()
        
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.totalQuestions, 2)
        XCTAssertEqual(vm.questionIndex, 0)
        XCTAssertNotNil(vm.currentQuestion)
        XCTAssertEqual(vm.currentScore, 0)
    }
    
    /// Verifies that service failures (e.g. empty datastore) gracefully transition the ViewModel to `.error`.
    func testStartQuizHandlesServiceError() {
        let service = MockQuestionService(questions: [])
        service.shouldThrow = true
        let vm = QuizViewModel(questionService: service)
        
        vm.startQuiz()
        
        if case .error = vm.viewState {
            // Expected behavior
        } else {
            XCTFail("Expected viewState to be .error")
        }
    }

    func testCatalogCountsComeFromLoadedQuestionsAndLoadOnlyOnce() throws {
        let service = MockQuestionService(questions: try makeMockQuestions())
        let vm = QuizViewModel(questionService: service)

        vm.loadQuestionCatalog()

        XCTAssertTrue(vm.isCatalogLoaded)
        XCTAssertNil(vm.catalogError)
        XCTAssertEqual(vm.availableQuestionCount, 2)
        XCTAssertEqual(vm.questionCount(for: .softwareEngineering), 2)
        XCTAssertEqual(vm.questionCount(for: .swiftAndApple), 0)
        XCTAssertEqual(vm.viewState, .idle)

        service.shouldThrow = true
        vm.loadQuestionCatalog()
        XCTAssertEqual(vm.availableQuestionCount, 2, "A loaded catalog is cached for the ViewModel lifetime")
    }

    func testCatalogLoadFailureCanBeRetried() throws {
        let service = MockQuestionService(questions: try makeMockQuestions())
        service.shouldThrow = true
        let vm = QuizViewModel(questionService: service)

        vm.loadQuestionCatalog()
        XCTAssertFalse(vm.isCatalogLoaded)
        XCTAssertNotNil(vm.catalogError)

        service.shouldThrow = false
        vm.loadQuestionCatalog()
        XCTAssertTrue(vm.isCatalogLoaded)
        XCTAssertNil(vm.catalogError)
        XCTAssertEqual(vm.availableQuestionCount, 2)
    }

    func testRetryLastQuizRepeatsSpecificCategoryAfterServiceRecovers() throws {
        let service = MockQuestionService(questions: try makeMockQuestions())
        service.shouldThrow = true
        let vm = QuizViewModel(questionService: service)

        vm.startQuiz(category: .softwareEngineering)
        guard case .error = vm.viewState else {
            XCTFail("Expected the initial category request to fail")
            return
        }

        service.shouldThrow = false
        vm.retryLastQuiz()

        XCTAssertEqual(service.categoryRequests, [.softwareEngineering, .softwareEngineering])
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.totalQuestions, 2)
        XCTAssertEqual(vm.currentQuestion?.category, .softwareEngineering)
        vm.resetToMenu()
    }

    func testRetryLastQuizRepeatsMixedRequestAfterServiceRecovers() throws {
        let service = MockQuestionService(questions: try makeMockQuestions())
        service.shouldThrow = true
        let vm = QuizViewModel(questionService: service)

        vm.startQuiz()
        guard case .error = vm.viewState else {
            XCTFail("Expected the initial mixed request to fail")
            return
        }

        service.shouldThrow = false
        vm.retryLastQuiz()

        XCTAssertEqual(service.allQuestionsRequestCount, 2)
        XCTAssertTrue(service.categoryRequests.isEmpty)
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.totalQuestions, 2)
        vm.resetToMenu()
    }

    func testInvalidAnswerIndexLeavesRoundPlaying() throws {
        let vm = QuizViewModel(questionService: MockQuestionService(questions: try makeMockQuestions()))
        vm.startQuiz()
        let initialTime = vm.timeRemaining

        vm.selectAnswer(at: -1)
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertNil(vm.selectedAnswerIndex)
        XCTAssertEqual(vm.timeRemaining, initialTime)

        vm.selectAnswer(at: 4)
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertNil(vm.selectedAnswerIndex)
        XCTAssertEqual(vm.timeRemaining, initialTime)
    }
    
    /// Verifies the full user progression loop: answering Q1, advancing to Q2, answering Q2, and transitioning to `.finished`.
    func testSelectAnswerAndAdvanceToFinish() throws {
        let questions = try makeMockQuestions()
        let service = MockQuestionService(questions: questions)
        let vm = QuizViewModel(questionService: service)
        
        vm.startQuiz()
        guard let firstQ = vm.currentQuestion else {
            XCTFail("No current question found")
            return
        }
        
        // Select correct answer on first question
        vm.selectAnswer(at: firstQ.correctAnswerIndex)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: firstQ.correctAnswerIndex, isCorrect: true))
        XCTAssertEqual(vm.streak, 1)
        XCTAssertGreaterThan(vm.currentScore, 0)
        
        // Advance to Q2
        vm.nextQuestion()
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.questionIndex, 1)
        
        guard let secondQ = vm.currentQuestion else {
            XCTFail("No second question found")
            return
        }
        
        // Select answer on second question
        vm.selectAnswer(at: secondQ.correctAnswerIndex)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: secondQ.correctAnswerIndex, isCorrect: true))
        
        // Advance to complete session
        vm.nextQuestion()
        if case .finished(let record) = vm.viewState {
            XCTAssertEqual(record.totalQuestions, 2)
            XCTAssertEqual(record.correctAnswers, 2)
            XCTAssertEqual(record.accuracyPercentage, 100)
        } else {
            XCTFail("Expected viewState to be .finished")
        }
    }
    
    /// Verifies that `resetToMenu()` thoroughly cleans up session state and cancels timers.
    func testResetToMenu() throws {
        let questions = try makeMockQuestions()
        let service = MockQuestionService(questions: questions)
        let vm = QuizViewModel(questionService: service)
        
        vm.startQuiz()
        vm.resetToMenu()
        
        XCTAssertEqual(vm.viewState, .idle)
        XCTAssertNil(vm.currentQuestion)
        XCTAssertEqual(vm.currentScore, 0)
        XCTAssertEqual(vm.streak, 0)
    }
}
