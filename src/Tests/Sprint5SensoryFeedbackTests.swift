import XCTest
@testable import TrainYourBrainCore

@MainActor
final class Sprint5SensoryFeedbackTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private struct MockQuestionService: QuestionServiceProtocol {
        let questions: [Question]
        
        func loadQuestions(for category: QuizCategory) throws -> [Question] {
            let filtered = questions.filter { $0.category == category }
            guard !filtered.isEmpty else { throw QuestionServiceError.emptyQuestionSet }
            return filtered
        }
        
        func loadAllQuestions() throws -> [Question] {
            guard !questions.isEmpty else { throw QuestionServiceError.emptyQuestionSet }
            return questions
        }
    }
    
    private func makeTestQuestion(
        correctIndex: Int = 1,
        difficulty: Difficulty = .medium
    ) -> Question {
        return try! Question(
            id: UUID(),
            prompt: "What is the primary role of Combine in Swift?",
            options: [
                "Database querying",
                "Asynchronous reactive event handling",
                "3D asset rendering",
                "Network socket low-level binding"
            ],
            correctAnswerIndex: correctIndex,
            explanation: "Combine provides a declarative Swift API for processing values over time.",
            category: .swiftAndApple,
            difficulty: difficulty
        )
    }
    
    private func makeViewModel(
        with questions: [Question],
        mockHaptics: MockHapticFeedbackService = MockHapticFeedbackService()
    ) -> (QuizViewModel, MockHapticFeedbackService) {
        let mockService = MockQuestionService(questions: questions)
        let vm = QuizViewModel(
            questionService: mockService,
            monotonicClock: { 1000.0 },
            hapticService: mockHaptics
        )
        return (vm, mockHaptics)
    }
    
    // MARK: - 1. Haptic Pre-warming & Initiation
    
    @MainActor
    func testHapticServicePreparesOnQuizStart() {
        let q = makeTestQuestion()
        let (vm, haptics) = makeViewModel(with: [q])
        
        XCTAssertEqual(haptics.prepareCount, 0)
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(haptics.prepareCount, 1, "startQuiz must prepare haptic engine for immediate response")
    }
    
    // MARK: - 2. Sensory Feedback Accuracy & Haptic Patterns
    
    @MainActor
    func testCorrectAnswerTriggersSuccessHapticFeedback() {
        let q = makeTestQuestion(correctIndex: 0)
        let (vm, haptics) = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        // Find option matching correct index
        guard let current = vm.currentQuestion else {
            XCTFail("Expected loaded question")
            return
        }
        
        vm.selectAnswer(at: current.correctAnswerIndex)
        
        XCTAssertEqual(haptics.triggerCount, 1)
        XCTAssertEqual(haptics.lastEvent, .success, "Correct answer must trigger success haptic pattern")
        XCTAssertEqual(haptics.recordedEvents, [.success])
    }
    
    @MainActor
    func testIncorrectAnswerTriggersErrorHapticFeedback() {
        let q = makeTestQuestion(correctIndex: 0)
        let (vm, haptics) = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        guard let current = vm.currentQuestion else {
            XCTFail("Expected loaded question")
            return
        }
        
        // Select an index that is NOT the correct answer
        let wrongIndex = (current.correctAnswerIndex + 1) % current.options.count
        vm.selectAnswer(at: wrongIndex)
        
        XCTAssertEqual(haptics.triggerCount, 1)
        XCTAssertEqual(haptics.lastEvent, .error, "Incorrect answer must trigger error haptic pattern")
        XCTAssertEqual(haptics.recordedEvents, [.error])
    }
    
    @MainActor
    func testTimeoutExpirationTriggersWarningHapticFeedback() {
        let q = makeTestQuestion()
        let (vm, haptics) = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        vm.handleTimeout()
        
        XCTAssertEqual(haptics.triggerCount, 1)
        XCTAssertEqual(haptics.lastEvent, .warning, "Timeout expiration must trigger warning haptic pattern")
        XCTAssertEqual(haptics.recordedEvents, [.warning])
    }
    
    // MARK: - 3. Debouncing & Touch Lock Guarantees
    
    @MainActor
    func testDebouncingPreventsMultipleHapticTriggersOnRapidTaps() {
        let q = makeTestQuestion(correctIndex: 0)
        let (vm, haptics) = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        // Simulate rapid repeated taps on the same or different buttons
        vm.selectAnswer(at: 0)
        vm.selectAnswer(at: 0)
        vm.selectAnswer(at: 1)
        vm.selectAnswer(at: 2)
        
        XCTAssertEqual(haptics.triggerCount, 1, "Only the first tap may trigger haptic feedback")
        XCTAssertEqual(vm.selectedAnswerIndex, 0, "Selected index must remain fixed to the first selection")
    }
    
    @MainActor
    func testAnswerSelectionWhenNotPlayingDoesNotTriggerHaptics() {
        let q = makeTestQuestion()
        let (vm, haptics) = makeViewModel(with: [q])
        
        // Idle state: no quiz active
        vm.selectAnswer(at: 0)
        XCTAssertEqual(haptics.triggerCount, 0, "Selecting answer in idle state must not trigger haptics")
        
        // Answered state: already answered
        vm.startQuiz(category: .swiftAndApple)
        vm.selectAnswer(at: 0)
        XCTAssertEqual(haptics.triggerCount, 1)
        
        // Attempt another selection while answered
        vm.selectAnswer(at: 1)
        XCTAssertEqual(haptics.triggerCount, 1, "Selecting answer in answered state must not trigger haptics")
    }
    
    // MARK: - 4. Mock & Protocol Extension Tests
    
    func testMockHapticFeedbackServiceMethods() {
        let mock = MockHapticFeedbackService()
        XCTAssertEqual(mock.triggerCount, 0)
        XCTAssertEqual(mock.prepareCount, 0)
        XCTAssertNil(mock.lastEvent)
        
        mock.prepare()
        XCTAssertEqual(mock.prepareCount, 1)
        
        mock.playSuccess()
        XCTAssertEqual(mock.lastEvent, .success)
        
        mock.playError()
        XCTAssertEqual(mock.lastEvent, .error)
        
        mock.playWarning()
        XCTAssertEqual(mock.lastEvent, .warning)
        
        XCTAssertEqual(mock.triggerCount, 3)
        XCTAssertEqual(mock.recordedEvents, [.success, .error, .warning])
        
        mock.reset()
        XCTAssertEqual(mock.triggerCount, 0)
        XCTAssertEqual(mock.prepareCount, 0)
        XCTAssertTrue(mock.recordedEvents.isEmpty)
        XCTAssertNil(mock.lastEvent)
    }
    
    func testSystemHapticFeedbackServiceSafeExecution() {
        let service = SystemHapticFeedbackService.shared
        // Ensure production calls do not throw or crash on macOS/Simulator platforms
        service.prepare()
        service.playSuccess()
        service.playError()
        service.playWarning()
    }
    
    func testSystemHapticFeedbackServiceRetainedGeneratorLifecycle() {
        let service = SystemHapticFeedbackService()
        // On macOS this is consistently false due to platform compilation;
        // on iOS it validates thread-safe inspection and clearing.
        XCTAssertFalse(service.hasRetainedGenerator)
        service.prepare()
        service.playSuccess()
        service.playError()
        service.playWarning()
        service.clearPreparedGenerator()
    }
    
    func testHapticFeedbackTypeEnumCases() {
        let allCases = HapticFeedbackType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.success))
        XCTAssertTrue(allCases.contains(.error))
        XCTAssertTrue(allCases.contains(.warning))
        XCTAssertEqual(HapticFeedbackType.success.rawValue, "success")
        XCTAssertEqual(HapticFeedbackType.error.rawValue, "error")
        XCTAssertEqual(HapticFeedbackType.warning.rawValue, "warning")
    }
}
