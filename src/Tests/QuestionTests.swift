import XCTest
@testable import TrainYourBrainCore

/// Unit test suite verifying the Domain-Driven Design (DDD) rules,
/// invariant validations, and Fisher-Yates randomization of the `Question` model.
final class QuestionTests: XCTestCase {
    
    /// Verifies that a well-formed Question model initializes with all properties intact.
    func testValidQuestionInitialization() throws {
        let question = try Question(
            prompt: "What is the primary role of the ViewModel in MVVM?",
            options: [
                "Directly rendering pixels to the screen",
                "Holding observable state and mediating domain logic for the view",
                "Communicating directly with raw database drivers",
                "Handling low-level touch events"
            ],
            correctAnswerIndex: 1,
            explanation: "The ViewModel exposes observable state that the declarative View consumes.",
            category: .softwareEngineering,
            difficulty: .medium
        )
        
        XCTAssertEqual(question.options.count, 4)
        XCTAssertEqual(question.correctAnswerIndex, 1)
        XCTAssertEqual(question.correctAnswerText, "Holding observable state and mediating domain logic for the view")
        XCTAssertTrue(question.isCorrect(selectedOptionIndex: 1))
        XCTAssertFalse(question.isCorrect(selectedOptionIndex: 0))
    }
    
    /// Verifies that an empty prompt (or one containing solely whitespace) is rejected by invariant validation.
    func testEmptyPromptThrowsValidationError() {
        XCTAssertThrowsError(
            try Question(
                prompt: "   ",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 0,
                explanation: "Explanation",
                category: .swiftAndApple
            )
        ) { error in
            XCTAssertEqual(error as? Question.ValidationError, .emptyPrompt)
        }
    }
    
    /// Verifies that providing fewer than 2 choices triggers an `insufficientOptions` error.
    func testInsufficientOptionsThrowsValidationError() {
        XCTAssertThrowsError(
            try Question(
                prompt: "Valid prompt?",
                options: ["Single Option"],
                correctAnswerIndex: 0,
                explanation: "Explanation",
                category: .swiftAndApple
            )
        ) { error in
            XCTAssertEqual(error as? Question.ValidationError, .insufficientOptions(count: 1))
        }
    }
    
    /// Verifies that specifying an answer index outside `options.indices` is caught defensively.
    func testInvalidCorrectIndexThrowsValidationError() {
        XCTAssertThrowsError(
            try Question(
                prompt: "Valid prompt?",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 5,
                explanation: "Explanation",
                category: .softwareEngineering
            )
        ) { error in
            XCTAssertEqual(error as? Question.ValidationError, .invalidCorrectIndex(index: 5, optionsCount: 4))
        }
    }
    
    /// Verifies that duplicate answer options are detected to prevent ambiguous question prompts.
    func testDuplicateOptionsThrowsValidationError() {
        XCTAssertThrowsError(
            try Question(
                prompt: "Valid prompt?",
                options: ["Same", "Same", "Other 1", "Other 2"],
                correctAnswerIndex: 0,
                explanation: "Explanation",
                category: .testingAndQuality
            )
        ) { error in
            XCTAssertEqual(error as? Question.ValidationError, .duplicateOptions)
        }
    }
    
    /// Verifies that Fisher-Yates randomization shuffles choices while recalculating
    /// the correct answer index so that the correct answer choice is never decoupled.
    func testShuffledOptionsPreservesCorrectAnswerMapping() throws {
        let question = try Question(
            prompt: "What is Swift's primary memory management model?",
            options: ["Garbage Collection", "Automatic Reference Counting (ARC)", "Manual Malloc", "None"],
            correctAnswerIndex: 1,
            explanation: "Swift uses ARC.",
            category: .swiftAndApple
        )
        
        let originalCorrectText = question.correctAnswerText
        
        // Execute multiple trials to rigorously test randomized permutations
        for _ in 0..<10 {
            let shuffled = question.shuffledOptions()
            XCTAssertEqual(shuffled.prompt, question.prompt)
            XCTAssertEqual(shuffled.options.count, 4)
            XCTAssertEqual(shuffled.options[shuffled.correctAnswerIndex], originalCorrectText)
            XCTAssertTrue(shuffled.isCorrect(selectedOptionIndex: shuffled.correctAnswerIndex))
        }
    }
    
    /// Verifies lossless Codable JSON serialization and deserialization.
    func testQuestionCodableRoundtrip() throws {
        let original = try Question(
            prompt: "What does TDD stand for?",
            options: ["Test-Driven Development", "Time-Dependent Delivery", "Target Domain Deployment", "Total Direct Debugging"],
            correctAnswerIndex: 0,
            explanation: "TDD stands for Test-Driven Development.",
            category: .testingAndQuality,
            difficulty: .easy
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Question.self, from: data)
        
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.prompt, original.prompt)
        XCTAssertEqual(decoded.category, .testingAndQuality)
        XCTAssertEqual(decoded.difficulty, .easy)
    }
}
