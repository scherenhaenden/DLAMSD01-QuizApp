import Foundation

/// Value object capturing the performance metrics of a finished quiz round.
/// Supports persistence and statistical evaluation for high scores.
public struct ScoreRecord: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let score: Int
    public let totalQuestions: Int
    public let correctAnswers: Int
    public let streakRecord: Int
    public let category: QuizCategory?
    public let completedAt: Date
    
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
    
    /// Ratio of correct answers in range [0.0, 1.0].
    public var accuracyRate: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    /// Percentage formatted integer value (e.g., 85).
    public var accuracyPercentage: Int {
        return Int((accuracyRate * 100.0).rounded())
    }
    
    /// Formatted accuracy string for UI presentation.
    public var accuracyDescription: String {
        return "\(accuracyPercentage)%"
    }
    
    /// Indicates whether the round met the passing threshold (50% or higher).
    public var isPassing: Bool {
        return accuracyRate >= 0.50
    }
    
    /// Academic performance feedback tier according to standard European evaluation standards.
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
