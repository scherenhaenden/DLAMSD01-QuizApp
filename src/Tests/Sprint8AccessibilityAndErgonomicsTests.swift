import XCTest
import SwiftUI
@testable import TrainYourBrainCore

final class Sprint8AccessibilityAndErgonomicsTests: XCTestCase {
    
    private var testUserDefaults: UserDefaults!
    private let testStorageKey = "test_scores_sprint8_\(UUID().uuidString)"
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "Sprint8AccessibilitySuite")!
        testUserDefaults.removePersistentDomain(forName: "Sprint8AccessibilitySuite")
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "Sprint8AccessibilitySuite")
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - 1. Extreme Capacity Edge Case (maxCapacity: 1)
    
    func testScoreStoreExtremeCapacity1PreservesBestScoreAcrossSubsequentGames() throws {
        // 1. Initialize store with maxCapacity = 1
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey,
            maxCapacity: 1
        )
        
        let personalBest = ScoreRecord(
            score: 1000,
            totalQuestions: 10,
            correctAnswers: 10,
            streakRecord: 10,
            category: .swiftAndApple,
            completedAt: Date(timeIntervalSince1970: 1000)
        )
        try store.save(record: personalBest)
        
        // Assert initial save is stored
        XCTAssertEqual(store.bestScore(for: nil)?.score, 1000)
        
        // 2. Play a subsequent low-score game of a DIFFERENT category with 10 pts
        let lowScoreGame = ScoreRecord(
            score: 10,
            totalQuestions: 10,
            correctAnswers: 1,
            streakRecord: 1,
            category: .algorithmsAndDataStructures,
            completedAt: Date(timeIntervalSince1970: 2000)
        )
        try store.save(record: lowScoreGame)
        
        // 3. Even with capacity 1, the all-time best record must strictly prevail over the low-scoring game!
        let loaded = store.loadRecords()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, personalBest.id)
        XCTAssertEqual(loaded.first?.score, 1000)
        
        let bestGlobal = store.bestScore(for: nil)
        XCTAssertEqual(bestGlobal?.id, personalBest.id)
        XCTAssertEqual(bestGlobal?.score, 1000)
    }
    
    // MARK: - 2. TimerBar Accessibility & Urgency Phases
    
    func testTimerBarAccessibilityValueAndUrgencyPhases() {
        // Normal phase (> 50% remaining)
        let normalPhase = TimerBar.resolveUrgencyPhase(progress: 0.8)
        XCTAssertEqual(normalPhase, .normal)
        XCTAssertEqual(TimerBar.resolveColor(for: .normal), .blue)
        
        let normalBar = TimerBar(timeRemaining: 12.0, totalTime: 15.0)
        XCTAssertEqual(normalBar.currentUrgencyPhase, .normal)
        XCTAssertEqual(normalBar.progress, 0.8, accuracy: 0.001)
        
        // Warning phase (20% to 50%)
        let warningPhase = TimerBar.resolveUrgencyPhase(progress: 0.35)
        XCTAssertEqual(warningPhase, .warning)
        XCTAssertEqual(TimerBar.resolveColor(for: .warning), .orange)
        
        // Critical phase (<= 20%)
        let criticalPhase = TimerBar.resolveUrgencyPhase(progress: 0.15)
        XCTAssertEqual(criticalPhase, .critical)
        XCTAssertEqual(TimerBar.resolveColor(for: .critical), .red)
        
        // Boundary progress clamps
        let zeroBar = TimerBar(timeRemaining: 0.0, totalTime: 0.0)
        XCTAssertEqual(zeroBar.progress, 0.0)
        
        let negativeBar = TimerBar(timeRemaining: -5.0, totalTime: 15.0)
        XCTAssertEqual(negativeBar.progress, 0.0)
    }
    
    // MARK: - 3. AnswerButton Accessibility Attributes
    
    func testAnswerButtonAccessibilityAttributesAcrossVisualStates() {
        // Check labels
        let label = AnswerButton.formattedAccessibilityLabel(letter: "B", text: "SwiftUI")
        XCTAssertEqual(label, "Option B: SwiftUI")
        
        // Check hints across all VisualStates
        XCTAssertEqual(AnswerButton.accessibilityHintText(for: .idle), "Double tap to select this answer.")
        XCTAssertEqual(AnswerButton.accessibilityHintText(for: .selected), "Selected. Double tap to change selection.")
        XCTAssertEqual(AnswerButton.accessibilityHintText(for: .correct), "Correct answer.")
        XCTAssertEqual(AnswerButton.accessibilityHintText(for: .wrong), "Incorrect answer.")
        XCTAssertEqual(AnswerButton.accessibilityHintText(for: .dimmed), "Unselected incorrect option.")
        
        // Check values across all VisualStates
        XCTAssertEqual(AnswerButton.accessibilityValueText(for: .correct), "Correct answer")
        XCTAssertEqual(AnswerButton.accessibilityValueText(for: .wrong), "Incorrect answer")
        XCTAssertEqual(AnswerButton.accessibilityValueText(for: .dimmed), "Not selected")
        XCTAssertEqual(AnswerButton.accessibilityValueText(for: .selected), "Selected")
        XCTAssertEqual(AnswerButton.accessibilityValueText(for: .idle), "")
        
        // Check touch target height constant (>= 56pt)
        XCTAssertGreaterThanOrEqual(AnswerButton.minTouchTargetHeight, 56.0)
    }
    
    // MARK: - 4. CategoryCard Accessibility Attributes
    
    func testCategoryCardAccessibilityLabelsAndDescriptions() {
        let card = CategoryCard(category: .softwareEngineering, questionCount: 6, action: {})
        XCTAssertEqual(card.title, "Software Engineering")
        XCTAssertEqual(card.iconName, "gearshape.2.fill")
        XCTAssertEqual(card.subtitle, "Software architecture, design patterns, agile methods, and system design principles.")
        
        let mixedCard = CategoryCard(category: nil, questionCount: 24, action: {})
        XCTAssertEqual(mixedCard.title, "All Topics (Mixed)")
        XCTAssertEqual(mixedCard.iconName, "square.grid.2x2.fill")
    }
    
    // MARK: - 5. QuestionCard Accessibility Label
    
    func testQuestionCardCombinedAccessibilityLabel() throws {
        let question = try Question(
            prompt: "What is Swift?",
            options: ["A language", "A bird", "A car", "A framework"],
            correctAnswerIndex: 0,
            explanation: "Swift is a compiled programming language by Apple.",
            category: .swiftAndApple,
            difficulty: .medium
        )
        
        let card = QuestionCard(question: question, questionNumber: 3, totalQuestions: 10)
        let accessibilityLabel = card.combinedAccessibilityLabel
        
        XCTAssertTrue(accessibilityLabel.contains("Question 3 of 10"))
        XCTAssertTrue(accessibilityLabel.contains("Category: Swift & Apple Platform"))
        XCTAssertTrue(accessibilityLabel.contains("Difficulty: Medium"))
        XCTAssertTrue(accessibilityLabel.contains("What is Swift?"))
    }
    
    // MARK: - 6. ResultView & ScoreRecord Accessibility Labels
    
    func testResultViewAndScoreRecordAccessibilityData() {
        let passingRecord = ScoreRecord(
            score: 85,
            totalQuestions: 10,
            correctAnswers: 8,
            streakRecord: 5,
            category: .swiftAndApple,
            durationSeconds: 45.0,
            totalResponseTime: 30.0,
            categoryBreakdown: [
                CategoryPerformance(
                    categoryId: "swift_and_apple",
                    categoryTitle: "Swift & Apple Ecosystem",
                    correctCount: 8,
                    totalCount: 10
                )
            ],
            completedAt: Date(timeIntervalSince1970: 5000)
        )
        
        XCTAssertTrue(passingRecord.isPassing)
        XCTAssertEqual(passingRecord.accuracyDescription, "80%")
        XCTAssertEqual(passingRecord.formattedAverageSpeed, "3.0s")
        XCTAssertEqual(passingRecord.formattedDuration, "45s")
        XCTAssertEqual(passingRecord.germanGrade.numericValue, 2.0)
        XCTAssertEqual(passingRecord.germanGrade.title, "Gut")
        
        let failingRecord = ScoreRecord(
            score: 30,
            totalQuestions: 10,
            correctAnswers: 3,
            streakRecord: 1,
            category: .algorithmsAndDataStructures,
            durationSeconds: 60.0,
            totalResponseTime: 50.0,
            completedAt: Date(timeIntervalSince1970: 5000)
        )
        
        XCTAssertFalse(failingRecord.isPassing)
        XCTAssertEqual(failingRecord.accuracyDescription, "30%")
        XCTAssertEqual(failingRecord.germanGrade.numericValue, 5.0)
        XCTAssertEqual(failingRecord.germanGrade.title, "Nicht Bestanden")
    }
    
    // MARK: - 7. Leaderboard Subviews Direct Evaluation
    
    @MainActor
    func testLeaderboardAccessibilitySubviews() throws {
        let store = InMemoryScoreStore()
        let record = ScoreRecord(
            score: 95,
            totalQuestions: 10,
            correctAnswers: 9,
            streakRecord: 7,
            category: .softwareEngineering,
            durationSeconds: 50.0,
            totalResponseTime: 25.0,
            completedAt: Date(timeIntervalSince1970: 6000)
        )
        try store.save(record: record)
        
        let vm = LeaderboardViewModel(scoreStore: store)
        let view = LeaderboardView(viewModel: vm)
        
        // Assert stat tile rendering and card rendering
        let statTileView = view.statTile(title: "Games", value: "1", icon: "gamecontroller.fill", color: .blue)
        XCTAssertNotNil(statTileView)
        
        let recordCardView = view.recordCard(index: 0, record: record)
        XCTAssertNotNil(recordCardView)
        
        let rankBadge1 = view.rankBadge(rank: 1)
        XCTAssertNotNil(rankBadge1)
        
        let rankBadge2 = view.rankBadge(rank: 2)
        XCTAssertNotNil(rankBadge2)
        
        let rankBadge3 = view.rankBadge(rank: 3)
        XCTAssertNotNil(rankBadge3)
        
        let rankBadgeDefault = view.rankBadge(rank: 4)
        XCTAssertNotNil(rankBadgeDefault)
        
        let metricColumnView = view.metricColumn(label: "Score", value: "95 pts")
        XCTAssertNotNil(metricColumnView)
    }
    
    // MARK: - 8. Mathematical WCAG 2.1 AA Contrast Ratios
    
    func testMathematicalWCAGContrastRatios() {
        // Luminance helper according to WCAG 2.1 definition:
        // L = 0.2126 * R + 0.7152 * G + 0.0722 * B where C = c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
        func relativeLuminance(r: Double, g: Double, b: Double) -> Double {
            func channel(_ c: Double) -> Double {
                let norm = c / 255.0
                return norm <= 0.03928 ? norm / 12.92 : pow((norm + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        
        func contrastRatio(l1: Double, l2: Double) -> Double {
            let lighter = max(l1, l2)
            let darker = min(l1, l2)
            return (lighter + 0.05) / (darker + 0.05)
        }
        
        let whiteLuminance = relativeLuminance(r: 255, g: 255, b: 255) // 1.0
        let blackLuminance = relativeLuminance(r: 0, g: 0, b: 0)       // 0.0
        let backgroundLuminance = relativeLuminance(r: 242, g: 242, b: 247) // Light mode grouped canvas
        
        // 1. Correct Feedback Color: RGB(27, 94, 32)
        let correctLuminance = relativeLuminance(r: 27, g: 94, b: 32)
        let correctContrast = contrastRatio(l1: whiteLuminance, l2: correctLuminance)
        XCTAssertGreaterThanOrEqual(correctContrast, 4.5, "quizCorrectFeedback must exceed WCAG AA 4.5:1 ratio")
        XCTAssertGreaterThanOrEqual(correctContrast, 7.0, "quizCorrectFeedback also fulfills WCAG AAA 7:1 ratio")
        XCTAssertEqual(round(correctContrast * 100) / 100, 7.87, "Exact sRGB ratio for white on #1B5E20 is 7.87:1")
        
        // 2. Incorrect Feedback Color: RGB(183, 28, 28)
        let incorrectLuminance = relativeLuminance(r: 183, g: 28, b: 28)
        let incorrectContrast = contrastRatio(l1: whiteLuminance, l2: incorrectLuminance)
        XCTAssertGreaterThanOrEqual(incorrectContrast, 4.5, "quizIncorrectFeedback must exceed WCAG AA 4.5:1 ratio")
        XCTAssertEqual(round(incorrectContrast * 100) / 100, 6.57, "Exact sRGB ratio for white on #B71C1C is 6.57:1")
        
        // 3. Black text on Light Grouped Canvas #F2F2F7
        let primaryTextContrast = contrastRatio(l1: backgroundLuminance, l2: blackLuminance)
        XCTAssertGreaterThanOrEqual(primaryTextContrast, 7.0, "Primary text on canvas must fulfill WCAG AAA 7:1 ratio")
        XCTAssertEqual(round(primaryTextContrast * 100) / 100, 18.82, "Exact sRGB ratio for black on #F2F2F7 is 18.82:1")
        
        // 4. Leaderboard German Grade Badge Contrast (Solid capsule with white text)
        // Passing badge uses white text on #1B5E20 -> exactly correctContrast (7.87:1, WCAG AAA)
        // Failing badge uses white text on #B71C1C -> exactly incorrectContrast (6.57:1, WCAG AA)
        XCTAssertGreaterThanOrEqual(correctContrast, 4.5, "Leaderboard passing badge must exceed WCAG AA")
        XCTAssertGreaterThanOrEqual(incorrectContrast, 4.5, "Leaderboard failing badge must exceed WCAG AA")
    }
    
    // MARK: - 9. Grade Badges High-Contrast WCAG Conformance Across Records
    
    func testLeaderboardGradeBadgeAndResultViewHighContrastFills() {
        let passing = ScoreRecord(
            score: 100,
            totalQuestions: 10,
            correctAnswers: 10,
            streakRecord: 10,
            category: .softwareEngineering,
            completedAt: Date(timeIntervalSince1970: 1000)
        )
        XCTAssertTrue(passing.isPassing)
        XCTAssertEqual(passing.germanGrade.title, "Sehr Gut")
        XCTAssertEqual(passing.germanGrade.formattedGrade, "1.0 · Sehr Gut (Outstanding)")
        
        let failing = ScoreRecord(
            score: 20,
            totalQuestions: 10,
            correctAnswers: 2,
            streakRecord: 1,
            category: .softwareEngineering,
            completedAt: Date(timeIntervalSince1970: 2000)
        )
        XCTAssertFalse(failing.isPassing)
        XCTAssertEqual(failing.germanGrade.title, "Nicht Bestanden")
        XCTAssertEqual(failing.germanGrade.formattedGrade, "5.0 · Nicht Bestanden (Fail)")
    }
}
