import Foundation

/// Aggregate root managing the lifecycle, active state, and scoring progression of an active quiz game round.
///
/// Encapsulates the entire domain logic for:
/// - Advancing through questions sequentially.
/// - Evaluating user selections and computing dynamic streak bonus points.
/// - Tracking timeouts when countdown expires without user input.
/// - Transitioning across the finite state machine (`idle` -> `inProgress` -> `questionAnswered` -> `completed`).
public struct QuizSession: Equatable, Sendable {
    
    /// Finite state machine states representing the operational phases of a quiz round.
    public enum State: Equatable, Sendable {
        /// Session initialized but waiting for user to start.
        case idle
        /// Question is actively displayed with running countdown timer.
        case inProgress
        /// User has tapped an answer (or timed out); answer feedback is actively revealed.
        case questionAnswered(selectedIndex: Int, isCorrect: Bool)
        /// All questions answered; results compiled into a final `ScoreRecord`.
        case completed(ScoreRecord)
    }
    
    /// The ordered sequence of questions selected for this session.
    public private(set) var questions: [Question]
    
    /// 0-based cursor tracking the current question index.
    public private(set) var currentIndex: Int
    
    /// Recorded option selections for each question. Nil signifies unanswered or timed-out items.
    public private(set) var userSelections: [Int?]
    
    /// Cumulative points scored in this round.
    public private(set) var score: Int
    
    /// Current consecutive chain of correct answers.
    public private(set) var currentStreak: Int
    
    /// Maximum streak achieved at any point during this session.
    public private(set) var bestStreak: Int
    
    /// Current phase in the state machine.
    public private(set) var state: State
    
    /// Timestamp when this round began.
    public let startedAt: Date
    
    /// Domain focus of the session, or nil if all categories are mixed.
    public let category: QuizCategory?
    
    /// Initializes a new quiz session with the given questions bank.
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
    
    /// Returns the active `Question` at the current cursor index, or `nil` if out of bounds.
    public var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    /// Total number of questions scheduled in this round.
    public var totalQuestions: Int {
        return questions.count
    }
    
    /// Normalized progress ratio in the range `[0.0, 1.0]` for progress bar rendering.
    public var progressRatio: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(currentIndex + 1) / Double(totalQuestions)
    }
    
    /// Indicates whether another question remains after the current one.
    public var hasNextQuestion: Bool {
        return currentIndex + 1 < questions.count
    }
    
    /// Total count of correctly answered questions across the session so far.
    public var correctAnswersCount: Int {
        var count = 0
        for (idx, question) in questions.enumerated() {
            if let selected = userSelections[idx], selected == question.correctAnswerIndex {
                count += 1
            }
        }
        return count
    }
    
    /// Aggregated performance metrics broken down by category across all answered questions.
    public var categoryBreakdown: [CategoryPerformance] {
        var tallies: [String: (title: String, total: Int, correct: Int)] = [:]
        for (idx, question) in questions.enumerated() {
            let catId = question.category.rawValue
            let catTitle = question.category.displayName
            let isCorrect = (userSelections.indices.contains(idx) && userSelections[idx] == question.correctAnswerIndex)
            var current = tallies[catId] ?? (title: catTitle, total: 0, correct: 0)
            current.total += 1
            if isCorrect {
                current.correct += 1
            }
            tallies[catId] = current
        }
        
        return tallies.map { (catId, tally) in
            CategoryPerformance(
                categoryId: catId,
                categoryTitle: tally.title,
                correctCount: tally.correct,
                totalCount: tally.total
            )
        }.sorted { $0.categoryTitle < $1.categoryTitle }
    }
    
    // MARK: - Mutating Domain Operations
    
    /// Transitions the session from `idle` to `inProgress`.
    public mutating func start() {
        guard state == .idle, !questions.isEmpty else { return }
        self.state = .inProgress
    }
    
    /// Records a user's answer selection, evaluates correctness, updates streaks and awards points.
    ///
    /// Mathematical Scoring Algorithm:
    /// `pointsEarned = basePoints * (1.0 + (streak - 1) * 0.1)`
    /// Encourages high accuracy by increasing point yields by 10% per consecutive correct answer.
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
            let streakMultiplier = 1.0 + (Double(currentStreak - 1) * 0.1)
            let pointsEarned = Int((Double(question.difficulty.basePoints) * streakMultiplier).rounded())
            score += pointsEarned
        } else {
            currentStreak = 0
        }
        
        self.state = .questionAnswered(selectedIndex: optionIndex, isCorrect: isCorrect)
        return isCorrect
    }
    
    /// Invoked when the question timer runs out.
    /// Records an unanswered state (`selectedIndex = -1`), resets the active streak, and locks the question.
    public mutating func recordTimeout() {
        guard state == .inProgress else { return }
        userSelections[currentIndex] = nil
        currentStreak = 0
        self.state = .questionAnswered(selectedIndex: -1, isCorrect: false)
    }
    
    /// Advances the cursor to the subsequent question or finalizes the session if all questions are completed.
    /// Strictly guarded: only advances if the active question has been answered or timed out.
    public mutating func advanceToNext(
        completedAt: Date = Date(),
        duration: TimeInterval? = nil,
        totalResponseTime: TimeInterval? = nil
    ) {
        guard case .questionAnswered = state else { return }
        
        if hasNextQuestion {
            currentIndex += 1
            state = .inProgress
        } else {
            let elapsed = duration ?? max(0.0, completedAt.timeIntervalSince(startedAt))
            let finalRecord = ScoreRecord(
                score: score,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswersCount,
                streakRecord: bestStreak,
                category: category,
                durationSeconds: elapsed,
                totalResponseTime: totalResponseTime,
                categoryBreakdown: categoryBreakdown,
                completedAt: completedAt
            )
            state = .completed(finalRecord)
        }
    }
}
