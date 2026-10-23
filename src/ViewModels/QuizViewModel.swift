import Foundation
import Combine
import SwiftUI

/// Main ViewModel coordinating game loop states, countdown timer, and scoring for SwiftUI views.
///
/// Architecture & Concurrency:
/// - Adheres strictly to the MVVM pattern: encapsulates all mutable state and business transitions.
/// - Bound to `@MainActor` to guarantee that all published mutations and UI re-renders execute safely
///   on the main dispatch thread without race conditions.
/// - Manages high-precision reactive timer subscriptions (10 Hz) using Combine's `Timer.publish`.
@MainActor
public final class QuizViewModel: ObservableObject {
    
    /// High-precision timer frequency in Hertz (10 updates per second).
    public static let timerFrequencyHz: Double = 10.0
    
    /// High-precision timer update interval in seconds (0.1s).
    public static let timerInterval: TimeInterval = 1.0 / timerFrequencyHz
    
    /// Operational presentation states consumed by SwiftUI views to drive view transitions.
    public enum ViewState: Equatable {
        case idle
        case loading
        case playing
        case answered(selectedIndex: Int, isCorrect: Bool)
        case finished(ScoreRecord)
        case error(String)
    }
    
    // MARK: - Published Properties (Observable State)
    
    /// Current phase in the UI lifecycle (determines whether to render HomeView, QuizView, or ResultView).
    @Published public private(set) var viewState: ViewState = .idle
    
    /// Active question currently being answered by the user.
    @Published public private(set) var currentQuestion: Question?
    
    /// 0-based index of the current question within the active round.
    @Published public private(set) var questionIndex: Int = 0
    
    /// Total count of questions in the current round.
    @Published public private(set) var totalQuestions: Int = 0
    
    /// Running score tally accumulated in the current session.
    @Published public private(set) var currentScore: Int = 0
    
    /// Active consecutive streak of correct answers.
    @Published public private(set) var streak: Int = 0
    
    /// Seconds remaining on the active question's countdown timer.
    @Published public private(set) var timeRemaining: TimeInterval = 15.0
    
    /// Index of the option selected by the user for the current question (or nil if awaiting input).
    @Published public private(set) var selectedAnswerIndex: Int?
    
    /// Catalog metadata for the home screen, independent of the active round.
    @Published public private(set) var availableQuestionCounts: [QuizCategory: Int] = [:]
    @Published public private(set) var isCatalogLoaded = false
    @Published public private(set) var catalogError: String?

    public var availableQuestionCount: Int {
        availableQuestionCounts.values.reduce(0, +)
    }

    public func questionCount(for category: QuizCategory) -> Int {
        availableQuestionCounts[category, default: 0]
    }

    // MARK: - Dependencies & Private State
    
    /// Injected question loading service.
    private let questionService: QuestionServiceProtocol
    
    /// Underlying aggregate root managing pure domain progression.
    private var session: QuizSession?

    /// Category requested for the most recent round, retained so the error screen can retry it.
    private var lastRequestedCategory: QuizCategory?
    
    /// Combine cancellable handle for the active high-frequency countdown timer.
    private var timerCancellable: AnyCancellable?
    
    /// Timestamp of the most recent timer firing to calculate real elapsed duration without drift.
    private var lastTickTimestamp: Date?
    
    /// Monotonic timestamp of the most recent timer tick for drift compensation.
    private var lastTickMonotonic: TimeInterval?
    
    /// Timestamp recording when the app entered background or inactive state during gameplay.
    private var backgroundTimestamp: Date?
    
    /// Monotonic timestamp recording when the app entered background (immune to clock tampering).
    private var backgroundMonotonicTimestamp: TimeInterval?
    
    /// Monotonic time provider closure returning seconds in continuous time.
    private let monotonicClock: () -> TimeInterval
    
    /// Default fallback duration in seconds if difficulty-specific limits are absent.
    private let standardTimeLimit: TimeInterval = 15.0
    
    /// Default monotonic time provider utilizing system uptime in seconds.
    public nonisolated static func defaultMonotonicClock() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
    
    /// Designated initializer accepting dependency injection for testability.
    public init(
        questionService: QuestionServiceProtocol = LocalQuestionService(),
        monotonicClock: @escaping () -> TimeInterval = QuizViewModel.defaultMonotonicClock
    ) {
        self.questionService = questionService
        self.monotonicClock = monotonicClock
    }
    
    /// Loads counts once per ViewModel lifetime. A failed load can be retried from HomeView.
    /// Catalog errors leave navigation idle so that recovery stays on the home screen.
    public func loadQuestionCatalog() {
        guard !isCatalogLoaded else { return }
        do {
            let questions = try questionService.loadAllQuestions()
            guard !questions.isEmpty else { throw QuestionServiceError.emptyQuestionSet }
            availableQuestionCounts = Dictionary(grouping: questions, by: \.category).mapValues { $0.count }
            catalogError = nil
            isCatalogLoaded = true
        } catch {
            availableQuestionCounts = [:]
            catalogError = error.localizedDescription
        }
    }

    // MARK: - Game Lifecycle Actions
    
    /// Initiates a fresh quiz round, optionally filtered by a specific category domain.
    ///
    /// Loads questions from the service, shuffles question order and answer options,
    /// instantiates a new `QuizSession`, synchronizes published properties, and begins the timer.
    public func startQuiz(category: QuizCategory? = nil) {
        lastRequestedCategory = category
        viewState = .loading
        stopTimer()
        
        do {
            let loadedQuestions: [Question]
            if let category = category {
                loadedQuestions = try questionService.loadQuestions(for: category)
            } else {
                loadedQuestions = try questionService.loadAllQuestions()
            }
            
            guard !loadedQuestions.isEmpty else {
                throw QuestionServiceError.emptyQuestionSet
            }
            
            // Randomize question order and options for session replayability
            let shuffledQuestions = loadedQuestions.shuffled().map { $0.fisherYatesShuffled() }
            var newSession = QuizSession(questions: shuffledQuestions, category: category)
            newSession.start()
            
            self.session = newSession
            self.totalQuestions = newSession.totalQuestions
            self.selectedAnswerIndex = nil
            self.questionIndex = 0
            self.currentScore = 0
            self.streak = 0
            self.syncFromSession()
            self.startTimer()
            self.viewState = .playing
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }

    /// Repeats the last round request after a recoverable question-loading error.
    public func retryLastQuiz() {
        startQuiz(category: lastRequestedCategory)
    }
    
    /// Invoked when the user selects a multiple-choice option.
    ///
    /// Stops the timer, records the selection in the domain session, updates running score,
    /// and transitions to `.answered` to display immediate pedagogical feedback.
    public func selectAnswer(at index: Int) {
        guard viewState == .playing,
              var currentSession = session,
              let question = currentSession.currentQuestion,
              question.options.indices.contains(index) else { return }

        stopTimer()
        backgroundTimestamp = nil
        selectedAnswerIndex = index
        let isCorrect = currentSession.submitAnswer(optionIndex: index)
        self.session = currentSession
        self.currentScore = currentSession.score
        self.streak = currentSession.currentStreak
        
        self.viewState = .answered(selectedIndex: index, isCorrect: isCorrect)
    }
    
    /// Advances the quiz to the subsequent question or transitions to `.finished` when all are completed.
    public func nextQuestion() {
        guard case .answered = viewState, var currentSession = session else { return }
        
        currentSession.advanceToNext()
        self.session = currentSession
        backgroundTimestamp = nil
        
        if case .completed(let record) = currentSession.state {
            stopTimer()
            self.viewState = .finished(record)
        } else {
            selectedAnswerIndex = nil
            syncFromSession()
            self.viewState = .playing
            startTimer()
        }
    }
    
    /// Cancels any active round and returns the application state to the home menu.
    public func resetToMenu() {
        stopTimer()
        backgroundTimestamp = nil
        session = nil
        currentQuestion = nil
        questionIndex = 0
        totalQuestions = 0
        currentScore = 0
        streak = 0
        timeRemaining = standardTimeLimit
        selectedAnswerIndex = nil
        lastRequestedCategory = nil
        viewState = .idle
    }
    
    // MARK: - Timer Mechanics & High-Frequency Countdown
    
    /// Starts or resumes a high-frequency (10 Hz, 0.1s interval) Combine timer updating `timeRemaining`.
    ///
    /// Real-Time Drift Compensation:
    /// Instead of decrementing by a fixed constant, each tick computes the actual elapsed duration
    /// since the previous firing, eliminating cumulative timer drift caused by main runloop contention.
    public func startTimer(initialRemaining: TimeInterval? = nil) {
        stopTimer()
        if let remaining = initialRemaining {
            timeRemaining = max(remaining, 0.0)
        } else {
            let questionTimeLimit = currentQuestion?.difficulty.timeLimitSeconds ?? standardTimeLimit
            timeRemaining = questionTimeLimit
        }
        
        guard timeRemaining > 0 else {
            handleTimeout()
            return
        }
        
        lastTickTimestamp = Date()
        lastTickMonotonic = monotonicClock()
        timerCancellable = Timer.publish(every: Self.timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentTickDate in
                guard let self = self else { return }
                let currentMonotonic = self.monotonicClock()
                let lastMono = self.lastTickMonotonic ?? currentMonotonic
                self.lastTickMonotonic = currentMonotonic
                self.lastTickTimestamp = currentTickDate
                let realDelta = max(currentMonotonic - lastMono, 0.0)
                self.tickTimer(delta: realDelta)
            }
    }
    
    /// Cancels and deallocates the active timer subscription.
    public func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        lastTickTimestamp = nil
        lastTickMonotonic = nil
    }
    
    /// Advances countdown time by `delta` seconds and triggers timeout handling if elapsed.
    ///
    /// Exposed for deterministic unit testing and simulated ticks without asynchronous delays.
    public func tickTimer(delta: TimeInterval) {
        guard viewState == .playing else { return }
        if timeRemaining > delta {
            timeRemaining -= delta
        } else {
            timeRemaining = 0.0
            handleTimeout()
        }
    }
    
    /// Handles application scene lifecycle transitions to preserve game fairness and anti-cheat constraints.
    ///
    /// Monotonic Anti-Cheat Guarantee:
    /// In addition to wall-clock `Date()`, the system samples a monotonic continuous clock (`systemUptime`).
    /// If the device clock is rewound or shifted while backgrounded, the monotonic clock detects the true
    /// physical elapsed duration, neutralizing attempts to evade timeouts by manipulating device settings.
    ///
    /// - Parameters:
    ///   - phase: The updated SwiftUI `ScenePhase` (.active, .inactive, or .background).
    ///   - currentDate: Timestamp provider defaulting to `Date()`, injectable for deterministic testing.
    ///   - monotonicTime: Optional simulated monotonic timestamp in seconds for deterministic testing.
    public func handleScenePhaseChange(
        to phase: ScenePhase,
        currentDate: Date = Date(),
        monotonicTime: TimeInterval? = nil
    ) {
        let currentMonotonic = monotonicTime ?? monotonicClock()

        switch phase {
        case .inactive, .background:
            if viewState == .playing && timerCancellable != nil {
                backgroundTimestamp = currentDate
                backgroundMonotonicTimestamp = currentMonotonic
                stopTimer()
            }
        case .active:
            guard let timestamp = backgroundTimestamp else { return }
            let bgMonotonic = backgroundMonotonicTimestamp ?? currentMonotonic
            backgroundTimestamp = nil
            backgroundMonotonicTimestamp = nil
            
            guard viewState == .playing else { return }
            
            let wallClockElapsed = currentDate.timeIntervalSince(timestamp)
            let monotonicElapsed = currentMonotonic - bgMonotonic
            let questionLimit = currentQuestion?.difficulty.timeLimitSeconds ?? standardTimeLimit
            
            // Anti-cheat 1: Flagrant retrograde clock jump on wall clock (> 500ms backwards)
            if wallClockElapsed < -0.5 {
                timeRemaining = 0.0
                handleTimeout()
                return
            }
            
            // Anti-cheat 2: Monotonic clock discrepancy resolution.
            // If the user remained backgrounded for 30s and rewound the system clock 29s (so wall clock = 1s),
            // monotonicElapsed (30s) takes precedence, ensuring the user cannot evade timeouts.
            let effectiveElapsed: TimeInterval
            if monotonicTime != nil {
                effectiveElapsed = max(monotonicElapsed, 0.0)
            } else if monotonicElapsed > max(wallClockElapsed, 0.0) && (monotonicElapsed - wallClockElapsed) > 1.0 {
                effectiveElapsed = monotonicElapsed
            } else {
                effectiveElapsed = max(wallClockElapsed, 0.0)
            }
            
            if effectiveElapsed >= timeRemaining {
                timeRemaining = 0.0
                handleTimeout()
            } else {
                timeRemaining = min(timeRemaining - effectiveElapsed, questionLimit)
                startTimer(initialRemaining: timeRemaining)
            }
        @unknown default:
            break
        }
    }
    
    /// Handles expiration of the countdown timer without user input.
    public func handleTimeout() {
        guard viewState == .playing, var currentSession = session else { return }
        stopTimer()
        backgroundTimestamp = nil
        currentSession.recordTimeout()
        self.session = currentSession
        self.streak = currentSession.currentStreak
        self.selectedAnswerIndex = -1
        self.viewState = .answered(selectedIndex: -1, isCorrect: false)
    }
    
    // MARK: - State Synchronization
    
    /// Pulls current progress values from the domain `QuizSession` into published view model properties.
    private func syncFromSession() {
        guard let session = session else { return }
        self.currentQuestion = session.currentQuestion
        self.questionIndex = session.currentIndex
        self.currentScore = session.score
        self.streak = session.currentStreak
    }
}
