import Foundation

/// Formal German university grade representation according to the standard Prüfungsordnung scale (1.0 to 5.0).
public struct GermanAcademicGrade: Codable, Equatable, Hashable, Sendable {
    /// Official numeric grade in German higher education (e.g., 1.0, 1.3, 2.0, 4.0, 5.0).
    public let numericValue: Double
    
    /// Official German grade title (e.g., "Sehr Gut", "Gut", "Befriedigend", "Ausreichend", "Nicht Bestanden").
    public let title: String
    
    /// English pedagogical description.
    public let localizedDescription: String
    
    /// Whether the grade satisfies the university passing threshold (grade <= 4.0).
    public let isPassing: Bool
    
    /// Standard formatting for academic transcripts, e.g. "1.3 · Sehr Gut (Excellent)".
    public var formattedGrade: String {
        if numericValue == 5.0 {
            return "5.0 · \(title) (\(localizedDescription))"
        }
        return String(format: "%.1f · %@ (%@)", numericValue, title, localizedDescription)
    }
    
    /// Derives the German university grade from the mathematical accuracy percentage.
    ///
    /// Standardized linear university grading scale (Lineare Notenskala) aligned with
    /// German higher education standards (§ 15 APO der IU Internationalen Hochschule),
    /// using a 50% passing threshold for 4.0 and 95% for 1.0 structured in 5% brackets:
    /// - 95% - 100%: 1.0 (Sehr Gut / Outstanding)
    /// - 90% - 94%:  1.3 (Sehr Gut / Excellent)
    /// - 85% - 89%:  1.7 (Gut / Very Good)
    /// - 80% - 84%:  2.0 (Gut / Good)
    /// - 75% - 79%:  2.3 (Gut / Above Average)
    /// - 70% - 74%:  2.7 (Befriedigend / Satisfactory)
    /// - 65% - 69%:  3.0 (Befriedigend / Fair)
    /// - 60% - 64%:  3.3 (Befriedigend / Acceptable)
    /// - 55% - 59%:  3.7 (Ausreichend / Sufficient)
    /// - 50% - 54%:  4.0 (Ausreichend / Pass)
    /// - < 50%:      5.0 (Nicht Bestanden / Fail)
    public init(accuracyPercentage: Int) {
        switch accuracyPercentage {
        case 95...100:
            self.numericValue = 1.0
            self.title = "Sehr Gut"
            self.localizedDescription = "Outstanding"
            self.isPassing = true
        case 90..<95:
            self.numericValue = 1.3
            self.title = "Sehr Gut"
            self.localizedDescription = "Excellent"
            self.isPassing = true
        case 85..<90:
            self.numericValue = 1.7
            self.title = "Gut"
            self.localizedDescription = "Very Good"
            self.isPassing = true
        case 80..<85:
            self.numericValue = 2.0
            self.title = "Gut"
            self.localizedDescription = "Good"
            self.isPassing = true
        case 75..<80:
            self.numericValue = 2.3
            self.title = "Gut"
            self.localizedDescription = "Above Average"
            self.isPassing = true
        case 70..<75:
            self.numericValue = 2.7
            self.title = "Befriedigend"
            self.localizedDescription = "Satisfactory"
            self.isPassing = true
        case 65..<70:
            self.numericValue = 3.0
            self.title = "Befriedigend"
            self.localizedDescription = "Fair"
            self.isPassing = true
        case 60..<65:
            self.numericValue = 3.3
            self.title = "Befriedigend"
            self.localizedDescription = "Acceptable"
            self.isPassing = true
        case 55..<60:
            self.numericValue = 3.7
            self.title = "Ausreichend"
            self.localizedDescription = "Sufficient"
            self.isPassing = true
        case 50..<55:
            self.numericValue = 4.0
            self.title = "Ausreichend"
            self.localizedDescription = "Pass"
            self.isPassing = true
        default:
            self.numericValue = 5.0
            self.title = "Nicht Bestanden"
            self.localizedDescription = "Fail"
            self.isPassing = false
        }
    }
    
    public init(
        numericValue: Double,
        title: String,
        localizedDescription: String,
        isPassing: Bool
    ) {
        self.numericValue = numericValue
        self.title = title
        self.localizedDescription = localizedDescription
        self.isPassing = isPassing
    }
}

/// Performance metrics for a single category within a round.
///
/// Uses a stable string identifier (`categoryId`) to maintain forward compatibility
/// with user-defined dynamic categories in Sprint 7 (ADR-09).
public struct CategoryPerformance: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String { categoryId }
    public let categoryId: String
    public let categoryTitle: String
    public let correctCount: Int
    public let totalCount: Int
    
    public init(
        categoryId: String,
        categoryTitle: String,
        correctCount: Int,
        totalCount: Int
    ) {
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.correctCount = max(0, min(correctCount, totalCount))
        self.totalCount = max(0, totalCount)
    }
    
    public var accuracyRate: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(correctCount) / Double(totalCount)
    }
    
    public var accuracyPercentage: Int {
        return Int((accuracyRate * 100.0).rounded())
    }
    
    public var accuracyDescription: String {
        return "\(accuracyPercentage)%"
    }
}

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
    
    /// Total duration of the round from start to finish in seconds (including explanation reading).
    public let durationSeconds: TimeInterval
    
    /// Total active response time across questions in seconds (excluding explanation reading).
    public let totalResponseTime: TimeInterval
    
    /// Breakdown of performance by category tested in this round.
    public let categoryBreakdown: [CategoryPerformance]
    
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
        durationSeconds: TimeInterval = 0.0,
        totalResponseTime: TimeInterval? = nil,
        categoryBreakdown: [CategoryPerformance] = [],
        completedAt: Date = Date()
    ) {
        self.id = id
        self.score = max(0, score)
        self.totalQuestions = max(0, totalQuestions)
        self.correctAnswers = max(0, min(correctAnswers, totalQuestions))
        self.streakRecord = max(0, streakRecord)
        self.category = category
        self.durationSeconds = max(0.0, durationSeconds)
        self.totalResponseTime = max(0.0, totalResponseTime ?? durationSeconds)
        self.categoryBreakdown = categoryBreakdown
        self.completedAt = completedAt
    }
    
    // MARK: - Codable Custom Decoding for Robust Backward Compatibility
    
    private enum CodingKeys: String, CodingKey {
        case id, score, totalQuestions, correctAnswers, streakRecord, category
        case durationSeconds, totalResponseTime, categoryBreakdown, completedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let rawScore = try container.decode(Int.self, forKey: .score)
        let rawTotal = try container.decode(Int.self, forKey: .totalQuestions)
        let rawCorrect = try container.decode(Int.self, forKey: .correctAnswers)
        let rawStreak = try container.decodeIfPresent(Int.self, forKey: .streakRecord) ?? 0
        let rawCategory = try container.decodeIfPresent(QuizCategory.self, forKey: .category)
        let rawDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .durationSeconds) ?? 0.0
        let rawResponseTime = try container.decodeIfPresent(TimeInterval.self, forKey: .totalResponseTime)
        let rawBreakdown = try container.decodeIfPresent([CategoryPerformance].self, forKey: .categoryBreakdown) ?? []
        let rawCompletedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? Date()

        // Enforce domain invariants: reject corrupt or negative values
        guard rawScore >= 0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.score], debugDescription: "Score cannot be negative: \(rawScore)")
            )
        }
        guard rawTotal >= 0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.totalQuestions], debugDescription: "Total questions cannot be negative: \(rawTotal)")
            )
        }
        guard rawCorrect >= 0 && rawCorrect <= rawTotal else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.correctAnswers], debugDescription: "Correct answers (\(rawCorrect)) must be in range 0...\(rawTotal)")
            )
        }
        guard rawStreak >= 0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.streakRecord], debugDescription: "Streak cannot be negative: \(rawStreak)")
            )
        }
        guard rawDuration >= 0.0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.durationSeconds], debugDescription: "Duration cannot be negative: \(rawDuration)")
            )
        }
        if let respTime = rawResponseTime, respTime < 0.0 {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath + [CodingKeys.totalResponseTime], debugDescription: "Total response time cannot be negative: \(respTime)")
            )
        }

        self.score = rawScore
        self.totalQuestions = rawTotal
        self.correctAnswers = rawCorrect
        self.streakRecord = rawStreak
        self.category = rawCategory
        self.durationSeconds = rawDuration
        self.totalResponseTime = max(0.0, rawResponseTime ?? rawDuration)
        self.categoryBreakdown = rawBreakdown
        self.completedAt = rawCompletedAt
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
    
    /// Official German university grade structure.
    public var germanGrade: GermanAcademicGrade {
        return GermanAcademicGrade(accuracyPercentage: accuracyPercentage)
    }
    
    /// Academic performance feedback tier according to standard German university grading terminology.
    /// Derived directly from the German academic grade to guarantee 100% semantic and textual consistency.
    public var academicEvaluationTier: String {
        switch germanGrade.title {
        case "Sehr Gut":
            return "Sehr Gut (Excellent)"
        case "Gut":
            return "Gut (Good)"
        case "Befriedigend":
            return "Befriedigend (Satisfactory)"
        case "Ausreichend":
            return "Ausreichend (Sufficient)"
        default:
            return "Nicht Bestanden (Needs Review)"
        }
    }
    
    /// Average active response time per question in seconds (excluding pedagogical reading time).
    public var averageResponseTime: TimeInterval {
        guard totalQuestions > 0 else { return 0.0 }
        return totalResponseTime / Double(totalQuestions)
    }
    
    /// Formatted elapsed duration string (e.g. `"1m 42s"` or `"42s"`).
    public var formattedDuration: String {
        let total = Int(durationSeconds.rounded())
        let mins = total / 60
        let secs = total % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    /// Formatted average speed per question (e.g. `"4.2s"`).
    public var formattedAverageSpeed: String {
        return String(format: "%.1fs", averageResponseTime)
    }
}

// MARK: - Comparable

extension ScoreRecord: Comparable {
    /// Canonical ordering for performance evaluation, leaderboard ranking, and tie-breaking.
    ///
    /// Evaluates in priority order:
    /// 1. Score points (higher is better)
    /// 2. Accuracy percentage (higher is better)
    /// 3. Streak record (higher is better)
    /// 4. Completion date (newer is better)
    public static func < (lhs: ScoreRecord, rhs: ScoreRecord) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score < rhs.score
        }
        if lhs.accuracyPercentage != rhs.accuracyPercentage {
            return lhs.accuracyPercentage < rhs.accuracyPercentage
        }
        if lhs.streakRecord != rhs.streakRecord {
            return lhs.streakRecord < rhs.streakRecord
        }
        return lhs.completedAt < rhs.completedAt
    }
}
