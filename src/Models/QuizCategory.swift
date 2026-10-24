import Foundation

/// Represents the academic domain categories available in Train-your-Brain.
///
/// Designed as an extensible, open struct conforming to `RawRepresentable`, `Codable`,
/// `CaseIterable`, `Identifiable`, `Hashable`, and `Sendable`.
/// Supports both the four foundational B.Sc. Softwareentwicklung system domains
/// and dynamic, user-defined or imported subjects.
public struct QuizCategory: RawRepresentable, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    /// Unique machine identifier for this category (e.g. "software_engineering", "custom_cloud_computing").
    public let rawValue: String
    
    /// User-facing display title for custom categories.
    public var customDisplayName: String?
    
    /// SF Symbols system icon name for custom categories.
    public var customIconName: String?
    
    /// Conceptual scope description for custom categories.
    public var customDescription: String?
    
    /// Indicates whether this category was created by the user or imported externally.
    public var isCustom: Bool
    
    /// Conformance to `Identifiable` using the raw string value for SwiftUI `ForEach` loops.
    public var id: String { rawValue }
    
    // MARK: - Built-in System Domains
    
    public static let softwareEngineering = QuizCategory(
        rawValue: "software_engineering",
        customDisplayName: "Software Engineering",
        customIconName: "gearshape.2.fill",
        customDescription: "Software architecture, design patterns, agile methods, and system design principles.",
        isCustom: false
    )
    
    public static let swiftAndApple = QuizCategory(
        rawValue: "swift_apple",
        customDisplayName: "Swift & Apple Platform",
        customIconName: "swift",
        customDescription: "Swift idioms, memory management (ARC), SwiftUI paradigms, and Apple Human Interface Guidelines.",
        isCustom: false
    )
    
    public static let algorithmsAndDataStructures = QuizCategory(
        rawValue: "algorithms_data_structures",
        customDisplayName: "Data Structures & Algorithms",
        customIconName: "network",
        customDescription: "Computational complexity, sorting, trees, and core abstract data types.",
        isCustom: false
    )
    
    public static let testingAndQuality = QuizCategory(
        rawValue: "testing_quality",
        customDisplayName: "Testing & Quality Assurance",
        customIconName: "shield.checkered",
        customDescription: "Test-Driven Development (TDD), unit testing with XCTest, code coverage, and quality gates.",
        isCustom: false
    )
    
    /// Foundational B.Sc. Softwareentwicklung curriculum subjects bundled with the application.
    public static let defaultCategories: [QuizCategory] = [
        .softwareEngineering,
        .swiftAndApple,
        .algorithmsAndDataStructures,
        .testingAndQuality
    ]
    
    /// Dynamic collection of all currently available categories (built-in defaults + registered custom subjects).
    public static var allCases: [QuizCategory] {
        CategoryRegistry.shared.allCategories
    }
    
    // MARK: - Initializers
    
    /// Designated initializer for full customization.
    public init(
        rawValue: String,
        customDisplayName: String? = nil,
        customIconName: String? = nil,
        customDescription: String? = nil,
        isCustom: Bool = true
    ) {
        self.rawValue = rawValue
        self.customDisplayName = customDisplayName
        self.customIconName = customIconName
        self.customDescription = customDescription
        self.isCustom = isCustom
    }
    
    /// Initializer conforming to `RawRepresentable`.
    /// Resolves against known system domains and the thread-safe `CategoryRegistry`.
    public init(rawValue: String) {
        if let match = Self.defaultCategories.first(where: { $0.rawValue == rawValue }) {
            self = match
            return
        }
        if let registered = CategoryRegistry.shared.category(for: rawValue) {
            self = registered
            return
        }
        self.rawValue = rawValue
        self.customDisplayName = nil
        self.customIconName = nil
        self.customDescription = nil
        self.isCustom = true
    }
    
    /// Convenience initializer for user-created custom subjects.
    public init(
        id: String,
        displayName: String,
        iconName: String = "folder.fill",
        description: String = "",
        isCustom: Bool = true
    ) {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
        self.rawValue = cleanId.isEmpty ? UUID().uuidString : cleanId
        self.customDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.customIconName = iconName.isEmpty ? "folder.fill" : iconName
        self.customDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isCustom = isCustom
    }
    
    // MARK: - Codable Single-Value Support
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(rawValue: raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    // MARK: - Dynamic Presentation Properties
    
    /// User-facing display title formatted for navigation headers and category cards.
    public var displayName: String {
        if let name = customDisplayName, !name.isEmpty {
            return name
        }
        if let registered = CategoryRegistry.shared.category(for: rawValue),
           let regName = registered.customDisplayName, !regName.isEmpty {
            return regName
        }
        switch rawValue {
        case Self.softwareEngineering.rawValue:
            return "Software Engineering"
        case Self.swiftAndApple.rawValue:
            return "Swift & Apple Platform"
        case Self.algorithmsAndDataStructures.rawValue:
            return "Data Structures & Algorithms"
        case Self.testingAndQuality.rawValue:
            return "Testing & Quality Assurance"
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    /// SF Symbols system icon name matching Apple Human Interface Guidelines conventions.
    public var iconName: String {
        if let icon = customIconName, !icon.isEmpty {
            return icon
        }
        if let registered = CategoryRegistry.shared.category(for: rawValue),
           let regIcon = registered.customIconName, !regIcon.isEmpty {
            return regIcon
        }
        switch rawValue {
        case Self.softwareEngineering.rawValue:
            return "gearshape.2.fill"
        case Self.swiftAndApple.rawValue:
            return "swift"
        case Self.algorithmsAndDataStructures.rawValue:
            return "network"
        case Self.testingAndQuality.rawValue:
            return "shield.checkered"
        default:
            return "folder.fill"
        }
    }
    
    /// Detailed description summarizing the conceptual scope of questions within this domain.
    public var localizedDescription: String {
        if let desc = customDescription, !desc.isEmpty {
            return desc
        }
        if let registered = CategoryRegistry.shared.category(for: rawValue),
           let regDesc = registered.customDescription, !regDesc.isEmpty {
            return regDesc
        }
        switch rawValue {
        case Self.softwareEngineering.rawValue:
            return "Software architecture, design patterns, agile methods, and system design principles."
        case Self.swiftAndApple.rawValue:
            return "Swift idioms, memory management (ARC), SwiftUI paradigms, and Apple Human Interface Guidelines."
        case Self.algorithmsAndDataStructures.rawValue:
            return "Computational complexity, sorting, trees, and core abstract data types."
        case Self.testingAndQuality.rawValue:
            return "Test-Driven Development (TDD), unit testing with XCTest, code coverage, and quality gates."
        default:
            return "User-defined study subject and question bank."
        }
    }
}
