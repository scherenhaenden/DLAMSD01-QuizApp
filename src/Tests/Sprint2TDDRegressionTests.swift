import XCTest
@testable import TrainYourBrainCore

/// TDD test suite validating the Sprint 2 bugfixes, state machine defenses, and domain invariants.
@MainActor
final class Sprint2TDDRegressionTests: XCTestCase {
    
    // MARK: - Mocks & Helpers
    
    private func makeTestQuestion(
        category: QuizCategory = .softwareEngineering,
        difficulty: Difficulty = .easy
    ) throws -> Question {
        return try Question(
            prompt: "What is Swift?",
            options: ["A compiled language", "A script", "A database", "An OS"],
            correctAnswerIndex: 0,
            explanation: "Swift is a compiled programming language developed by Apple.",
            category: category,
            difficulty: difficulty
        )
    }
    
    private final class MockService: QuestionServiceProtocol, @unchecked Sendable {
        let questions: [Question]
        init(questions: [Question]) { self.questions = questions }
        func loadAllQuestions() throws -> [Question] { questions }
        func loadQuestions(for category: QuizCategory) throws -> [Question] {
            let filtered = questions.filter { $0.category == category }
            guard !filtered.isEmpty else { throw QuestionServiceError.emptyQuestionSet }
            return filtered
        }
    }
    
    // MARK: - Finding 1: Play Again Retained Selection Bug
    
    func testPlayAgainResetsSelectedAnswerIndexAndGameState() throws {
        let q1 = try makeTestQuestion()
        let q2 = try makeTestQuestion()
        let vm = QuizViewModel(questionService: MockService(questions: [q1, q2]))
        
        // Round 1
        vm.startQuiz()
        vm.selectAnswer(at: 0)
        XCTAssertEqual(vm.selectedAnswerIndex, 0)
        
        vm.nextQuestion()
        vm.selectAnswer(at: 0)
        XCTAssertEqual(vm.selectedAnswerIndex, 0)
        
        vm.nextQuestion()
        guard case .finished = vm.viewState else {
            XCTFail("Expected finished state after answering all questions")
            return
        }
        
        // Play Again (Round 2)
        vm.startQuiz()
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertNil(vm.selectedAnswerIndex, "CRITICAL: selectedAnswerIndex must be nil on round start so buttons are not disabled!")
        XCTAssertEqual(vm.questionIndex, 0)
        XCTAssertEqual(vm.currentScore, 0)
        XCTAssertEqual(vm.streak, 0)
    }
    
    // MARK: - Finding 5: Fisher-Yates Shuffle with Index Tracking
    
    func testFisherYatesShufflePreservesCorrectAnswerTracking() throws {
        let q = try makeTestQuestion()
        let originalAnswerText = q.correctAnswerText
        
        for _ in 0..<30 {
            var rng = SystemRandomNumberGenerator()
            let shuffled = q.fisherYatesShuffled(using: &rng)
            
            XCTAssertEqual(shuffled.options.count, 4)
            XCTAssertEqual(shuffled.correctAnswerText, originalAnswerText, "Fisher-Yates must track correct index during in-place swaps")
            XCTAssertEqual(shuffled.options[shuffled.correctAnswerIndex], originalAnswerText)
        }
    }
    
    // MARK: - Finding 8: State Machine Invariant Defenses
    
    func testCannotAdvanceQuestionWithoutAnswering() throws {
        let q1 = try makeTestQuestion()
        let q2 = try makeTestQuestion()
        var session = QuizSession(questions: [q1, q2])
        session.start()
        
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertEqual(session.state, .inProgress)
        
        // Attempt to advance without answering
        session.advanceToNext()
        XCTAssertEqual(session.currentIndex, 0, "Should NOT advance cursor if question was not answered or timed out")
        XCTAssertEqual(session.state, .inProgress)
        
        // Answer, then advance
        session.submitAnswer(optionIndex: 0)
        XCTAssertEqual(session.state, .questionAnswered(selectedIndex: 0, isCorrect: true))
        
        session.advanceToNext()
        XCTAssertEqual(session.currentIndex, 1)
        XCTAssertEqual(session.state, .inProgress)
    }
    
    func testCannotRestartActiveSessionInProgress() throws {
        let q = try makeTestQuestion()
        var session = QuizSession(questions: [q])
        session.start()
        session.submitAnswer(optionIndex: 0)
        let initialScore = session.score
        
        // Attempt to call start() on an already answered / in-progress session
        session.start()
        XCTAssertEqual(session.score, initialScore, "Restarting active session should be a no-op")
    }
    
    // MARK: - Finding 9: Question Invariants (Exactly 4 Options, No Empty Options)
    
    func testQuestionRequiresExactlyFourNonEmptyOptions() {
        XCTAssertThrowsError(
            try Question(prompt: "Test", options: ["A", "B"], correctAnswerIndex: 0, explanation: "Expl", category: .softwareEngineering)
        ) { error in
            guard case Question.ValidationError.insufficientOptions(let count) = error else {
                XCTFail("Expected insufficientOptions, got \(error)")
                return
            }
            XCTAssertEqual(count, 2)
        }
        
        XCTAssertThrowsError(
            try Question(prompt: "Test", options: ["A", "B", "C"], correctAnswerIndex: 0, explanation: "Expl", category: .softwareEngineering)
        )
        
        XCTAssertThrowsError(
            try Question(prompt: "Test", options: ["A", "B", "C", "D", "E"], correctAnswerIndex: 0, explanation: "Expl", category: .softwareEngineering)
        )
        
        XCTAssertThrowsError(
            try Question(prompt: "Test", options: ["  ", "B", "C", "D"], correctAnswerIndex: 0, explanation: "Expl", category: .softwareEngineering)
        )
    }
}
