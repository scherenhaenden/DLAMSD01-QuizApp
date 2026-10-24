import Foundation

/// Specific error domain for data layer operations loading, saving, and decoding questions and study material.
public enum QuestionServiceError: LocalizedError, Equatable {
    case resourceNotFound(filename: String)
    case unreadableData(String)
    case decodingFailed(String)
    case emptyQuestionSet
    case customCatalogSaveFailed(String)
    case systemCategoryDeletionNotAllowed(String)
    case systemQuestionDeletionNotAllowed(String)
    case questionNotFound(UUID)
    case invalidCatalogPayload(String)
    case duplicateQuestionId(UUID)
    
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
        case .customCatalogSaveFailed(let details):
            return "Failed to persist custom study catalog: \(details)"
        case .systemCategoryDeletionNotAllowed(let id):
            return "System category '\(id)' is part of the core B.Sc. curriculum and cannot be deleted."
        case .systemQuestionDeletionNotAllowed(let id):
            return "Bundled curriculum question '\(id)' is read-only and cannot be modified or deleted."
        case .questionNotFound(let id):
            return "Question with ID '\(id)' was not found in the custom catalog."
        case .invalidCatalogPayload(let details):
            return "Invalid catalog format or corrupt question data: \(details)"
        case .duplicateQuestionId(let id):
            return "Question with ID '\(id)' already exists in the catalog."
        }
    }
}

/// Abstract contract for reading, querying, and managing dynamic question datasets and study material.
///
/// Designed following the Dependency Inversion Principle (DIP) to decouple domain consumers
/// (like `QuizViewModel`) from physical I/O, file persistence, and network sources.
public protocol QuestionServiceProtocol: Sendable {
    /// Retrieves all available questions from the underlying data source (bundled + custom user material).
    func loadAllQuestions() throws -> [Question]
    
    /// Retrieves questions filtered by a specific academic category.
    func loadQuestions(for category: QuizCategory) throws -> [Question]
    
    /// Retrieves only user-created or imported questions.
    func loadCustomQuestions() throws -> [Question]
    
    // MARK: - Dynamic Catalog Operations (Sprint 9)
    
    /// Adds a user-defined custom category and persists it.
    func addCategory(_ category: QuizCategory) throws
    
    /// Removes a custom category and its associated questions from persistent storage.
    func deleteCategory(id: String) throws
    
    /// Adds a new question to the custom catalog and persists it.
    func addQuestion(_ question: Question) throws
    
    /// Updates an existing question in the custom catalog.
    func updateQuestion(_ question: Question) throws
    
    /// Deletes a question from the custom catalog.
    func deleteQuestion(id: UUID) throws
    
    /// Imports questions and categories from raw JSON data transactionally.
    @discardableResult
    func importCatalog(from data: Data) throws -> (categoriesCount: Int, questionsCount: Int)
}

// MARK: - Default Protocol Implementations for Backward Compatibility with Mock Services
public extension QuestionServiceProtocol {
    func loadCustomQuestions() throws -> [Question] { [] }
    func addCategory(_ category: QuizCategory) throws {}
    func deleteCategory(id: String) throws {}
    func addQuestion(_ question: Question) throws {}
    func updateQuestion(_ question: Question) throws {}
    func deleteQuestion(id: UUID) throws {}
    @discardableResult
    func importCatalog(from data: Data) throws -> (categoriesCount: Int, questionsCount: Int) {
        return (0, 0)
    }
}
