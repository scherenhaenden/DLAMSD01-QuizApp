import Foundation

/// Specific error domain for data layer operations loading and decoding questions.
public enum QuestionServiceError: LocalizedError, Equatable {
    case resourceNotFound(filename: String)
    case unreadableData(String)
    case decodingFailed(String)
    case emptyQuestionSet
    
    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let filename):
            return "Could not find resource file: '\(filename)' in bundle."
        case .unreadableData(let details):
            return "Unable to read question data: \(details)"
        case .decodingFailed(let details):
            return "Failed to decode question JSON payload: \(details)"
        case .emptyQuestionSet:
            return "Question bank contains no questions for the requested scope."
        }
    }
}

/// Abstract contract for reading and querying question datasets.
///
/// Designed following the Dependency Inversion Principle (DIP) to decouple
/// domain consumers (like `QuizViewModel`) from physical I/O and bundle mechanisms.
/// This abstraction enables effortless unit testing via mock services with zero disk I/O.
public protocol QuestionServiceProtocol: Sendable {
    /// Retrieves all available questions from the underlying data source.
    func loadAllQuestions() throws -> [Question]
    
    /// Retrieves questions filtered by a specific academic category.
    func loadQuestions(for category: QuizCategory) throws -> [Question]
}
