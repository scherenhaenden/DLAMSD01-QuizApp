import Foundation
import Combine

/// Main ViewModel coordinating game loop states, countdown timer, and scoring for SwiftUI views.
/// Annotated with `@MainActor` to guarantee all UI mutations execute safely on the main thread.
@MainActor
public final class QuizViewModel: ObservableObject {
    
    public enum ViewState: Equatable {
        case idle
        case loading
        case playing
        case answered(selectedIndex: Int, isCorrect: Bool)
        case finished(ScoreRecord)
        case error(String)
    }
    
    // MARK: - Published Properties
    
    @Published public private(set) var viewState: ViewState = .idle
    @Published public private(set) var currentQuestion: Question?
    @Published public private(set) var questionIndex: Int = 0
    @Published public private(set) var totalQuestions: Int = 0
    @Published public private(set) var currentScore: Int = 0
    @Published public private(set) var streak: Int = 0
    @Published public private(set) var timeRemaining: TimeInterval = 15.0
    @Published public private(set) var selectedAnswerIndex: Int?
    
    // MARK: - Dependencies & Private State
    
    private let questionService: QuestionServiceProtocol
    private var session: QuizSession?
    private var timerCancellable: AnyCancellable?
    private let standardTimeLimit: TimeInterval = 15.0
    
    public init(questionService: QuestionServiceProtocol = LocalQuestionService()) {
        self.questionService = questionService
    }
    
    // MARK: - Game Lifecycle Actions
    
    /// Starts a new quiz session with an optional category filter.
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
            
            // Randomize questions for session replayability
            let shuffledQuestions = loadedQuestions.shuffled().map { $0.shuffledOptions() }
            var newSession = QuizSession(questions: shuffledQuestions, category: category)
            newSession.start()
            
            self.session = newSession
            self.totalQuestions = newSession.totalQuestions
            self.syncFromSession()
            self.startTimer()
            self.viewState = .playing
        } catch {
            self.viewState = .error(error.localizedDescription)
        }
    }
    
    /// User selects an answer option.
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
    
    /// Advances to next question after feedback review.
    public func nextQuestion() {
        guard var currentSession = session else { return }
        
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
    
    /// Resets the game back to the menu/idle state.
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
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
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
    
    private func syncFromSession() {
        guard let session = session else { return }
        self.currentQuestion = session.currentQuestion
        self.questionIndex = session.currentIndex
        self.currentScore = session.score
        self.streak = session.currentStreak
    }
}
