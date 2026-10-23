import XCTest

final class TrainYourBrainUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testCategoryRoundShowsFeedbackResultsAndCanReplay() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 10))
        XCTAssertTrue(category.label.contains("6 questions"))
        attachScreenshot(named: "Home - category counts")
        category.tap()

        let firstAnswer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(firstAnswer.frame.height, 56, "Answer controls must meet the 56 pt touch target")
        firstAnswer.tap()
        let firstFeedback = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Correct!", "Incorrect")
        ).firstMatch
        XCTAssertTrue(firstFeedback.waitForExistence(timeout: 5))
        attachScreenshot(named: "Quiz - answer feedback")
        app.buttons["quiz.advance"].tap()

        answerAndAdvance(questionCount: 5)

        let playAgain = app.buttons["result.playAgain"]
        XCTAssertTrue(playAgain.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Round Completed!"].exists || app.staticTexts["Good Effort!"].exists)
        attachScreenshot(named: "Results - completed round")
        playAgain.tap()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 5))

        app.buttons["quiz.close"].tap()
        XCTAssertTrue(category.waitForExistence(timeout: 5))
    }

    func testMixedRoundStartsAndReturnsToTopics() {
        app.launch()
        let mixedRound = app.buttons["home.category.mixed"]
        XCTAssertTrue(mixedRound.waitForExistence(timeout: 10))
        XCTAssertTrue(mixedRound.label.contains("24 questions"))
        attachScreenshot(named: "Home - mixed round")
        mixedRound.tap()

        let answer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        XCTAssertTrue(answer.label.hasPrefix("Option A:"))

        app.buttons["quiz.close"].tap()
        XCTAssertTrue(mixedRound.waitForExistence(timeout: 5))
    }

    func testIncorrectAnswerMarksTheCorrectOption() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 10))

        // Questions and answer order are shuffled, so retry a fresh round until option A is incorrect.
        for _ in 0..<10 {
            category.tap()
            let firstAnswer = app.buttons["quiz.answer.0"]
            XCTAssertTrue(firstAnswer.waitForExistence(timeout: 5))
            firstAnswer.tap()

            let incorrectFeedback = app.staticTexts["Incorrect"]
            if incorrectFeedback.waitForExistence(timeout: 2) {
                let correctAnswerState = app.buttons.matching(
                    NSPredicate(format: "value == %@", "Correct answer")
                ).firstMatch
                XCTAssertTrue(correctAnswerState.waitForExistence(timeout: 5))
                attachScreenshot(named: "Quiz - incorrect answer feedback")
                return
            }

            XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 5))
            app.buttons["quiz.close"].tap()
            XCTAssertTrue(category.waitForExistence(timeout: 5))
        }

        XCTFail("Could not sample an incorrect first answer in ten shuffled attempts")
    }

    func testAccessibilityDynamicTypeKeepsCategoryStartAvailable() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 10))
        XCTAssertTrue(category.isEnabled)
        XCTAssertTrue(category.label.contains("6 questions"))
        attachScreenshot(named: "Home - accessibility XXXL")

        category.tap()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 5))
    }

    private func answerAndAdvance(questionCount: Int) {
        for questionIndex in 0..<questionCount {
            let answer = app.buttons["quiz.answer.0"]
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "Question \(questionIndex + 1) did not appear")
            answer.tap()

            let advance = app.buttons["quiz.advance"]
            XCTAssertTrue(advance.waitForExistence(timeout: 5), "Feedback did not appear for question \(questionIndex + 1)")
            advance.tap()
        }
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
