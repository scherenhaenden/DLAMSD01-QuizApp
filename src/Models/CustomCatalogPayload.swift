import Foundation

/// Serializable representation of a user-defined category stored on disk or transferred externally.
public struct CustomCategoryRecord: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let iconName: String
    public let description: String
    
    public init(
        id: String,
        displayName: String,
        iconName: String = "folder.fill",
        description: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
        self.description = description
    }
    
    public var toQuizCategory: QuizCategory {
        QuizCategory(id: id, displayName: displayName, iconName: iconName, description: description, isCustom: true)
    }
    
    public init(from category: QuizCategory) {
        self.id = category.rawValue
        self.displayName = category.displayName
        self.iconName = category.iconName
        self.description = category.localizedDescription
    }
}

/// Root data container representing a persistent or exportable custom study catalog.
public struct CustomCatalogPayload: Codable, Sendable {
    public var categories: [CustomCategoryRecord]
    public var questions: [Question]
    
    enum CodingKeys: String, CodingKey {
        case categories
        case questions
    }
    
    public init(categories: [CustomCategoryRecord] = [], questions: [Question] = []) {
        self.categories = categories
        self.questions = questions
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCategories = try container.decodeIfPresent([CustomCategoryRecord].self, forKey: .categories) ?? []
        self.categories = decodedCategories
        
        let rawQuestions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        
        // Re-link questions with decoded categories local to this payload
        // (Do NOT mutate global CategoryRegistry.shared during decoding to prevent dirty state on decode failure)
        let categoryMap = Dictionary(uniqueKeysWithValues: decodedCategories.map { ($0.id, $0.toQuizCategory) })
        self.questions = rawQuestions.map { q in
            if let matchedCategory = categoryMap[q.category.rawValue] {
                if let reconstructed = try? Question(
                    id: q.id,
                    prompt: q.prompt,
                    options: q.options,
                    correctAnswerIndex: q.correctAnswerIndex,
                    explanation: q.explanation,
                    category: matchedCategory,
                    difficulty: q.difficulty
                ) {
                    return reconstructed
                }
            }
            return q
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categories, forKey: .categories)
        try container.encode(questions, forKey: .questions)
    }
}
