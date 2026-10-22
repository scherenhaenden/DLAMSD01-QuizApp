import Foundation

/// Aggregate root managing the lifecycle, active state, and scoring progression of a quiz game round.
public struct QuizSession: Equatable, Sendable {
    
    public enum State: Equatable, Sendable {
        case idle
        case inProgress
        case questionAnswered(selectedIndex: Int, isCorrect: Bool)
        case completed(ScoreRecord)
    }
    
    public private(set) var questions: [Question]
    public private(set) var currentIndex: Int
    public private(set) var userSelections: [Int?]
    public private(set) var score: Int
    public private(set) var currentStreak: Int
    public private(set) var bestStreak: Int
    public private(set) var state: State
    public let startedAt: Date
    public let category: QuizCategory?
    
    public init(questions: [Question], category: QuizCategory? = nil) {
        self.questions = questions
        self.currentIndex = 0
        self.userSelections = Array(repeating: nil, count: questions.count)
        self.score = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.state = questions.isEmpty ? .completed(ScoreRecord(score: 0, totalQuestions: 0, correctAnswers: 0)) : .idle
        self.startedAt = Date()
        self.category = category
    }
    
    public var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    public var totalQuestions: Int {
        return questions.count
    }
    
    public var progressRatio: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(currentIndex + 1) / Double(totalQuestions)
    }
    
    public var hasNextQuestion: Bool {
        return currentIndex + 1 < questions.count
    }
    
    public var correctAnswersCount: Int {
        var count = 0
        for (idx, question) in questions.enumerated() {
            if let selected = userSelections[idx], selected == question.correctAnswerIndex {
                count += 1
            }
        }
        return count
    }
    
    // MARK: - Mutating Domain Operations
    
    /// Starts the active session if questions are available.
    public mutating func start() {
        guard !questions.isEmpty else { return }
        self.state = .inProgress
    }
    
    /// Records an answer selection for the current question and updates scoring and streak.
    /// Returns whether the answer was correct.
    @discardableResult
    public mutating func submitAnswer(optionIndex: Int) -> Bool {
        guard state == .inProgress, let question = currentQuestion else {
            return false
        }
        
        guard optionIndex >= 0 && optionIndex < question.options.count else {
            return false
        }
        
        userSelections[currentIndex] = optionIndex
        let isCorrect = question.isCorrect(selectedOptionIndex: optionIndex)
        
        if isCorrect {
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            // Scoring algorithm: base points * streak multiplier bonus
            let streakMultiplier = 1.0 + (Double(currentStreak - 1) * 0.1)
            let pointsEarned = Int((Double(question.difficulty.basePoints) * streakMultiplier).rounded())
            score += pointsEarned
        } else {
            currentStreak = 0
        }
        
        self.state = .questionAnswered(selectedIndex: optionIndex, isCorrect: isCorrect)
        return isCorrect
    }
    
    /// Records a timeout when the user fails to answer before the countdown finishes.
    public mutating func recordTimeout() {
        guard state == .inProgress else { return }
        userSelections[currentIndex] = nil
        currentStreak = 0
        self.state = .questionAnswered(selectedIndex: -1, isCorrect: false)
    }
    
    /// Advances the cursor to the subsequent question or finalizes the session if completed.
    public mutating func advanceToNext() {
        if hasNextQuestion {
            currentIndex += 1
            state = .inProgress
        } else {
            let finalRecord = ScoreRecord(
                score: score,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswersCount,
                streakRecord: bestStreak,
                category: category,
                completedAt: Date()
            )
            state = .completed(finalRecord)
        }
    }
}
