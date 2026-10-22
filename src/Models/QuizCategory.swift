import Foundation

/// Represents the academic domain categories available in Train-your-Brain.
/// Aligned with the Software Engineering and Apple Mobile Solutions curriculum.
public enum QuizCategory: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case softwareEngineering = "software_engineering"
    case swiftAndApple = "swift_apple"
    case algorithmsAndDataStructures = "algorithms_data_structures"
    case testingAndQuality = "testing_quality"
    
    public var id: String { rawValue }
    
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
    
    public var iconName: String {
        switch self {
        case .softwareEngineering:
            return "gearshape.2.fill"
        case .swiftAndApple:
            return "swift"
        case .algorithmsAndDataStructures:
            return "network"
        case .testingAndQuality:
            return "checkmark.shield.fill"
        }
    }
    
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
