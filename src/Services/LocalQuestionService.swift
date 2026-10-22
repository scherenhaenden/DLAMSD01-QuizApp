import Foundation

/// Production implementation of `QuestionServiceProtocol` reading questions from bundled JSON files.
public final class LocalQuestionService: QuestionServiceProtocol, @unchecked Sendable {
    private let resourceName: String
    private let resourceExtension: String
    private let customBundle: Bundle?
    private let customData: Data?
    
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
    
    /// Initializer intended for unit testing with mocked JSON in-memory data.
    public init(mockData: Data) {
        self.resourceName = "mock"
        self.resourceExtension = "json"
        self.customBundle = nil
        self.customData = mockData
    }
    
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
    
    public func loadQuestions(for category: QuizCategory) throws -> [Question] {
        let all = try loadAllQuestions()
        let filtered = all.filter { $0.category == category }
        guard !filtered.isEmpty else {
            throw QuestionServiceError.emptyQuestionSet
        }
        return filtered
    }
    
    // MARK: - Private Helpers
    
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
