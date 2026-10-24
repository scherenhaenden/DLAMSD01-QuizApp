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
    
    public init(categories: [CustomCategoryRecord] = [], questions: [Question] = []) {
        self.categories = categories
        self.questions = questions
    }
}
