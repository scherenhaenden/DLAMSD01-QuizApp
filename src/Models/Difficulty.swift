import Foundation

/// Defines the difficulty tiers and scoring weighting for quiz questions.
public enum Difficulty: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }
    
    /// Base points awarded for answering a question at this difficulty correctly.
    public var basePoints: Int {
        switch self {
        case .easy:
            return 10
        case .medium:
            return 20
        case .hard:
            return 35
        }
    }
    
    /// Time limit in seconds allowed per question according to difficulty.
    public var timeLimitSeconds: TimeInterval {
        switch self {
        case .easy:
            return 20.0
        case .medium:
            return 15.0
        case .hard:
            return 12.0
        }
    }
}
