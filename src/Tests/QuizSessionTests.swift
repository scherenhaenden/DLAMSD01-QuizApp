import XCTest
@testable import TrainYourBrainCore

/// Unit test suite validating the state machine, scoring mathematics,
/// streak multipliers, and timeout penalties in `QuizSession`.
final class QuizSessionTests: XCTestCase {
    
    /// Test helper creating a standardized 3-question fixture with tiered difficulties.
    private func makeSampleQuestions() throws -> [Question] {
        return [
            try Question(
                prompt: "Question 1",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 0,
                explanation: "Explanation 1",
                category: .softwareEngineering,
                difficulty: .easy // 10 pts
            ),
            try Question(
                prompt: "Question 2",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 1,
                explanation: "Explanation 2",
                category: .softwareEngineering,
                difficulty: .medium // 20 pts
            ),
            try Question(
                prompt: "Question 3",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 2,
                explanation: "Explanation 3",
                category: .softwareEngineering,
                difficulty: .hard // 35 pts
            )
        ]
    }
    
    /// Verifies the pristine default state of a newly created session before starting.
    func testInitialSessionState() throws {
        let questions = try makeSampleQuestions()
        let session = QuizSession(questions: questions, category: .softwareEngineering)
        
        XCTAssertEqual(session.totalQuestions, 3)
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertEqual(session.score, 0)
        XCTAssertEqual(session.currentStreak, 0)
        XCTAssertEqual(session.state, .idle)
        XCTAssertTrue(session.hasNextQuestion)
        XCTAssertEqual(session.currentQuestion?.prompt, "Question 1")
    }
    
    /// Verifies that calling `start()` moves the state machine to `.inProgress`.
    func testStartSessionMovesToInProgress() throws {
        let questions = try makeSampleQuestions()
        var session = QuizSession(questions: questions)
        session.start()
        
        XCTAssertEqual(session.state, .inProgress)
    }
    
    /// Verifies that consecutive correct answers accumulate points with the 10% streak bonus.
    func testAnsweringCorrectlyIncrementsScoreAndStreak() throws {
        let questions = try makeSampleQuestions()
        var session = QuizSession(questions: questions)
        session.start()
        
        // Question 1: Easy (10 base points, streak = 1 -> multiplier 1.0)
        let isCorrect = session.submitAnswer(optionIndex: 0)
        XCTAssertTrue(isCorrect)
        XCTAssertEqual(session.score, 10)
        XCTAssertEqual(session.currentStreak, 1)
        XCTAssertEqual(session.bestStreak, 1)
        XCTAssertEqual(session.state, .questionAnswered(selectedIndex: 0, isCorrect: true))
        
        session.advanceToNext()
        XCTAssertEqual(session.currentIndex, 1)
        XCTAssertEqual(session.state, .inProgress)
        
        // Question 2: Medium (20 base points * 1.1 streak multiplier = 22 points)
        let isCorrect2 = session.submitAnswer(optionIndex: 1)
        XCTAssertTrue(isCorrect2)
        XCTAssertEqual(session.score, 10 + 22)
        XCTAssertEqual(session.currentStreak, 2)
        XCTAssertEqual(session.bestStreak, 2)
    }
    
    /// Verifies that an incorrect answer immediately breaks the active streak back to 0.
    func testAnsweringIncorrectlyResetsStreak() throws {
        let questions = try makeSampleQuestions()
        var session = QuizSession(questions: questions)
        session.start()
        
        // Correct answer first
        session.submitAnswer(optionIndex: 0)
        XCTAssertEqual(session.currentStreak, 1)
        
        session.advanceToNext()
        // Wrong answer next (resets streak to 0, score remains 10)
        let isCorrect = session.submitAnswer(optionIndex: 0) // expected 1
        XCTAssertFalse(isCorrect)
        XCTAssertEqual(session.currentStreak, 0)
        XCTAssertEqual(session.bestStreak, 1)
        XCTAssertEqual(session.score, 10)
    }
    
    /// Verifies timeout handling when user fails to answer before timer runs out.
    func testTimeoutHandling() throws {
        let questions = try makeSampleQuestions()
        var session = QuizSession(questions: questions)
        session.start()
        
        session.recordTimeout()
        XCTAssertEqual(session.currentStreak, 0)
        XCTAssertEqual(session.score, 0)
        XCTAssertEqual(session.state, .questionAnswered(selectedIndex: -1, isCorrect: false))
    }
    
    /// Verifies full session completion produces an accurate `ScoreRecord` value object.
    func testFullSessionCompletionEmitsScoreRecord() throws {
        let questions = try makeSampleQuestions()
        var session = QuizSession(questions: questions, category: .softwareEngineering)
        session.start()
        
        // Q1: Correct (Easy 10)
        session.submitAnswer(optionIndex: 0)
        session.advanceToNext()
        
        // Q2: Wrong
        session.submitAnswer(optionIndex: 0) // expected 1
        session.advanceToNext()
        
        // Q3: Correct (Hard 35, streak resets to 1 -> 35 pts)
        session.submitAnswer(optionIndex: 2)
        session.advanceToNext()
        
        if case .completed(let record) = session.state {
            XCTAssertEqual(record.totalQuestions, 3)
            XCTAssertEqual(record.correctAnswers, 2)
            XCTAssertEqual(record.score, 10 + 35)
            XCTAssertEqual(record.accuracyPercentage, 67)
            XCTAssertTrue(record.isPassing)
            XCTAssertEqual(record.academicEvaluationTier, "Befriedigend (Satisfactory)")
        } else {
            XCTFail("Expected session state to be completed")
        }
    }
}
