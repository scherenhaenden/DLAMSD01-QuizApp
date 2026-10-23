import XCTest
import SwiftUI
@testable import TrainYourBrainCore

@MainActor
final class Sprint6ResultsAnalyticsTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private final class TestQuestionService: QuestionServiceProtocol, @unchecked Sendable {
        let questions: [Question]
        init(questions: [Question]) {
            self.questions = questions
        }
        func loadAllQuestions() throws -> [Question] { questions }
        func loadQuestions(for category: QuizCategory) throws -> [Question] { questions }
    }
    
    private func makeTestQuestion(
        category: QuizCategory = .softwareEngineering,
        correctIndex: Int = 0
    ) -> Question {
        return try! Question(
            id: UUID(),
            prompt: "Sample Prompt for category \(category.displayName)",
            options: ["Option A", "Option B", "Option C", "Option D"],
            correctAnswerIndex: correctIndex,
            explanation: "Explanation text.",
            category: category,
            difficulty: .medium
        )
    }
    
    // MARK: - 1. German Academic Grading Scale Tests (US-11)
    
    func testGermanAcademicGradeScaleMapping() {
        // Outstanding (1.0)
        let grade100 = GermanAcademicGrade(accuracyPercentage: 100)
        XCTAssertEqual(grade100.numericValue, 1.0)
        XCTAssertEqual(grade100.title, "Sehr Gut")
        XCTAssertTrue(grade100.isPassing)
        XCTAssertEqual(grade100.formattedGrade, "1.0 · Sehr Gut (Outstanding)")
        
        let grade95 = GermanAcademicGrade(accuracyPercentage: 95)
        XCTAssertEqual(grade95.numericValue, 1.0)
        
        // Excellent (1.3)
        let grade92 = GermanAcademicGrade(accuracyPercentage: 92)
        XCTAssertEqual(grade92.numericValue, 1.3)
        XCTAssertEqual(grade92.title, "Sehr Gut")
        XCTAssertTrue(grade92.isPassing)
        XCTAssertEqual(grade92.formattedGrade, "1.3 · Sehr Gut (Excellent)")
        
        // Very Good (1.7)
        let grade88 = GermanAcademicGrade(accuracyPercentage: 88)
        XCTAssertEqual(grade88.numericValue, 1.7)
        XCTAssertEqual(grade88.title, "Gut")
        XCTAssertTrue(grade88.isPassing)
        
        // Good (2.0)
        let grade82 = GermanAcademicGrade(accuracyPercentage: 82)
        XCTAssertEqual(grade82.numericValue, 2.0)
        XCTAssertEqual(grade82.title, "Gut")
        
        // Above Average (2.3)
        let grade76 = GermanAcademicGrade(accuracyPercentage: 76)
        XCTAssertEqual(grade76.numericValue, 2.3)
        XCTAssertEqual(grade76.title, "Gut")
        
        // Satisfactory (2.7)
        let grade72 = GermanAcademicGrade(accuracyPercentage: 72)
        XCTAssertEqual(grade72.numericValue, 2.7)
        XCTAssertEqual(grade72.title, "Befriedigend")
        
        // Fair (3.0)
        let grade68 = GermanAcademicGrade(accuracyPercentage: 68)
        XCTAssertEqual(grade68.numericValue, 3.0)
        XCTAssertEqual(grade68.title, "Befriedigend")
        
        // Acceptable (3.3)
        let grade62 = GermanAcademicGrade(accuracyPercentage: 62)
        XCTAssertEqual(grade62.numericValue, 3.3)
        XCTAssertEqual(grade62.title, "Befriedigend")
        
        // Sufficient (3.7)
        let grade57 = GermanAcademicGrade(accuracyPercentage: 57)
        XCTAssertEqual(grade57.numericValue, 3.7)
        XCTAssertEqual(grade57.title, "Ausreichend")
        XCTAssertTrue(grade57.isPassing)
        
        // Pass boundary (4.0)
        let grade50 = GermanAcademicGrade(accuracyPercentage: 50)
        XCTAssertEqual(grade50.numericValue, 4.0)
        XCTAssertEqual(grade50.title, "Ausreichend")
        XCTAssertTrue(grade50.isPassing)
        
        // Fail (5.0)
        let grade49 = GermanAcademicGrade(accuracyPercentage: 49)
        XCTAssertEqual(grade49.numericValue, 5.0)
        XCTAssertEqual(grade49.title, "Nicht Bestanden")
        XCTAssertFalse(grade49.isPassing)
        XCTAssertEqual(grade49.formattedGrade, "5.0 · Nicht Bestanden (Fail)")
        
        let grade0 = GermanAcademicGrade(accuracyPercentage: 0)
        XCTAssertEqual(grade0.numericValue, 5.0)
        XCTAssertFalse(grade0.isPassing)
    }
    
    func testGermanGradeAndAcademicEvaluationTierConsistencyAt75Percent() {
        // Specific regression test for 75% accuracy (e.g. 18/24 or 3/4)
        let record75 = ScoreRecord(score: 1800, totalQuestions: 24, correctAnswers: 18)
        XCTAssertEqual(record75.accuracyPercentage, 75)
        XCTAssertEqual(record75.germanGrade.numericValue, 2.3)
        XCTAssertEqual(record75.germanGrade.title, "Gut")
        XCTAssertEqual(record75.germanGrade.formattedGrade, "2.3 · Gut (Above Average)")
        // Verify semantic consistency: academicEvaluationTier must align with germanGrade (Gut, not Befriedigend)
        XCTAssertEqual(record75.academicEvaluationTier, "Gut (Good)")
    }
    
    // MARK: - 2. Time Spent & Speed Analytics Tests (US-12)
    
    func testTimeSpentAndSpeedCalculations() {
        let record = ScoreRecord(
            score: 1500,
            totalQuestions: 10,
            correctAnswers: 8,
            streakRecord: 4,
            category: .softwareEngineering,
            durationSeconds: 102.5
        )
        
        XCTAssertEqual(record.formattedDuration, "1m 43s")
        XCTAssertEqual(record.averageResponseTime, 10.25, accuracy: 0.01)
        XCTAssertEqual(record.formattedAverageSpeed, "10.2s")
        
        // Sub-minute duration formatting
        let shortRecord = ScoreRecord(
            score: 300,
            totalQuestions: 3,
            correctAnswers: 3,
            durationSeconds: 14.2
        )
        XCTAssertEqual(shortRecord.formattedDuration, "14s")
        XCTAssertEqual(shortRecord.formattedAverageSpeed, "4.7s")
        
        // Zero question boundary
        let zeroRecord = ScoreRecord(
            score: 0,
            totalQuestions: 0,
            correctAnswers: 0,
            durationSeconds: 0.0
        )
        XCTAssertEqual(zeroRecord.averageResponseTime, 0.0)
        XCTAssertEqual(zeroRecord.formattedAverageSpeed, "0.0s")
        XCTAssertEqual(zeroRecord.formattedDuration, "0s")
    }
    
    func testActiveResponseTimeSeparatedFromReadingTimeInViewModel() {
        var simulatedUptime: TimeInterval = 1000.0
        let mockClock = { simulatedUptime }
        
        let q = makeTestQuestion(category: .softwareEngineering, correctIndex: 0)
        let service = TestQuestionService(questions: [q])
        let vm = QuizViewModel(questionService: service, monotonicClock: mockClock)
        
        // 1. Start quiz at t = 1000.0
        vm.startQuiz(category: .softwareEngineering)
        XCTAssertEqual(vm.viewState, QuizViewModel.ViewState.playing)
        
        // 2. Answer question after 2.0s of active decision time (t = 1002.0)
        simulatedUptime += 2.0
        vm.selectAnswer(at: 0)
        guard case .answered = vm.viewState else {
            XCTFail("Expected view state to be answered")
            return
        }
        
        // 3. User spends 60.0s reading the pedagogical explanation before tapping next (t = 1062.0)
        simulatedUptime += 60.0
        vm.nextQuestion()
        
        // 4. Verify the round completed with decoupled active vs reading time
        guard case .finished(let record) = vm.viewState else {
            XCTFail("Expected view state to be finished")
            return
        }
        
        // Total session duration includes the 60s reading: 62.0s
        XCTAssertEqual(record.durationSeconds, 62.0, accuracy: 0.01)
        XCTAssertEqual(record.formattedDuration, "1m 2s")
        
        // Active response time measures strictly the 2.0s answering period:
        XCTAssertEqual(record.totalResponseTime, 2.0, accuracy: 0.01)
        XCTAssertEqual(record.averageResponseTime, 2.0, accuracy: 0.01)
        XCTAssertEqual(record.formattedAverageSpeed, "2.0s")
    }
    
    // MARK: - 3. Category Performance Breakdown Tests
    
    func testCategoryPerformanceModelAndBreakdown() {
        let item = CategoryPerformance(
            categoryId: "software_engineering",
            categoryTitle: "Software Engineering",
            correctCount: 4,
            totalCount: 5
        )
        
        XCTAssertEqual(item.id, "software_engineering")
        XCTAssertEqual(item.accuracyRate, 0.8)
        XCTAssertEqual(item.accuracyPercentage, 80)
        XCTAssertEqual(item.accuracyDescription, "80%")
        
        // Zero count boundary defensively clamped
        let zeroItem = CategoryPerformance(
            categoryId: "test",
            categoryTitle: "Test",
            correctCount: 0,
            totalCount: 0
        )
        XCTAssertEqual(zeroItem.accuracyRate, 0.0)
        XCTAssertEqual(zeroItem.accuracyPercentage, 0)
        XCTAssertEqual(zeroItem.accuracyDescription, "0%")
    }
    
    func testQuizSessionAggregatesCategoryBreakdown() {
        let q1 = makeTestQuestion(category: .softwareEngineering, correctIndex: 0)
        let q2 = makeTestQuestion(category: .softwareEngineering, correctIndex: 1)
        let q3 = makeTestQuestion(category: .swiftAndApple, correctIndex: 2)
        
        var session = QuizSession(questions: [q1, q2, q3])
        session.start()
        
        // Q1: Correct
        session.submitAnswer(optionIndex: 0)
        session.advanceToNext()
        
        // Q2: Incorrect
        session.submitAnswer(optionIndex: 0)
        session.advanceToNext()
        
        // Q3: Correct
        session.submitAnswer(optionIndex: 2)
        session.advanceToNext(duration: 45.0)
        
        guard case .completed(let record) = session.state else {
            XCTFail("Expected session to be completed")
            return
        }
        
        XCTAssertEqual(record.totalQuestions, 3)
        XCTAssertEqual(record.correctAnswers, 2)
        XCTAssertEqual(record.durationSeconds, 45.0)
        XCTAssertEqual(record.formattedDuration, "45s")
        XCTAssertEqual(record.formattedAverageSpeed, "15.0s")
        XCTAssertEqual(record.categoryBreakdown.count, 2)
        
        let sePerformance = record.categoryBreakdown.first { $0.categoryId == QuizCategory.softwareEngineering.rawValue }
        XCTAssertNotNil(sePerformance)
        XCTAssertEqual(sePerformance?.totalCount, 2)
        XCTAssertEqual(sePerformance?.correctCount, 1)
        XCTAssertEqual(sePerformance?.accuracyPercentage, 50)
        
        let swiftPerformance = record.categoryBreakdown.first { $0.categoryId == QuizCategory.swiftAndApple.rawValue }
        XCTAssertNotNil(swiftPerformance)
        XCTAssertEqual(swiftPerformance?.totalCount, 1)
        XCTAssertEqual(swiftPerformance?.correctCount, 1)
        XCTAssertEqual(swiftPerformance?.accuracyPercentage, 100)
    }
    
    // MARK: - 4. Codable Robustness & Backward Compatibility
    
    func testScoreRecordCodableRoundtrip() throws {
        let catItem = CategoryPerformance(
            categoryId: "testing_qa",
            categoryTitle: "Testing & QA",
            correctCount: 2,
            totalCount: 3
        )
        let original = ScoreRecord(
            score: 1200,
            totalQuestions: 6,
            correctAnswers: 5,
            streakRecord: 3,
            category: .testingAndQuality,
            durationSeconds: 78.5,
            categoryBreakdown: [catItem]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScoreRecord.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.score, original.score)
        XCTAssertEqual(decoded.totalQuestions, original.totalQuestions)
        XCTAssertEqual(decoded.correctAnswers, original.correctAnswers)
        XCTAssertEqual(decoded.streakRecord, original.streakRecord)
        XCTAssertEqual(decoded.durationSeconds, original.durationSeconds)
        XCTAssertEqual(decoded.categoryBreakdown, original.categoryBreakdown)
        XCTAssertEqual(decoded.germanGrade, original.germanGrade)
    }
    
    func testScoreRecordDecodesLegacyJSONWithoutDurationOrBreakdown() throws {
        let legacyJSON = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "score": 800,
            "totalQuestions": 4,
            "correctAnswers": 3,
            "streakRecord": 2,
            "category": "software_engineering",
            "completedAt": 0.0
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(ScoreRecord.self, from: legacyJSON)
        XCTAssertEqual(decoded.score, 800)
        XCTAssertEqual(decoded.totalQuestions, 4)
        XCTAssertEqual(decoded.correctAnswers, 3)
        XCTAssertEqual(decoded.streakRecord, 2)
        XCTAssertEqual(decoded.durationSeconds, 0.0)
        XCTAssertTrue(decoded.categoryBreakdown.isEmpty)
        XCTAssertEqual(decoded.accuracyPercentage, 75)
        XCTAssertEqual(decoded.germanGrade.numericValue, 2.3)
    }
    
    func testScoreRecordDecoderRejectsCorruptInvariants() {
        // 1. Rejects correctAnswers > totalQuestions (e.g. 8 out of 4 = 200%)
        let invalidAnswersJSON = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "score": 800,
            "totalQuestions": 4,
            "correctAnswers": 8,
            "streakRecord": 2
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ScoreRecord.self, from: invalidAnswersJSON))
        
        // 2. Rejects negative score
        let negativeScoreJSON = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "score": -100,
            "totalQuestions": 5,
            "correctAnswers": 3
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ScoreRecord.self, from: negativeScoreJSON))
        
        // 3. Rejects negative duration
        let negativeDurationJSON = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "score": 500,
            "totalQuestions": 5,
            "correctAnswers": 3,
            "durationSeconds": -12.5
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ScoreRecord.self, from: negativeDurationJSON))
    }
    
    // MARK: - 5. ResultView Rendering & Layout Integration
    
    func testResultViewRendersWithFullAnalytics() {
        let catItem = CategoryPerformance(
            categoryId: "software_engineering",
            categoryTitle: "Software Engineering",
            correctCount: 9,
            totalCount: 10
        )
        let record = ScoreRecord(
            score: 2100,
            totalQuestions: 10,
            correctAnswers: 9,
            streakRecord: 7,
            category: .softwareEngineering,
            durationSeconds: 95.0,
            categoryBreakdown: [catItem]
        )
        
        var playAgainTapped = false
        var returnToMenuTapped = false
        
        let view = ResultView(
            record: record,
            onPlayAgain: { playAgainTapped = true },
            onBackToMenu: { returnToMenuTapped = true }
        )
        
        XCTAssertNotNil(view.body)
        XCTAssertFalse(playAgainTapped)
        XCTAssertFalse(returnToMenuTapped)
        XCTAssertEqual(record.germanGrade.numericValue, 1.3)
        XCTAssertEqual(record.formattedDuration, "1m 35s")
        XCTAssertEqual(record.formattedAverageSpeed, "9.5s")
    }
}
