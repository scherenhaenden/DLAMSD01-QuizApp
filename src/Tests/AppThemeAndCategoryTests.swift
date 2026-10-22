import XCTest
@testable import TrainYourBrainCore

final class AppThemeAndCategoryTests: XCTestCase {
    
    // MARK: - AppTheme Tests
    
    func testAppThemeCasesAndRawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "system")
        XCTAssertEqual(AppTheme.light.rawValue, "light")
        XCTAssertEqual(AppTheme.dark.rawValue, "dark")
        XCTAssertEqual(AppTheme.allCases.count, 3)
    }
    
    func testAppThemeDisplayProperties() {
        XCTAssertEqual(AppTheme.system.displayName, "Auto")
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        
        XCTAssertEqual(AppTheme.system.iconName, "circle.righthalf.filled")
        XCTAssertEqual(AppTheme.light.iconName, "sun.max.fill")
        XCTAssertEqual(AppTheme.dark.iconName, "moon.fill")
        
        XCTAssertEqual(AppTheme.system.id, "system")
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }
    
    // MARK: - QuizCategory Tests
    
    func testQuizCategoryMetadata() {
        for category in QuizCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.localizedDescription.isEmpty)
            XCTAssertFalse(category.iconName.isEmpty)
            XCTAssertEqual(category.id, category.rawValue)
        }
        
        XCTAssertEqual(QuizCategory.softwareEngineering.displayName, "Software Engineering")
        XCTAssertEqual(QuizCategory.swiftAndApple.displayName, "Swift & Apple Platform")
        XCTAssertEqual(QuizCategory.algorithmsAndDataStructures.displayName, "Data Structures & Algorithms")
        XCTAssertEqual(QuizCategory.testingAndQuality.displayName, "Testing & Quality Assurance")
        
        // Ensure Testing & QA uses the dedicated shield icon to prevent icon collisions
        XCTAssertEqual(QuizCategory.testingAndQuality.iconName, "shield.checkered")
    }
    
    // MARK: - Difficulty Tests
    
    func testDifficultyProperties() {
        for difficulty in Difficulty.allCases {
            XCTAssertFalse(difficulty.displayName.isEmpty)
            XCTAssertGreaterThan(difficulty.basePoints, 0)
            XCTAssertGreaterThan(difficulty.timeLimitSeconds, 0)
            XCTAssertEqual(difficulty.id, difficulty.rawValue)
        }
        
        XCTAssertEqual(Difficulty.easy.basePoints, 10)
        XCTAssertEqual(Difficulty.medium.basePoints, 20)
        XCTAssertEqual(Difficulty.hard.basePoints, 35)
        
        XCTAssertEqual(Difficulty.easy.timeLimitSeconds, 20.0)
        XCTAssertEqual(Difficulty.medium.timeLimitSeconds, 15.0)
        XCTAssertEqual(Difficulty.hard.timeLimitSeconds, 12.0)
    }
}
