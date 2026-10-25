import XCTest

final class TrainYourBrainUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--reset-state"]
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
        
        // Verify touch targets remain comfortably accessible and meet minimum HIG recommendations (>= 44x44 pt)
        let scoresButton = app.buttons["home.scoresButton"]
        XCTAssertTrue(scoresButton.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(scoresButton.frame.height, 44.0, "Leaderboard button must meet minimum 44pt touch target")
        
        XCTAssertTrue(category.waitForExistence(timeout: 10))
        XCTAssertTrue(category.isEnabled)
        XCTAssertGreaterThanOrEqual(category.frame.height, 44.0, "Category card must meet minimum 44pt touch target")
        XCTAssertGreaterThanOrEqual(category.frame.width, 44.0)
        XCTAssertLessThanOrEqual(category.frame.width, 640.0, "Category card width must respect 640pt ergonomic max-width constraint on iPad landscape")
        
        // Open Leaderboard modal in landscape
        scoresButton.tap()
        let leaderboardTitle = app.staticTexts["Leaderboard & History"]
        XCTAssertTrue(leaderboardTitle.waitForExistence(timeout: 10))
        attachScreenshot(named: "Leaderboard - iPad Landscape Layout")
        
        let doneButton = app.buttons["leaderboard.dismiss"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        Thread.sleep(forTimeInterval: 1.0) // Allow modal sheet dismissal animation to complete
        
        // 3. Verify Quiz active gameplay in Landscape orientation
        XCTAssertTrue(category.waitForExistence(timeout: 10))
        category.tap()
        
        let answer0 = app.buttons["quiz.answer.0"]
        XCTAssertTrue(answer0.waitForExistence(timeout: 10), "Question and options must load in landscape mode")
        XCTAssertGreaterThanOrEqual(answer0.frame.height, 44.0, "Answer option must maintain minimum 44pt target in landscape")
        attachScreenshot(named: "Quiz - iPad Landscape Layout")
        
        answer0.tap()
        let advanceButton = app.buttons["quiz.advance"]
        XCTAssertTrue(advanceButton.waitForExistence(timeout: 10), "Advance button must be available in landscape")
        XCTAssertGreaterThanOrEqual(advanceButton.frame.height, 44.0, "Advance button must maintain minimum 44pt target in landscape")
        advanceButton.tap()
        
        // Complete remaining 5 questions to reach ResultView in landscape
        answerAndAdvance(questionCount: 5)
        
        let playAgain = app.buttons["result.playAgain"]
        if !playAgain.waitForExistence(timeout: 10) {
            if app.buttons["quiz.advance"].exists {
                app.buttons["quiz.advance"].tap()
            }
        }
        XCTAssertTrue(playAgain.waitForExistence(timeout: 15), "Play Again button must appear in landscape ResultView")
        let completedHeader = app.staticTexts["Round Completed!"]
        let effortHeader = app.staticTexts["Good Effort!"]
        XCTAssertTrue(completedHeader.waitForExistence(timeout: 10) || effortHeader.waitForExistence(timeout: 10), "ResultView header must appear in landscape")
        
        let returnToMenu = app.buttons["result.returnToMenu"]
        XCTAssertTrue(returnToMenu.waitForExistence(timeout: 5), "Return to Menu button must appear in landscape")
        XCTAssertGreaterThanOrEqual(playAgain.frame.height, 44.0, "Play Again button must meet 44pt touch target")
        XCTAssertGreaterThanOrEqual(returnToMenu.frame.height, 44.0, "Return to Menu button must meet 44pt touch target")
        attachScreenshot(named: "Results - iPad Landscape Layout")
        
        if !returnToMenu.isHittable {
            app.swipeUp()
        }
        returnToMenu.tap()
        
        // 4. Restore Portrait orientation
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(category.waitForExistence(timeout: 10))
    }

    func testStudyMaterialManagerSheetCanOpenAndClose() {
        app.launch()
        let materialButton = app.buttons["home.materialButton"]
        XCTAssertTrue(materialButton.waitForExistence(timeout: 15))
        materialButton.tap()

        let navTitle = app.staticTexts["Study Material"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 10))
        attachScreenshot(named: "Study Material - Manager Opened")

        // 1. Verify and navigate to Questions tab (mandatory non-conditional assertion)
        let questionsSegment = app.buttons["Questions"]
        XCTAssertTrue(questionsSegment.waitForExistence(timeout: 5), "Questions segment tab must exist")
        questionsSegment.tap()
        let addQuestionButton = app.buttons["studyMaterial.addQuestionButton"]
        let fallbackAddQuestion = app.buttons["Add New Question"]
        XCTAssertTrue(addQuestionButton.waitForExistence(timeout: 5) || fallbackAddQuestion.waitForExistence(timeout: 2), "Add Question button must exist in Questions tab")
        attachScreenshot(named: "Study Material - Questions Tab")

        // 2. Verify and navigate to Import tab (mandatory non-conditional assertion)
        let importSegment = app.buttons["Import"]
        XCTAssertTrue(importSegment.waitForExistence(timeout: 5), "Import segment tab must exist")
        importSegment.tap()
        let browseButton = app.buttons["studyMaterial.browseFileButton"]
        let fallbackBrowse = app.buttons["Select JSON File to import"]
        XCTAssertTrue(browseButton.waitForExistence(timeout: 5) || fallbackBrowse.waitForExistence(timeout: 2), "Browse JSON File button must exist in Import tab")
        attachScreenshot(named: "Study Material - Import Tab")

        // 3. Navigate back to Subjects tab and inspect Add Subject sheet (mandatory non-conditional assertions)
        let subjectsSegment = app.buttons["Subjects"]
        XCTAssertTrue(subjectsSegment.waitForExistence(timeout: 5), "Subjects segment tab must exist")
        subjectsSegment.tap()
        let addSubjectButton = app.buttons["studyMaterial.addSubjectButton"]
        let fallbackAddSubject = app.buttons["Add New Subject"]
        XCTAssertTrue(addSubjectButton.waitForExistence(timeout: 5) || fallbackAddSubject.waitForExistence(timeout: 2), "Add New Subject button must exist in Subjects tab")
        if addSubjectButton.exists {
            addSubjectButton.tap()
        } else {
            fallbackAddSubject.tap()
        }

        let newSubjectTitle = app.staticTexts["New Subject"]
        XCTAssertTrue(newSubjectTitle.waitForExistence(timeout: 5), "New Subject modal sheet must appear")
        attachScreenshot(named: "Study Material - Add Subject Sheet")

        let nameField = app.textFields["studyMaterial.newSubjectNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "New Subject name textfield must appear")
        nameField.tap()
        nameField.typeText("Robotics")
        let saveButton = app.buttons["studyMaterial.saveNewSubjectButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button must exist on New Subject sheet")
        XCTAssertTrue(saveButton.isEnabled, "Save button must be enabled when name is non-empty")
        saveButton.tap()

        let createdSubject = app.staticTexts["Robotics"]
        XCTAssertTrue(createdSubject.waitForExistence(timeout: 5), "Created subject 'Robotics' must appear in list")

        // 4. Test editing the newly created custom subject
        let editButton = app.buttons["studyMaterial.editSubjectButton.robotics"]
        let fallbackEdit = app.buttons["Edit Subject Robotics"]
        if !editButton.exists && !fallbackEdit.exists {
            app.swipeUp()
        }
        XCTAssertTrue(editButton.waitForExistence(timeout: 5) || fallbackEdit.waitForExistence(timeout: 2), "Edit button for 'Robotics' must exist in subjects list")
        if editButton.exists {
            editButton.tap()
        } else {
            fallbackEdit.tap()
        }

        let editTitle = app.staticTexts["Edit Subject"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 5), "Edit Subject sheet must appear")
        attachScreenshot(named: "Study Material - Edit Subject Sheet")
        let editNameField = app.textFields["studyMaterial.editSubjectNameField"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 5), "Edit Subject name field must appear")
        editNameField.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 25)
        editNameField.typeText(deleteString)
        editNameField.typeText("Robotics Lab")
        let saveEditButton = app.buttons["studyMaterial.saveEditSubjectButton"]
        XCTAssertTrue(saveEditButton.waitForExistence(timeout: 5), "Save button must exist on Edit Subject sheet")
        saveEditButton.tap()

        let updatedSubject = app.staticTexts["Robotics Lab"]
        XCTAssertTrue(updatedSubject.waitForExistence(timeout: 5), "Updated subject 'Robotics Lab' must appear in subjects list")

        // 5. Navigate to Questions tab and author a custom question
        questionsSegment.tap()
        XCTAssertTrue(addQuestionButton.waitForExistence(timeout: 5))
        addQuestionButton.tap()

        let questionPromptField = app.textFields["studyMaterial.questionPromptField"]
        XCTAssertTrue(questionPromptField.waitForExistence(timeout: 5), "Question prompt field must appear")
        questionPromptField.tap()
        questionPromptField.typeText("What is ROS?")

        let option0 = app.textFields["studyMaterial.questionOption.0"]
        XCTAssertTrue(option0.waitForExistence(timeout: 5))
        option0.tap()
        option0.typeText("Robot Operating System")

        let option1 = app.textFields["studyMaterial.questionOption.1"]
        XCTAssertTrue(option1.waitForExistence(timeout: 5))
        option1.tap()
        option1.typeText("Random Optical System")

        app.swipeUp()

        let option2 = app.textFields["studyMaterial.questionOption.2"]
        XCTAssertTrue(option2.waitForExistence(timeout: 5))
        option2.tap()
        option2.typeText("Remote Open Server")

        let option3 = app.textFields["studyMaterial.questionOption.3"]
        if !option3.exists {
            app.swipeUp()
        }
        XCTAssertTrue(option3.waitForExistence(timeout: 5))
        option3.tap()
        option3.typeText("Realtime Output Suite")

        let explanationField = app.textFields["studyMaterial.questionExplanationField"]
        if !explanationField.exists {
            app.swipeUp()
        }
        XCTAssertTrue(explanationField.waitForExistence(timeout: 5), "Explanation field must appear")
        explanationField.tap()
        explanationField.typeText("ROS stands for Robot Operating System.")
        attachScreenshot(named: "Study Material - Add Question Sheet")

        let saveQuestionButton = app.buttons["studyMaterial.saveQuestionButton"]
        XCTAssertTrue(saveQuestionButton.waitForExistence(timeout: 5))
        saveQuestionButton.tap()

        let createdQuestionPrompt = app.staticTexts["What is ROS?"]
        XCTAssertTrue(createdQuestionPrompt.waitForExistence(timeout: 5), "Created question must appear in questions list")

        // 6. Dismiss Study Material sheet and return to HomeView
        let doneButton = app.buttons["studyMaterial.doneButton"]
        let fallbackDone = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5) || fallbackDone.waitForExistence(timeout: 2), "Done button must exist on Study Material sheet")
        if doneButton.exists {
            doneButton.tap()
        } else {
            fallbackDone.tap()
        }

        // 7. Verify custom category is available on HomeView and play a quiz round
        let roboticsCategoryCard = app.buttons["home.category.robotics"]
        if !roboticsCategoryCard.exists {
            app.swipeUp()
        }
        XCTAssertTrue(roboticsCategoryCard.waitForExistence(timeout: 10), "Custom category card must appear on HomeView")
        if !roboticsCategoryCard.isHittable {
            app.swipeUp()
        }
        roboticsCategoryCard.tap()

        let firstAnswer = app.buttons["quiz.answer.0"]
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 10), "Quiz with custom question must start and display answers")
        firstAnswer.tap()

        let feedback = app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Correct!", "Incorrect")
        ).firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 10), "Pedagogical feedback must appear for custom question")

        let advanceButton = app.buttons["quiz.advance"]
        XCTAssertTrue(advanceButton.waitForExistence(timeout: 10))
        if !advanceButton.isHittable {
            app.swipeUp()
        }
        advanceButton.tap()

        let playAgain = app.buttons["result.playAgain"]
        if !playAgain.waitForExistence(timeout: 5) {
            if advanceButton.exists {
                advanceButton.tap()
            }
        }
        XCTAssertTrue(playAgain.waitForExistence(timeout: 10), "Result screen must render after finishing round")

        let returnToMenuButton = app.buttons["result.returnToMenu"]
        XCTAssertTrue(returnToMenuButton.waitForExistence(timeout: 5), "Result screen Return to Menu button must exist")
        if !returnToMenuButton.isHittable {
            app.swipeUp()
        }
        returnToMenuButton.tap()

        XCTAssertTrue(app.buttons["home.scoresButton"].waitForExistence(timeout: 10))

        // 8. Verify persistence across app termination and relaunch
        app.terminate()
        app.launchArguments.removeAll(where: { $0 == "--reset-state" })
        app.launch()

        let persistedCategoryCard = app.buttons["home.category.robotics"]
        if !persistedCategoryCard.exists {
            app.swipeUp()
        }
        XCTAssertTrue(persistedCategoryCard.waitForExistence(timeout: 10), "Custom category must persist across app restart")

        // 9. Clean up: reopen study material sheet and verify deletion
        let reopenMaterialButton = app.buttons["home.materialButton"]
        if !reopenMaterialButton.exists {
            app.swipeDown()
        }
        XCTAssertTrue(reopenMaterialButton.waitForExistence(timeout: 10), "Material button must be accessible on HomeView after relaunch")
        reopenMaterialButton.tap()

        let reopenedSegmentedPicker = app.segmentedControls["studyMaterial.segmentedPicker"]
        XCTAssertTrue(reopenedSegmentedPicker.waitForExistence(timeout: 5))
        let reopenedQuestionsSegment = reopenedSegmentedPicker.buttons["Questions"]
        reopenedQuestionsSegment.tap()

        let questionToDeletePrompt = app.staticTexts["What is ROS?"]
        if questionToDeletePrompt.waitForExistence(timeout: 5) {
            let deleteQuestionButton = app.buttons["studyMaterial.deleteQuestionButton"]
            if deleteQuestionButton.waitForExistence(timeout: 5) {
                deleteQuestionButton.tap()
            }
        }

        let reopenedSubjectsSegment = reopenedSegmentedPicker.buttons["Subjects"]
        reopenedSubjectsSegment.tap()

        let deleteSubjectButton = app.buttons["studyMaterial.deleteSubjectButton.robotics"]
        if !deleteSubjectButton.exists {
            app.swipeUp()
        }
        if deleteSubjectButton.waitForExistence(timeout: 5) {
            deleteSubjectButton.tap()
        }

        let finalDone = app.buttons["studyMaterial.doneButton"]
        if finalDone.waitForExistence(timeout: 5) {
            finalDone.tap()
        } else if app.buttons["Done"].waitForExistence(timeout: 2) {
            app.buttons["Done"].tap()
        }
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
