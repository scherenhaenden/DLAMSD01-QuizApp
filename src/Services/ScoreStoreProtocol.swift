import Foundation

/// Errors encountered during persistence operations in the score store.
public enum ScoreStoreError: LocalizedError, Equatable, Sendable {
    case encodingFailed(String)
    case decodingFailed(String)
    case persistenceFailed(String)
    case corruptedDataDiscarded

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let msg):
            return "Failed to encode score records: \(msg)"
        case .decodingFailed(let msg):
            return "Failed to decode score records: \(msg)"
        case .persistenceFailed(let msg):
            return "Underlying storage error: \(msg)"
        case .corruptedDataDiscarded:
            return "Corrupted data was detected and cleared."
        }
    }
}

/// Abstract contract for persisting and retrieving user quiz score records (ADR-07).
///
/// Designed to decouple storage mechanisms (`UserDefaults`, SQLite, or in-memory)
/// from the view model and presentation layers, ensuring testability and compliance
/// with Human Interface Guidelines.
public protocol ScoreStoreProtocol: Sendable {
    /// Persists a new score record to persistent storage.
    func save(record: ScoreRecord) throws
    
    /// Loads all recorded scores, sorted chronologically descending by completion timestamp.
    func loadRecords() -> [ScoreRecord]
    
    /// Loads top score records, sorted by score descending, then accuracy descending, then date descending.
    func loadHighScores(limit: Int) -> [ScoreRecord]
    
    /// Retrieves the single best score record achieved for a specific category (or across all if nil).
    func bestScore(for category: QuizCategory?) -> ScoreRecord?
    
    /// Removes all stored records from the persistent store.
    func clearAll() throws
}

extension ScoreStoreProtocol {
    /// Default overload loading up to 50 top high scores.
    public func loadHighScores() -> [ScoreRecord] {
        return loadHighScores(limit: 50)
    }
}
