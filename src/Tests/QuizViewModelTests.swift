import XCTest
@testable import TrainYourBrainCore

@MainActor
final class QuizViewModelTests: XCTestCase {
    
    private final class MockQuestionService: QuestionServiceProtocol, @unchecked Sendable {
        let questions: [Question]
        var shouldThrow: Bool = false
        
        init(questions: [Question]) {
            self.questions = questions
        }
        
        func loadAllQuestions() throws -> [Question] {
            if shouldThrow {
                throw QuestionServiceError.emptyQuestionSet
            }
            return questions
        }
        
        func loadQuestions(for category: QuizCategory) throws -> [Question] {
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
    
    func testStartQuizHandlesServiceError() {
        let service = MockQuestionService(questions: [])
        service.shouldThrow = true
        let vm = QuizViewModel(questionService: service)
        
        vm.startQuiz()
        
        if case .error = vm.viewState {
            // Success
        } else {
            XCTFail("Expected viewState to be .error")
        }
    }
    
    func testSelectAnswerAndAdvanceToFinish() throws {
        let questions = try makeMockQuestions()
        let service = MockQuestionService(questions: questions)
        let vm = QuizViewModel(questionService: service)
        
        vm.startQuiz()
        guard let firstQ = vm.currentQuestion else {
            XCTFail("No current question")
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
            XCTFail("No second question")
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
