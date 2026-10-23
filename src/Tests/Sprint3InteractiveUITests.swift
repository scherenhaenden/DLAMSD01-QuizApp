import XCTest
import SwiftUI
@testable import TrainYourBrainCore

/// Regression checks for Sprint 3: Modular & Interactive Presentation Components (v0.3.0).
/// Exercises button state resolution, accessibility strings, touch-target constants, and metadata.
@MainActor
final class Sprint3InteractiveUITests: XCTestCase {
    
    // MARK: - AnswerButton State Machine Tests
    
    func testAnswerButtonStateResolution() {
        // 1. Idle & unselected
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: false, isCorrectAnswer: nil, isAnswerRevealed: false),
            .idle
        )
        
        // 2. Idle & selected before reveal
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: true, isCorrectAnswer: nil, isAnswerRevealed: false),
            .selected
        )
        
        // 3. Revealed & correct (user picked correctly)
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: true, isCorrectAnswer: true, isAnswerRevealed: true),
            .correct
        )
        
        // 4. Revealed & correct (user picked another option, but this is the right answer)
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: false, isCorrectAnswer: true, isAnswerRevealed: true),
            .correct
        )
        
        // 5. Revealed & wrong (user picked this wrong option)
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: true, isCorrectAnswer: false, isAnswerRevealed: true),
            .wrong
        )
        
        // 6. Revealed & dimmed (unselected incorrect choice)
        XCTAssertEqual(
            AnswerButton.resolveVisualState(isSelected: false, isCorrectAnswer: false, isAnswerRevealed: true),
            .dimmed
        )
    }
    
    func testAnswerButtonAccessibilityStrings() {
        let optionText = "Automatic Reference Counting (ARC) guarantees deterministic object deallocation."
        
        // Idle state hint
        let idleHint = AnswerButton.accessibilityHintText(for: .idle)
        XCTAssertEqual(idleHint, "Double tap to select this answer.")
        
        // Selected state hint
        let selectedHint = AnswerButton.accessibilityHintText(for: .selected)
        XCTAssertEqual(selectedHint, "Selected. Double tap to change selection.")
        
        // Revealed correct hint
        let correctHint = AnswerButton.accessibilityHintText(for: .correct)
        XCTAssertTrue(correctHint.contains("Correct answer"))
        
        // Revealed wrong hint
        let wrongHint = AnswerButton.accessibilityHintText(for: .wrong)
        XCTAssertTrue(wrongHint.contains("Incorrect answer"))
        
        // Label format
        let label = AnswerButton.formattedAccessibilityLabel(letter: "A", text: optionText)
        XCTAssertEqual(label, "Option A: \(optionText)")
    }
    
    func testAnswerButtonErgonomicTouchTargetHeight() {
        // Apple HIG specifies 44 pt minimum. Sprint 3 requires >= 56 pt for mobile ergonomic usage.
        XCTAssertGreaterThanOrEqual(
            AnswerButton.minTouchTargetHeight,
            56.0,
            "AnswerButton must guarantee at least 56 pt touch target height"
        )
    }
    
    func testAnswerButtonRenderingWithLongText() {
        var actionExecuted = false
        let longText = "This is an extraordinarily verbose software engineering answer option that intentionally tests multiline wrapping and Dynamic Type scaling without truncation or ellipses clipping across compact mobile displays."
        
        let button = AnswerButton(
            optionText: longText,
            index: 0,
            isSelected: false,
            isCorrectAnswer: nil,
            isAnswerRevealed: false,
            action: { actionExecuted = true }
        )
        
        XCTAssertNotNil(button.body)
        button.action()
        XCTAssertTrue(actionExecuted)
    }
    
    // MARK: - QuestionCard Presentation Tests
    
    func testQuestionCardMetadataAndDifficultyBadges() throws {
        let question = try Question(
            id: UUID(),
            prompt: "What is the theoretical time complexity of quickselect in the average case?",
            options: ["O(n)", "O(n log n)", "O(n^2)", "O(1)"],
            correctAnswerIndex: 0,
            explanation: "Average-case quickselect runs in O(n) using randomized partitioning.",
            category: .algorithmsAndDataStructures,
            difficulty: .hard
        )
        
        let card = QuestionCard(question: question, questionNumber: 3, totalQuestions: 10)
        XCTAssertNotNil(card.body)
        
        // Invariants
        XCTAssertEqual(card.question.category, QuizCategory.algorithmsAndDataStructures)
        XCTAssertEqual(card.question.difficulty, Difficulty.hard)
        XCTAssertEqual(card.question.difficulty.timeLimitSeconds, 12.0)
        XCTAssertEqual(card.questionNumber, 3)
        XCTAssertEqual(card.totalQuestions, 10)
        
        // Accessibility string
        let accessibilityLabel = card.combinedAccessibilityLabel
        XCTAssertTrue(accessibilityLabel.contains("Question 3 of 10"))
        XCTAssertTrue(accessibilityLabel.contains("Data Structures & Algorithms"))
        XCTAssertTrue(accessibilityLabel.contains("Hard"))
    }
    
    // MARK: - CategoryCard Presentation Tests
    
    func testCategoryCardRenderingAndProperties() {
        var tapped = false
        let card = CategoryCard(
            category: .softwareEngineering,
            questionCount: 6,
            isSelected: true,
            action: { tapped = true }
        )
        
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.category?.displayName, "Software Engineering")
        XCTAssertEqual(card.questionCount, 6)
        XCTAssertTrue(card.isSelected)
        
        card.action()
        XCTAssertTrue(tapped)
    }
    
    func testMixedDomainCardRendering() {
        var tapped = false
        let mixedCard = CategoryCard(
            category: nil,
            questionCount: 24,
            isSelected: false,
            action: { tapped = true }
        )
        
        XCTAssertNotNil(mixedCard.body)
        XCTAssertEqual(mixedCard.title, "All Topics (Mixed)")
        XCTAssertEqual(mixedCard.questionCount, 24)
        XCTAssertFalse(mixedCard.isSelected)
        
        mixedCard.action()
        XCTAssertTrue(tapped)
    }
}
