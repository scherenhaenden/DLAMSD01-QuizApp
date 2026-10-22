import Foundation

/// Defines the difficulty tiers and scoring weighting for quiz questions.
///
/// In alignment with Cognitive Load Theory and adaptive gamification,
/// difficulty levels scale both the reward (base points) and the cognitive
/// pressure (reduced countdown timer) to challenge users appropriately.
public enum Difficulty: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    /// Stable identifier conforming to `Identifiable` for SwiftUI list and picker iteration.
    public var id: String { rawValue }
    
    /// Human-readable localized title displayed in UI tags and category chips.
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
    
    /// Base score points awarded for answering a question at this difficulty correctly.
    /// Higher difficulty offers greater point incentives to reward mastery.
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
    
    /// Dedicated time limit in seconds allowed per question according to difficulty.
    /// Easy questions allow 20 seconds for reading, while Hard questions require
    /// rapid recall under a 12-second countdown to stimulate active retrieval.
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
