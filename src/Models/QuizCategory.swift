import Foundation

/// Represents the academic domain categories available in Train-your-Brain.
///
/// Each category maps directly to key subjects of the B.Sc. Softwareentwicklung
/// curriculum at IU International University of Applied Sciences, specifically
/// designed to reinforce factual knowledge in software architecture, Apple platforms,
/// data structures, and automated verification.
public enum QuizCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case softwareEngineering = "software_engineering"
    case swiftAndApple = "swift_apple"
    case algorithmsAndDataStructures = "algorithms_data_structures"
    case testingAndQuality = "testing_quality"
    
    /// Conformance to `Identifiable` using the raw string value for SwiftUI `ForEach` loops.
    public var id: String { rawValue }
    
    /// User-facing display title formatted for navigation headers and category cards.
    public var displayName: String {
        switch self {
        case .softwareEngineering:
            return "Software Engineering"
        case .swiftAndApple:
            return "Swift & Apple Platform"
        case .algorithmsAndDataStructures:
            return "Data Structures & Algorithms"
        case .testingAndQuality:
            return "Testing & Quality Assurance"
        }
    }
    
    /// SF Symbols system icon name matching Apple Human Interface Guidelines conventions.
    public var iconName: String {
        switch self {
        case .softwareEngineering:
            return "gearshape.2.fill"
        case .swiftAndApple:
            return "swift"
        case .algorithmsAndDataStructures:
            return "network"
        case .testingAndQuality:
            return "shield.checkered"
        }
    }
    
    /// Detailed description summarizing the conceptual scope of questions within this domain.
    public var localizedDescription: String {
        switch self {
        case .softwareEngineering:
            return "Software architecture, design patterns, agile methods, and system design principles."
        case .swiftAndApple:
            return "Swift idioms, memory management (ARC), SwiftUI paradigms, and Apple Human Interface Guidelines."
        case .algorithmsAndDataStructures:
            return "Computational complexity, sorting, trees, and core abstract data types."
        case .testingAndQuality:
            return "Test-Driven Development (TDD), unit testing with XCTest, code coverage, and quality gates."
        }
    }
}
