import XCTest
@testable import TrainYourBrainCore

final class ScoreRecordTests: XCTestCase {
    
    func testAccuracyMetricsAndTiers() {
        // 100% Perfect
        let record1 = ScoreRecord(score: 300, totalQuestions: 10, correctAnswers: 10)
        XCTAssertEqual(record1.accuracyRate, 1.0)
        XCTAssertEqual(record1.accuracyPercentage, 100)
        XCTAssertEqual(record1.accuracyDescription, "100%")
        XCTAssertTrue(record1.isPassing)
        XCTAssertEqual(record1.academicEvaluationTier, "Sehr Gut (Excellent)")
        
        // 80% Gut
        let record2 = ScoreRecord(score: 160, totalQuestions: 10, correctAnswers: 8)
        XCTAssertEqual(record2.accuracyPercentage, 80)
        XCTAssertTrue(record2.isPassing)
        XCTAssertEqual(record2.academicEvaluationTier, "Gut (Good)")
        
        // 40% Failing
        let record3 = ScoreRecord(score: 40, totalQuestions: 10, correctAnswers: 4)
        XCTAssertEqual(record3.accuracyPercentage, 40)
        XCTAssertFalse(record3.isPassing)
        XCTAssertEqual(record3.academicEvaluationTier, "Nicht Bestanden (Needs Review)")
        
        // Edge case: 0 questions
        let recordZero = ScoreRecord(score: 0, totalQuestions: 0, correctAnswers: 0)
        XCTAssertEqual(recordZero.accuracyRate, 0.0)
        XCTAssertEqual(recordZero.accuracyPercentage, 0)
        XCTAssertFalse(recordZero.isPassing)
    }
}
