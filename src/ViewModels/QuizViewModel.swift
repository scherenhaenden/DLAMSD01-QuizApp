import Foundation
import Combine

/// Main ViewModel coordinating game loop states, countdown timer, and scoring for SwiftUI views.
///
/// Architecture & Concurrency:
/// - Adheres strictly to the MVVM pattern: encapsulates all mutable state and business transitions.
/// - Bound to `@MainActor` to guarantee that all published mutations and UI re-renders execute safely
///   on the main dispatch thread without race conditions.
/// - Manages timer subscriptions reactively using Combine's `Timer.publish`.
@MainActor
public final class QuizViewModel: ObservableObject {
    
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
    
    // MARK: - Dependencies & Private State
    
    /// Injected question loading service.
    private let questionService: QuestionServiceProtocol
    
    /// Underlying aggregate root managing pure domain progression.
    private var session: QuizSession?
    
    /// Combine cancellable handle for the active 1-second interval timer.
    private var timerCancellable: AnyCancellable?
    
    /// Default fallback duration in seconds if difficulty-specific limits are absent.
    private let standardTimeLimit: TimeInterval = 15.0
    
    /// Designated initializer accepting dependency injection for testability.
    public init(questionService: QuestionServiceProtocol = LocalQuestionService()) {
        self.questionService = questionService
    }
    
    // MARK: - Game Lifecycle Actions
    
    /// Initiates a fresh quiz round, optionally filtered by a specific category domain.
    ///
    /// Loads questions from the service, shuffles question order and answer options,
    /// instantiates a new `QuizSession`, synchronizes published properties, and begins the timer.
    public func startQuiz(category: QuizCategory? = nil) {
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
    
    /// Invoked when the user selects a multiple-choice option.
    ///
    /// Stops the timer, records the selection in the domain session, updates running score,
    /// and transitions to `.answered` to display immediate pedagogical feedback.
    public func selectAnswer(at index: Int) {
        guard viewState == .playing, var currentSession = session else { return }
        
        stopTimer()
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
        session = nil
        currentQuestion = nil
        questionIndex = 0
        totalQuestions = 0
        currentScore = 0
        streak = 0
        timeRemaining = standardTimeLimit
        selectedAnswerIndex = nil
        viewState = .idle
    }
    
    // MARK: - Timer Mechanics
    
    /// Starts a repeating 1-second Combine timer updating `timeRemaining`.
    private func startTimer() {
        stopTimer()
        let questionTimeLimit = currentQuestion?.difficulty.timeLimitSeconds ?? standardTimeLimit
        timeRemaining = questionTimeLimit
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 1.0 {
                    self.timeRemaining -= 1.0
                } else {
                    self.timeRemaining = 0.0
                    self.handleTimeout()
                }
            }
    }
    
    /// Cancels and deallocates the active timer subscription.
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    /// Handles expiration of the countdown timer without user input.
    private func handleTimeout() {
        guard viewState == .playing, var currentSession = session else { return }
        stopTimer()
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
