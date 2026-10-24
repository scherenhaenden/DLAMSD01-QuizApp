import Foundation

/// Production implementation of `QuestionServiceProtocol` managing bundled curriculum questions
/// and user-created/imported study materials.
///
/// Features:
/// - Immutable bundled questions (`questions.json`) representing the official B.Sc. curriculum.
/// - Persistent local sandbox storage (`Application Support/TrainYourBrain/custom_catalog.json`) for custom categories and questions.
/// - Atomic transactional file writes with rollback on malformed import payloads.
/// - Resilient thread safety via `NSLock`.
public final class LocalQuestionService: QuestionServiceProtocol, @unchecked Sendable {
    private let resourceName: String
    private let resourceExtension: String
    private let customBundle: Bundle?
    private let customData: Data?
    private let customCatalogURL: URL?
    private let lock = NSLock()
    
    private var bundledCache: [Question]?
    private var customPayload: CustomCatalogPayload?
    
    /// Default initializer configured for reading a bundled resource file and persisting to Application Support.
    public init(
        resourceName: String = "questions",
        resourceExtension: String = "json",
        bundle: Bundle? = nil,
        customCatalogURL: URL? = nil
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.customBundle = bundle
        self.customData = nil
        
        if let customCatalogURL = customCatalogURL {
            self.customCatalogURL = customCatalogURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            self.customCatalogURL = appSupport?
                .appendingPathComponent("TrainYourBrain", isDirectory: true)
                .appendingPathComponent("custom_catalog.json")
        }
    }
    
    /// Testing initializer accepting in-memory JSON data, with optional custom catalog persistence URL.
    public init(mockData: Data, customCatalogURL: URL? = nil) {
        self.resourceName = "mock"
        self.resourceExtension = "json"
        self.customBundle = nil
        self.customData = mockData
        self.customCatalogURL = customCatalogURL
    }
    
    // MARK: - QuestionServiceProtocol Implementation
    
    /// Reads and returns all combined questions (bundled curriculum + custom study material).
    public func loadAllQuestions() throws -> [Question] {
        lock.lock()
        defer { lock.unlock() }
        
        let bundled = try loadBundledQuestionsUnchecked()
        let custom = loadCustomQuestionsUnchecked()
        let combined = bundled + custom
        
        guard !combined.isEmpty else {
            throw QuestionServiceError.emptyQuestionSet
        }
        return combined
    }
    
    /// Filters questions by category, combining bundled and custom entries.
    public func loadQuestions(for category: QuizCategory) throws -> [Question] {
        let all = try loadAllQuestions()
        let filtered = all.filter { $0.category.rawValue == category.rawValue }
        guard !filtered.isEmpty else {
            throw QuestionServiceError.emptyQuestionSet
        }
        return filtered
    }
    
    /// Retrieves only user-created or imported questions.
    public func loadCustomQuestions() throws -> [Question] {
        lock.lock()
        defer { lock.unlock() }
        return loadCustomQuestionsUnchecked()
    }
    
    // MARK: - Dynamic Study Material Management
    
    /// Registers and persists a user-defined custom category.
    public func addCategory(_ category: QuizCategory) throws {
        lock.lock()
        defer { lock.unlock() }
        
        loadCustomPayloadIfNeeded()
        
        // Prevent overriding system categories
        if QuizCategory.defaultCategories.contains(where: { $0.rawValue == category.rawValue }) {
            return
        }
        
        CategoryRegistry.shared.register(category)
        
        let record = CustomCategoryRecord(from: category)
        if let idx = customPayload?.categories.firstIndex(where: { $0.id == category.rawValue }) {
            customPayload?.categories[idx] = record
        } else {
            customPayload?.categories.append(record)
        }
        
        try persistCustomPayloadUnchecked()
    }
    
    /// Deletes a custom category and removes all associated questions from persistent storage.
    public func deleteCategory(id: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        if QuizCategory.defaultCategories.contains(where: { $0.rawValue == id }) {
            throw QuestionServiceError.systemCategoryDeletionNotAllowed(id)
        }
        
        loadCustomPayloadIfNeeded()
        
        CategoryRegistry.shared.unregister(id: id)
        customPayload?.categories.removeAll { $0.id == id }
        customPayload?.questions.removeAll { $0.category.rawValue == id }
        
        try persistCustomPayloadUnchecked()
    }
    
    /// Appends a new question to the custom catalog and persists it.
    public func addQuestion(_ question: Question) throws {
        lock.lock()
        defer { lock.unlock() }
        
        loadCustomPayloadIfNeeded()
        
        if customPayload?.questions.contains(where: { $0.id == question.id }) == true {
            throw QuestionServiceError.duplicateQuestionId(question.id)
        }
        
        // If question belongs to an unregistered custom category, register it
        if !QuizCategory.defaultCategories.contains(where: { $0.rawValue == question.category.rawValue }) {
            CategoryRegistry.shared.register(question.category)
            let catRecord = CustomCategoryRecord(from: question.category)
            if customPayload?.categories.contains(where: { $0.id == question.category.rawValue }) == false {
                customPayload?.categories.append(catRecord)
            }
        }
        
        customPayload?.questions.append(question)
        try persistCustomPayloadUnchecked()
    }
    
    /// Updates an existing question within the custom catalog.
    public func updateQuestion(_ question: Question) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let bundled = try loadBundledQuestionsUnchecked()
        if bundled.contains(where: { $0.id == question.id }) {
            throw QuestionServiceError.systemQuestionDeletionNotAllowed(question.id.uuidString)
        }
        
        loadCustomPayloadIfNeeded()
        
        guard let idx = customPayload?.questions.firstIndex(where: { $0.id == question.id }) else {
            throw QuestionServiceError.questionNotFound(question.id)
        }
        
        customPayload?.questions[idx] = question
        try persistCustomPayloadUnchecked()
    }
    
    /// Removes a question from the custom catalog.
    public func deleteQuestion(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let bundled = try loadBundledQuestionsUnchecked()
        if bundled.contains(where: { $0.id == id }) {
            throw QuestionServiceError.systemQuestionDeletionNotAllowed(id.uuidString)
        }
        
        loadCustomPayloadIfNeeded()
        
        guard let idx = customPayload?.questions.firstIndex(where: { $0.id == id }) else {
            throw QuestionServiceError.questionNotFound(id)
        }
        
        customPayload?.questions.remove(at: idx)
        try persistCustomPayloadUnchecked()
    }
    
    /// Transactionally imports categories and questions from raw JSON data.
    ///
    /// Validates all questions against domain invariants before mutating storage.
    /// If any error occurs, the entire transaction is aborted and no data is written.
    @discardableResult
    public func importCatalog(from data: Data) throws -> (categoriesCount: Int, questionsCount: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        loadCustomPayloadIfNeeded()
        
        var importedCategories: [CustomCategoryRecord] = []
        var importedQuestions: [Question] = []
        
        let decoder = JSONDecoder()
        
        // Attempt 1: Full CustomCatalogPayload format
        if let payload = try? decoder.decode(CustomCatalogPayload.self, from: data) {
            importedCategories = payload.categories
            importedQuestions = payload.questions
        } else if let questionsOnly = try? decoder.decode([Question].self, from: data) {
            // Attempt 2: Array of Question objects
            importedQuestions = questionsOnly
        } else {
            throw QuestionServiceError.invalidCatalogPayload("Provided JSON payload does not match the expected catalog or question schema.")
        }
        
        guard !importedQuestions.isEmpty || !importedCategories.isEmpty else {
            throw QuestionServiceError.invalidCatalogPayload("The imported JSON contains zero valid categories or questions.")
        }
        
        // Dry-run validation of every imported question
        for q in importedQuestions {
            do {
                _ = try Question(
                    id: q.id,
                    prompt: q.prompt,
                    options: q.options,
                    correctAnswerIndex: q.correctAnswerIndex,
                    explanation: q.explanation,
                    category: q.category,
                    difficulty: q.difficulty
                )
            } catch {
                throw QuestionServiceError.invalidCatalogPayload("Question '\(q.prompt)' failed validation: \(error.localizedDescription)")
            }
        }
        
        // Auto-create category records for any questions referencing non-system categories
        for q in importedQuestions {
            let cat = q.category
            if !QuizCategory.defaultCategories.contains(where: { $0.rawValue == cat.rawValue }) {
                if !importedCategories.contains(where: { $0.id == cat.rawValue }) {
                    importedCategories.append(CustomCategoryRecord(from: cat))
                }
            }
        }
        
        // Transaction commit: apply to registry and in-memory payload
        for catRecord in importedCategories {
            let category = catRecord.toQuizCategory
            CategoryRegistry.shared.register(category)
            if let idx = customPayload?.categories.firstIndex(where: { $0.id == catRecord.id }) {
                customPayload?.categories[idx] = catRecord
            } else {
                customPayload?.categories.append(catRecord)
            }
        }
        
        for q in importedQuestions {
            if let idx = customPayload?.questions.firstIndex(where: { $0.id == q.id }) {
                customPayload?.questions[idx] = q
            } else {
                customPayload?.questions.append(q)
            }
        }
        
        try persistCustomPayloadUnchecked()
        return (importedCategories.count, importedQuestions.count)
    }
    
    // MARK: - Private Storage & Bundle Helpers
    
    private func loadBundledQuestionsUnchecked() throws -> [Question] {
        if let cached = bundledCache {
            return cached
        }
        
        let data: Data
        if let customData = customData {
            data = customData
        } else {
            data = try readDataFromBundle()
        }
        
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([Question].self, from: data)
            self.bundledCache = questions
            return questions
        } catch {
            throw QuestionServiceError.decodingFailed(error.localizedDescription)
        }
    }
    
    private func loadCustomQuestionsUnchecked() -> [Question] {
        loadCustomPayloadIfNeeded()
        return customPayload?.questions ?? []
    }
    
    private func loadCustomPayloadIfNeeded() {
        if customPayload != nil { return }
        
        guard let url = customCatalogURL, FileManager.default.fileExists(atPath: url.path) else {
            self.customPayload = CustomCatalogPayload()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let payload = try decoder.decode(CustomCatalogPayload.self, from: data)
            
            // Register all custom categories into CategoryRegistry
            for cat in payload.categories {
                CategoryRegistry.shared.register(cat.toQuizCategory)
            }
            
            self.customPayload = payload
        } catch {
            self.customPayload = CustomCatalogPayload()
        }
    }
    
    private func persistCustomPayloadUnchecked() throws {
        guard let url = customCatalogURL else { return }
        guard let payload = customPayload else { return }
        
        do {
            let parentDir = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentDir.path) {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            throw QuestionServiceError.customCatalogSaveFailed(error.localizedDescription)
        }
    }
    
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
