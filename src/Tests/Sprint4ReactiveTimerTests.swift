import XCTest
import Combine
import SwiftUI
@testable import TrainYourBrainCore

/// Unit and integration test suite verifying Sprint 4 reactive timer mechanics,
/// proportional chromatic urgency shifts, and anti-cheat scene lifecycle transitions.
@MainActor
final class Sprint4ReactiveTimerTests: XCTestCase {
    
    // MARK: - Test Doubles & Helpers
    
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
        id: UUID = UUID(),
        category: QuizCategory = .swiftAndApple,
        difficulty: Difficulty = .medium,
        correctIndex: Int = 1
    ) -> Question {
        try! Question(
            id: id,
            prompt: "What is the expected behavior for \(id.uuidString.prefix(6))?",
            options: ["Option A", "Option B", "Option C", "Option D"],
            correctAnswerIndex: correctIndex,
            explanation: "Pedagogical explanation for \(id.uuidString.prefix(6)).",
            category: category,
            difficulty: difficulty
        )
    }
    
    private func makeViewModel(with questions: [Question]) -> QuizViewModel {
        let service = MockQuestionService(questions: questions)
        return QuizViewModel(questionService: service)
    }
    
    // MARK: - 1. Timer Specification & Frequency Constants
    
    func testTimerConstantsAndFrequency() {
        XCTAssertEqual(QuizViewModel.timerFrequencyHz, 10.0, "Timer operates at 10 Hz for smooth reactive animation")
        XCTAssertEqual(QuizViewModel.timerInterval, 0.1, accuracy: 0.0001, "Interval is reciprocal of 10 Hz frequency")
    }
    
    // MARK: - 2. Dynamic Initial Durations by Difficulty
    
    func testInitialTimeRemainingMatchesQuestionDifficulty() {
        let easyQ = makeTestQuestion(difficulty: .easy)
        let medQ = makeTestQuestion(difficulty: .medium)
        let hardQ = makeTestQuestion(difficulty: .hard)
        
        // Easy round
        let vmEasy = makeViewModel(with: [easyQ])
        vmEasy.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vmEasy.timeRemaining, 20.0, "Easy questions grant 20.0 seconds")
        
        // Medium round
        let vmMed = makeViewModel(with: [medQ])
        vmMed.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vmMed.timeRemaining, 15.0, "Medium questions grant 15.0 seconds")
        
        // Hard round
        let vmHard = makeViewModel(with: [hardQ])
        vmHard.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vmHard.timeRemaining, 12.0, "Hard questions grant 12.0 seconds")
    }
    
    // MARK: - 3. Deterministic Ticking & Timeout Transition
    
    func testDeterministicTickDecrementsTimeRemaining() {
        let q = makeTestQuestion(difficulty: .medium)
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        
        vm.tickTimer(delta: 0.1)
        XCTAssertEqual(vm.timeRemaining, 14.9, accuracy: 0.0001)
        
        vm.tickTimer(delta: 4.9)
        XCTAssertEqual(vm.timeRemaining, 10.0, accuracy: 0.0001)
        XCTAssertEqual(vm.viewState, .playing)
    }
    
    func testTimeoutExpirationResetsStreakAndTransitionsToAnsweredState() {
        let q1 = makeTestQuestion(correctIndex: 0)
        let q2 = makeTestQuestion(correctIndex: 1)
        let vm = makeViewModel(with: [q1, q2])
        vm.startQuiz(category: .swiftAndApple)
        
        // Build an initial streak
        if let current = vm.currentQuestion {
            vm.selectAnswer(at: current.correctAnswerIndex)
            XCTAssertEqual(vm.streak, 1)
            vm.nextQuestion()
        }
        
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.streak, 1)
        
        // Tick past remaining time
        let currentRemaining = vm.timeRemaining
        vm.tickTimer(delta: currentRemaining + 0.5)
        
        XCTAssertEqual(vm.timeRemaining, 0.0, "Time remaining is clamped to 0.0 on timeout")
        XCTAssertEqual(vm.selectedAnswerIndex, -1, "Timeout records -1 as selected index")
        XCTAssertEqual(vm.streak, 0, "Streak resets to zero on timeout")
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: -1, isCorrect: false), "View state transitions to answered(false)")
    }
    
    func testCanAdvanceToNextQuestionAfterTimeout() {
        let q1 = makeTestQuestion()
        let q2 = makeTestQuestion()
        let vm = makeViewModel(with: [q1, q2])
        vm.startQuiz(category: .swiftAndApple)
        
        // Timeout on question 1
        vm.handleTimeout()
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: -1, isCorrect: false))
        
        // Advance to question 2
        vm.nextQuestion()
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.questionIndex, 1)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        XCTAssertNil(vm.selectedAnswerIndex)
    }
    
    // MARK: - 4. Proportional Chromatic Shifts (TimerBar)
    
    func testTimerBarUrgencyPhaseThresholds() {
        // Normal phase: progress > 50%
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 1.0), .normal)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.75), .normal)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.501), .normal)
        
        // Warning phase: 20% < progress <= 50%
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.50), .warning)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.35), .warning)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.201), .warning)
        
        // Critical phase: progress <= 20%
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.20), .critical)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.10), .critical)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: 0.0), .critical)
        XCTAssertEqual(TimerBar.resolveUrgencyPhase(progress: -0.05), .critical)
    }
    
    func testTimerBarColorMappings() {
        XCTAssertEqual(TimerBar.resolveColor(for: .normal), .blue)
        XCTAssertEqual(TimerBar.resolveColor(for: .warning), .orange)
        XCTAssertEqual(TimerBar.resolveColor(for: .critical), .red)
    }
    
    func testTimerBarDynamicProportionsAcrossDifficulties() {
        // 20-second Easy question
        let easyNormal = TimerBar(timeRemaining: 15.0, totalTime: 20.0) // 75%
        XCTAssertEqual(easyNormal.currentUrgencyPhase, .normal)
        XCTAssertEqual(easyNormal.barColor, .blue)
        
        let easyWarning = TimerBar(timeRemaining: 8.0, totalTime: 20.0) // 40%
        XCTAssertEqual(easyWarning.currentUrgencyPhase, .warning)
        XCTAssertEqual(easyWarning.barColor, .orange)
        
        let easyCritical = TimerBar(timeRemaining: 3.0, totalTime: 20.0) // 15%
        XCTAssertEqual(easyCritical.currentUrgencyPhase, .critical)
        XCTAssertEqual(easyCritical.barColor, .red)
        
        // 12-second Hard question
        let hardNormal = TimerBar(timeRemaining: 8.0, totalTime: 12.0) // 66.7%
        XCTAssertEqual(hardNormal.currentUrgencyPhase, .normal)
        
        let hardWarning = TimerBar(timeRemaining: 5.0, totalTime: 12.0) // 41.7%
        XCTAssertEqual(hardWarning.currentUrgencyPhase, .warning)
        
        let hardCritical = TimerBar(timeRemaining: 2.0, totalTime: 12.0) // 16.7%
        XCTAssertEqual(hardCritical.currentUrgencyPhase, .critical)
    }
    
    func testTimerBarProgressClampingAndEdgeCases() {
        // Exceeding total time
        let overflowBar = TimerBar(timeRemaining: 25.0, totalTime: 20.0)
        XCTAssertEqual(overflowBar.progress, 1.0)
        
        // Negative remaining time
        let negativeBar = TimerBar(timeRemaining: -5.0, totalTime: 15.0)
        XCTAssertEqual(negativeBar.progress, 0.0)
        XCTAssertEqual(negativeBar.currentUrgencyPhase, .critical)
        
        // Zero total time guard
        let zeroTotalBar = TimerBar(timeRemaining: 5.0, totalTime: 0.0)
        XCTAssertEqual(zeroTotalBar.progress, 0.0)
    }
    
    // MARK: - 5. ScenePhase Lifecycle & Anti-Cheat Validation
    
    func testBackgroundTransitionDeductsElapsedTimeOnResume() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        let startTime = Date()
        
        // User moves app to background at t = 0
        vm.handleScenePhaseChange(to: .background, currentDate: startTime)
        
        // User resumes app after 4.5 seconds in background
        let resumeTime = startTime.addingTimeInterval(4.5)
        vm.handleScenePhaseChange(to: .active, currentDate: resumeTime)
        
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.timeRemaining, 10.5, accuracy: 0.001, "4.5 seconds was deducted from remaining time")
    }
    
    func testBackgroundTransitionLongerThanRemainingTriggersAntiCheatTimeout() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        let startTime = Date()
        vm.handleScenePhaseChange(to: .inactive, currentDate: startTime)
        
        // User returns after 25 seconds (exceeds 15s limit)
        let resumeTime = startTime.addingTimeInterval(25.0)
        vm.handleScenePhaseChange(to: .active, currentDate: resumeTime)
        
        XCTAssertEqual(vm.timeRemaining, 0.0)
        XCTAssertEqual(vm.selectedAnswerIndex, -1)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: -1, isCorrect: false), "Exceeding time while backgrounded triggers immediate timeout")
    }
    
    func testBackgroundingWhenNotPlayingDoesNotAffectState() {
        let q = makeTestQuestion()
        let vm = makeViewModel(with: [q])
        
        // 1. Idle state
        let t1 = Date()
        vm.handleScenePhaseChange(to: .background, currentDate: t1)
        vm.handleScenePhaseChange(to: .active, currentDate: t1.addingTimeInterval(10.0))
        XCTAssertEqual(vm.viewState, .idle)
        
        // 2. Answered state
        vm.startQuiz(category: .swiftAndApple)
        vm.selectAnswer(at: 0)
        guard case .answered(let selectedIndex, let isCorrect) = vm.viewState else {
            XCTFail("Expected .answered viewState after selecting answer")
            return
        }
        XCTAssertEqual(selectedIndex, 0)
        
        let t2 = Date()
        vm.handleScenePhaseChange(to: .background, currentDate: t2)
        vm.handleScenePhaseChange(to: .active, currentDate: t2.addingTimeInterval(30.0))
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: 0, isCorrect: isCorrect), "Answered state is preserved across background lifecycle")
    }
    
    func testResetToMenuCleansLifecycleAndStopsTimer() {
        let q = makeTestQuestion()
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        let t1 = Date()
        vm.handleScenePhaseChange(to: .background, currentDate: t1)
        vm.resetToMenu()
        
        XCTAssertEqual(vm.viewState, .idle)
        
        // Resuming after reset should not trigger anything
        let t2 = t1.addingTimeInterval(20.0)
        vm.handleScenePhaseChange(to: .active, currentDate: t2)
        XCTAssertEqual(vm.viewState, .idle)
    }
    
    // MARK: - 6. Clock Manipulation & Retrograde Jump Anti-Cheat Regressions
    
    func testClockRewindAttemptTriggersAntiCheatTimeout() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        
        let t0 = Date()
        vm.handleScenePhaseChange(to: .background, currentDate: t0)
        
        // Simulating user setting the device clock 30 seconds into the past while in background
        let rewoundTime = t0.addingTimeInterval(-30.0)
        vm.handleScenePhaseChange(to: .active, currentDate: rewoundTime)
        
        XCTAssertEqual(vm.timeRemaining, 0.0, "Clock rewind attempt must NOT inflate timeRemaining to 45s; must clamp to 0.0")
        XCTAssertEqual(vm.selectedAnswerIndex, -1)
        XCTAssertEqual(vm.streak, 0)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: -1, isCorrect: false), "Clock rewind triggers immediate anti-cheat timeout")
    }
    
    func testSmallNegativeClockJitterDoesNotInflateTimeRemaining() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        
        let t0 = Date()
        vm.handleScenePhaseChange(to: .background, currentDate: t0)
        
        // Minor sub-second NTP clock jitter (-0.1s)
        let jitteredTime = t0.addingTimeInterval(-0.1)
        vm.handleScenePhaseChange(to: .active, currentDate: jitteredTime)
        
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertLessThanOrEqual(vm.timeRemaining, 15.0, "Time remaining must never exceed the question's difficulty limit")
        XCTAssertEqual(vm.timeRemaining, 15.0, accuracy: 0.001)
    }
    
    func testVariableDeltaTicksCompensateForRunLoopDrift() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        
        // Simulate irregular frame durations (e.g. 150ms, 250ms, 80ms)
        vm.tickTimer(delta: 0.15)
        XCTAssertEqual(vm.timeRemaining, 14.85, accuracy: 0.0001)
        
        vm.tickTimer(delta: 0.25)
        XCTAssertEqual(vm.timeRemaining, 14.60, accuracy: 0.0001)
        
        vm.tickTimer(delta: 0.08)
        XCTAssertEqual(vm.timeRemaining, 14.52, accuracy: 0.0001)
    }
    
    func testMonotonicClockNeutralizesClockRollbackTampering() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s limit
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        
        let t0 = Date()
        let monoStart: TimeInterval = 1000.0
        vm.handleScenePhaseChange(to: .background, currentDate: t0, monotonicTime: monoStart)
        
        // Attack scenario: User stays outside for 30s (monotonic clock advances by 30s),
        // but rewinds device system clock by 29s, so wall clock only appears to advance 1.0s.
        let wallDateWithRewind = t0.addingTimeInterval(1.0)
        let monoEnd = monoStart + 30.0
        
        vm.handleScenePhaseChange(to: .active, currentDate: wallDateWithRewind, monotonicTime: monoEnd)
        
        XCTAssertEqual(vm.timeRemaining, 0.0, "Monotonic clock must enforce real physical 30s elapsed duration")
        XCTAssertEqual(vm.selectedAnswerIndex, -1)
        XCTAssertEqual(vm.streak, 0)
        XCTAssertEqual(vm.viewState, .answered(selectedIndex: -1, isCorrect: false), "Clock rollback tampering is foiled by monotonic clock")
    }
    
    func testMonotonicClockAllowsLegitimateResumeWithinLimit() {
        let q = makeTestQuestion(difficulty: .medium) // 15.0s limit
        let vm = makeViewModel(with: [q])
        vm.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(vm.timeRemaining, 15.0)
        
        let t0 = Date()
        let monoStart: TimeInterval = 500.0
        vm.handleScenePhaseChange(to: .background, currentDate: t0, monotonicTime: monoStart)
        
        // Legitimate scenario: User minimizes for 5 seconds of physical time
        let wallResume = t0.addingTimeInterval(5.0)
        let monoResume = monoStart + 5.0
        
        vm.handleScenePhaseChange(to: .active, currentDate: wallResume, monotonicTime: monoResume)
        
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.timeRemaining, 10.0, accuracy: 0.001, "Remaining time accurately decrements by 5s")
    }
}
