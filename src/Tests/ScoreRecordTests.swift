import XCTest
@testable import TrainYourBrainCore

/// Unit test suite verifying mathematical accuracy calculations and European academic grading tiers in `ScoreRecord`.
final class ScoreRecordTests: XCTestCase {
    
    /// Verifies accuracy percentage rounding, passing cutoffs, and German grading bracket definitions.
    func testAccuracyMetricsAndTiers() {
        // 100% Perfect score: Sehr Gut
        let record1 = ScoreRecord(score: 300, totalQuestions: 10, correctAnswers: 10)
        XCTAssertEqual(record1.accuracyRate, 1.0)
        XCTAssertEqual(record1.accuracyPercentage, 100)
        XCTAssertEqual(record1.accuracyDescription, "100%")
        XCTAssertTrue(record1.isPassing)
        XCTAssertEqual(record1.academicEvaluationTier, "Sehr Gut (Excellent)")
        
        // 80% Performance: Gut
        let record2 = ScoreRecord(score: 160, totalQuestions: 10, correctAnswers: 8)
        XCTAssertEqual(record2.accuracyPercentage, 80)
        XCTAssertTrue(record2.isPassing)
        XCTAssertEqual(record2.academicEvaluationTier, "Gut (Good)")
        
        // 40% Failing score: Nicht Bestanden
        let record3 = ScoreRecord(score: 40, totalQuestions: 10, correctAnswers: 4)
        XCTAssertEqual(record3.accuracyPercentage, 40)
        XCTAssertFalse(record3.isPassing)
        XCTAssertEqual(record3.academicEvaluationTier, "Nicht Bestanden (Needs Review)")
        
        // Defensive boundary case: 0 total questions must not crash with divide-by-zero
        let recordZero = ScoreRecord(score: 0, totalQuestions: 0, correctAnswers: 0)
        XCTAssertEqual(recordZero.accuracyRate, 0.0)
        XCTAssertEqual(recordZero.accuracyPercentage, 0)
        XCTAssertFalse(recordZero.isPassing)
    }
}
