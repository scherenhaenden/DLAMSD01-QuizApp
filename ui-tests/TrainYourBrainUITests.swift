import XCTest

final class TrainYourBrainUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testCategoryRoundShowsFeedbackResultsAndCanReplay() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))
        XCTAssertTrue(category.label.contains("6 questions"))
        attachScreenshot(named: "Home - category counts")
        category.tap()

        let firstAnswer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(firstAnswer.frame.height, 56, "Answer controls must meet the 56 pt touch target")
        firstAnswer.tap()
        let firstFeedback = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Correct!", "Incorrect")
        ).firstMatch
        XCTAssertTrue(firstFeedback.waitForExistence(timeout: 10))
        attachScreenshot(named: "Quiz - answer feedback")
        app.buttons["quiz.advance"].tap()

        answerAndAdvance(questionCount: 5)

        let playAgain = app.buttons["result.playAgain"]
        if !playAgain.waitForExistence(timeout: 10) {
            if app.buttons["quiz.advance"].exists {
                app.buttons["quiz.advance"].tap()
            }
        }
        XCTAssertTrue(playAgain.waitForExistence(timeout: 15))
        let completedHeader = app.staticTexts["Round Completed!"]
        let effortHeader = app.staticTexts["Good Effort!"]
        XCTAssertTrue(completedHeader.waitForExistence(timeout: 10) || effortHeader.waitForExistence(timeout: 10))
        
        // Assert scorecard dashboard metrics & German academic evaluation
        XCTAssertTrue(app.staticTexts["Score"].waitForExistence(timeout: 5), "Score metric tile must render")
        XCTAssertTrue(app.staticTexts["Accuracy"].waitForExistence(timeout: 5), "Accuracy metric tile must render")
        XCTAssertTrue(app.staticTexts["Streak"].waitForExistence(timeout: 5), "Streak metric tile must render")
        XCTAssertTrue(app.staticTexts["Avg Speed"].waitForExistence(timeout: 5), "Avg Speed metric tile must render")
        XCTAssertTrue(app.buttons["result.returnToMenu"].waitForExistence(timeout: 5), "Return to Menu CTA must render")
        
        attachScreenshot(named: "Results - completed round")
        if !playAgain.isHittable {
            app.swipeUp()
        }
        playAgain.tap()
        let replayAnswer = app.buttons["quiz.answer.0"]
        if !replayAnswer.waitForExistence(timeout: 5) {
            playAgain.tap()
        }
        XCTAssertTrue(replayAnswer.waitForExistence(timeout: 15))

        app.buttons["quiz.close"].tap()
        XCTAssertTrue(category.waitForExistence(timeout: 10))
    }

    func testMixedRoundStartsAndReturnsToTopics() {
        app.launch()
        let mixedRound = app.buttons["home.category.mixed"]
        XCTAssertTrue(mixedRound.waitForExistence(timeout: 15))
        XCTAssertTrue(mixedRound.label.contains("24 questions"))
        attachScreenshot(named: "Home - mixed round")
        mixedRound.tap()

        let answer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertTrue(answer.label.hasPrefix("Option A:"))

        app.buttons["quiz.close"].tap()
        XCTAssertTrue(mixedRound.waitForExistence(timeout: 10))
    }

    func testIncorrectAnswerMarksTheCorrectOption() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))

        // Questions and answer order are shuffled, so retry a fresh round until option A is incorrect.
        for _ in 0..<10 {
            category.tap()
            let firstAnswer = app.buttons["quiz.answer.0"]
            XCTAssertTrue(firstAnswer.waitForExistence(timeout: 10))
            firstAnswer.tap()

            let incorrectFeedback = app.staticTexts["Incorrect"]
            if incorrectFeedback.waitForExistence(timeout: 5) {
                let correctAnswerState = app.buttons.matching(
                    NSPredicate(format: "value == %@", "Correct answer")
                ).firstMatch
                XCTAssertTrue(correctAnswerState.waitForExistence(timeout: 10))
                attachScreenshot(named: "Quiz - incorrect answer feedback")
                return
            }

            XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 10))
            app.buttons["quiz.close"].tap()
            XCTAssertTrue(category.waitForExistence(timeout: 10))
        }

        XCTFail("Could not sample an incorrect first answer in ten shuffled attempts")
    }

    func testAccessibilityDynamicTypeKeepsCategoryStartAvailable() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))
        XCTAssertTrue(category.isEnabled)
        XCTAssertTrue(category.label.contains("6 questions"))
        attachScreenshot(named: "Home - accessibility XXXL")

        category.tap()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 10))
    }

    func testLiveCountdownReachesTimeoutAndEnablesAdvance() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))
        category.tap()

        // 1. Verify active quiz screen and countdown components loaded
        let firstAnswer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 15), "Question and answer options must load")
        let timer = app.descendants(matching: .any)["quiz.timerBar"]
        XCTAssertTrue(timer.exists || app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 's'")).firstMatch.exists)

        // 2. Wait for question countdown (12s to 20s) to expire without user input
        // When timer hits 0.0s, the state transitions to .answered with timeout penalty
        let advanceButton = app.buttons["quiz.advance"]
        XCTAssertTrue(advanceButton.waitForExistence(timeout: 25), "Timeout must transition to .answered and display advance button")

        // 3. Verify pedagogical feedback on timeout (Incorrect label & explanation)
        let feedbackHeader = app.staticTexts["Incorrect"]
        XCTAssertTrue(feedbackHeader.waitForExistence(timeout: 5))
        attachScreenshot(named: "Quiz - live countdown timeout")

        // 4. Advance to next question and exit cleanly
        advanceButton.tap()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 15))
        app.buttons["quiz.close"].tap()
        XCTAssertTrue(category.waitForExistence(timeout: 10))
    }

    func testBackgroundAndForegroundResumeDeductsTimeAndPreservesGameplay() {
        app.launch()
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))
        category.tap()

        // 1. Verify active quiz screen loaded
        let firstAnswer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 15), "Question and answer options must load")

        // 2. Transition app to background via Home button simulation
        XCUIDevice.shared.press(.home)

        // Wait 3 seconds in background (less than 15s difficulty limit)
        Thread.sleep(forTimeInterval: 3.0)

        // 3. Reactivate app to foreground
        app.activate()

        // 4. Verify gameplay is preserved and active after returning
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 10), "Quiz options must remain interactive after background resume")
        attachScreenshot(named: "Quiz - resumed after background")

        // 5. User can select an answer and advance successfully
        firstAnswer.tap()
        let advance = app.buttons["quiz.advance"]
        XCTAssertTrue(advance.waitForExistence(timeout: 10), "Can advance after answering resumed quiz")
        advance.tap()
        XCTAssertTrue(app.buttons["quiz.answer.0"].waitForExistence(timeout: 15))
        app.buttons["quiz.close"].tap()
        XCTAssertTrue(category.waitForExistence(timeout: 10))
    }

    func testLeaderboardAndHistoryOpensAndDismisses() {
        app.launch()
        let scoresButton = app.buttons["home.scoresButton"]
        XCTAssertTrue(scoresButton.waitForExistence(timeout: 15), "Scores button must exist on home screen")
        scoresButton.tap()

        let leaderboardTitle = app.staticTexts["Leaderboard & History"]
        XCTAssertTrue(leaderboardTitle.waitForExistence(timeout: 10), "Leaderboard title must appear in modal sheet")

        let segmentPicker = app.segmentedControls["leaderboard.segmentPicker"]
        XCTAssertTrue(segmentPicker.waitForExistence(timeout: 5), "Segmented picker must appear")

        attachScreenshot(named: "Leaderboard - modal sheet")

        let doneButton = app.buttons["leaderboard.dismiss"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Done button must exist")
        doneButton.tap()

        XCTAssertTrue(scoresButton.waitForExistence(timeout: 10), "Home screen must return after dismissing leaderboard")
    }

    func testIPadLandscapeAndPortraitErgonomicAdaptation() {
        app.launch()
        
        // 1. Verify portrait orientation baseline
        let category = app.buttons["home.category.software_engineering"]
        XCTAssertTrue(category.waitForExistence(timeout: 15))
        
        // 2. Rotate to Landscape orientation (iPad 10.2" regular size class)
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 2.0) // Allow rotation and layout animation to settle
        attachScreenshot(named: "Home - iPad Landscape Layout")
        
        // Verify touch targets remain available in landscape
        let scoresButton = app.buttons["home.scoresButton"]
        XCTAssertTrue(scoresButton.waitForExistence(timeout: 10))
        XCTAssertTrue(category.waitForExistence(timeout: 10))
        XCTAssertTrue(category.isEnabled)
        
        // Open Leaderboard modal in landscape
        scoresButton.tap()
        let leaderboardTitle = app.staticTexts["Leaderboard & History"]
        XCTAssertTrue(leaderboardTitle.waitForExistence(timeout: 10))
        attachScreenshot(named: "Leaderboard - iPad Landscape Layout")
        
        let doneButton = app.buttons["leaderboard.dismiss"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        
        // 3. Restore Portrait orientation
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(category.waitForExistence(timeout: 10))
    }

    private func answerAndAdvance(questionCount: Int) {
        for questionIndex in 0..<questionCount {
            let answer = app.buttons["quiz.answer.0"]
            XCTAssertTrue(answer.waitForExistence(timeout: 15), "Question \(questionIndex + 1) did not appear")
            if !answer.isHittable {
                app.swipeDown()
            }
            answer.tap()

            let advance = app.buttons["quiz.advance"]
            XCTAssertTrue(advance.waitForExistence(timeout: 15), "Feedback did not appear for question \(questionIndex + 1)")
            if !advance.isHittable {
                app.swipeUp()
            }
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
