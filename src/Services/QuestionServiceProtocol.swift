import Foundation

public enum QuestionServiceError: LocalizedError, Equatable {
    case resourceNotFound(filename: String)
    case unreadableData(String)
    case decodingFailed(String)
    case emptyQuestionSet
    
    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let filename):
            return "Could not find resource file: '\(filename)'."
        case .unreadableData(let details):
            return "Unable to read question data: \(details)"
        case .decodingFailed(let details):
            return "Failed to decode question JSON payload: \(details)"
        case .emptyQuestionSet:
            return "Question bank contains no questions."
        }
    }
}

/// Abstract contract for reading question datasets, enabling clean separation of concerns and mockability for testing.
public protocol QuestionServiceProtocol: Sendable {
    func loadAllQuestions() throws -> [Question]
    func loadQuestions(for category: QuizCategory) throws -> [Question]
}
