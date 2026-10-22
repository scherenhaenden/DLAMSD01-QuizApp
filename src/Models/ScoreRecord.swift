import Foundation

/// Value object capturing the performance metrics and academic score of a finished quiz round.
///
/// Designed as an immutable record of historical performance, suitable for
/// lightweight local persistence (`UserDefaults`) and for statistical evaluation
/// in the results screen and personal best tracking.
public struct ScoreRecord: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Unique identifier for each completed round instance.
    public let id: UUID
    
    /// Total aggregate score points achieved, taking into account difficulty and streak multipliers.
    public let score: Int
    
    /// Total number of questions presented in the quiz round.
    public let totalQuestions: Int
    
    /// Count of questions correctly answered by the user.
    public let correctAnswers: Int
    
    /// Longest consecutive chain of correct answers achieved during this round.
    public let streakRecord: Int
    
    /// Category focus of the round, or `nil` if it was a mixed multi-discipline round.
    public let category: QuizCategory?
    
    /// Timestamp recording when the round concluded.
    public let completedAt: Date
    
    /// Designated initializer with defensive boundary clamping.
    public init(
        id: UUID = UUID(),
        score: Int,
        totalQuestions: Int,
        correctAnswers: Int,
        streakRecord: Int = 0,
        category: QuizCategory? = nil,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.score = max(0, score)
        self.totalQuestions = max(0, totalQuestions)
        self.correctAnswers = max(0, min(correctAnswers, totalQuestions))
        self.streakRecord = max(0, streakRecord)
        self.category = category
        self.completedAt = completedAt
    }
    
    /// Decimal ratio of correct answers in the normalized range `[0.0, 1.0]`.
    /// Returns `0.0` safely if total questions is zero to prevent division by zero.
    public var accuracyRate: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    /// Integer percentage value rounded mathematically (e.g. `85` for 85%).
    public var accuracyPercentage: Int {
        return Int((accuracyRate * 100.0).rounded())
    }
    
    /// Formatted percentage string formatted for direct display in UI widgets (e.g. `"85%"`).
    public var accuracyDescription: String {
        return "\(accuracyPercentage)%"
    }
    
    /// Indicates whether the round met the passing threshold (50% or higher according to IU grading).
    public var isPassing: Bool {
        return accuracyRate >= 0.50
    }
    
    /// Academic performance feedback tier according to standard German university grading terminology.
    /// Provides pedagogical evaluation mapped directly from the achieved accuracy percentage.
    public var academicEvaluationTier: String {
        switch accuracyPercentage {
        case 90...100:
            return "Sehr Gut (Excellent)"
        case 80..<90:
            return "Gut (Good)"
        case 65..<80:
            return "Befriedigend (Satisfactory)"
        case 50..<65:
            return "Ausreichend (Sufficient)"
        default:
            return "Nicht Bestanden (Needs Review)"
        }
    }
}
