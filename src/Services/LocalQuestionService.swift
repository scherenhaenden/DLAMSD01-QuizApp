import Foundation

/// Production implementation of `QuestionServiceProtocol` reading questions from bundled JSON files.
///
/// Implements resilient error handling and flexible initialization:
/// - Supports standard application bundle lookups (`Bundle.main`).
/// - Supports Swift Package Manager modular resources (`Bundle.module`).
/// - Supports raw in-memory `Data` injection for fast, deterministic unit testing.
public final class LocalQuestionService: QuestionServiceProtocol, @unchecked Sendable {
    private let resourceName: String
    private let resourceExtension: String
    private let customBundle: Bundle?
    private let customData: Data?
    
    /// Default initializer configured for reading a bundled resource file (defaults to `questions.json`).
    public init(
        resourceName: String = "questions",
        resourceExtension: String = "json",
        bundle: Bundle? = nil
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.customBundle = bundle
        self.customData = nil
    }
    
    /// Testing initializer accepting in-memory JSON data, bypassing file system lookups.
    public init(mockData: Data) {
        self.resourceName = "mock"
        self.resourceExtension = "json"
        self.customBundle = nil
        self.customData = mockData
    }
    
    /// Reads and decodes all questions from the configured source.
    ///
    /// Throws `QuestionServiceError` if the resource is missing, corrupted, or yields zero questions.
    public func loadAllQuestions() throws -> [Question] {
        let data: Data
        
        if let customData = customData {
            data = customData
        } else {
            data = try readDataFromBundle()
        }
        
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([Question].self, from: data)
            guard !questions.isEmpty else {
                throw QuestionServiceError.emptyQuestionSet
            }
            return questions
        } catch let error as QuestionServiceError {
            throw error
        } catch {
            throw QuestionServiceError.decodingFailed(error.localizedDescription)
        }
    }
    
    /// Filters questions by category, throwing `emptyQuestionSet` if no matching entries exist.
    public func loadQuestions(for category: QuizCategory) throws -> [Question] {
        let all = try loadAllQuestions()
        let filtered = all.filter { $0.category == category }
        guard !filtered.isEmpty else {
            throw QuestionServiceError.emptyQuestionSet
        }
        return filtered
    }
    
    // MARK: - Private Helpers
    
    /// Resolves the resource URL using the appropriate bundle context (SPM vs. App Bundle).
    private func readDataFromBundle() throws -> Data {
        let targetBundle: Bundle
        if let customBundle = customBundle {
            targetBundle = customBundle
        } else {
            #if SWIFT_PACKAGE
            targetBundle = Bundle.module
            #else
            targetBundle = Bundle.main
            #endif
        }
        
        guard let url = targetBundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw QuestionServiceError.resourceNotFound(filename: "\(resourceName).\(resourceExtension)")
        }
        
        do {
            return try Data(contentsOf: url)
        } catch {
            throw QuestionServiceError.unreadableData(error.localizedDescription)
        }
    }
}
