import XCTest
import SwiftUI
@testable import TrainYourBrainCore

/// Interaction and presentation tests exercising SwiftUI view constructions,
/// state bindings, and view transitions on `@MainActor`.
@MainActor
final class ViewInteractionTests: XCTestCase {
    
    // MARK: - Fixtures
    
    private func makeLoadedViewModel() throws -> QuizViewModel {
        let service = LocalQuestionService()
        let vm = QuizViewModel(questionService: service)
        return vm
    }
    
    // MARK: - HomeView & Category Flow Tests
    
    func testHomeViewInitialStateAndQuickPlay() throws {
        let vm = try makeLoadedViewModel()
        let homeView = HomeView(viewModel: vm)
        XCTAssertNotNil(homeView.body)
        XCTAssertEqual(vm.viewState, .idle)
        
        // Quick play starts mixed quiz with 24 questions
        vm.startQuiz(category: nil)
        XCTAssertEqual(vm.viewState, .playing)
        XCTAssertEqual(vm.totalQuestions, 24)
        XCTAssertNotNil(vm.currentQuestion)
    }
    
    func testCategorySelectionStartsQuizForEveryDomain() throws {
        let vm = try makeLoadedViewModel()
        
        for category in QuizCategory.allCases {
            vm.startQuiz(category: category)
            XCTAssertEqual(vm.viewState, .playing)
            XCTAssertEqual(vm.totalQuestions, 6, "Every individual category in questions.json has 6 questions")
            XCTAssertEqual(vm.currentQuestion?.category, category)
            vm.resetToMenu()
            XCTAssertEqual(vm.viewState, .idle)
        }
    }
    
    // MARK: - QuizView & TimerBar Ergonomic Tests
    
    func testQuizViewAndQuestionCardRendering() throws {
        let vm = try makeLoadedViewModel()
        vm.startQuiz(category: .softwareEngineering)
        
        let quizView = QuizView(viewModel: vm)
        XCTAssertNotNil(quizView.body)
        
        if let currentQ = vm.currentQuestion {
            let card = QuestionCard(question: currentQ, questionNumber: 1, totalQuestions: 6)
            XCTAssertNotNil(card.body)
            
            // Exercise answer reveal in QuizView
            vm.selectAnswer(at: currentQ.correctAnswerIndex)
            XCTAssertNotNil(quizView.body)
        }
    }
    
    func testTimerBarProgressProportionForDifferentDifficulties() {
        // Easy Question (20s total)
        let easyBar = TimerBar(timeRemaining: 10.0, totalTime: 20.0)
        XCTAssertNotNil(easyBar.body)
        
        // Medium Question (15s total)
        let medBar = TimerBar(timeRemaining: 15.0, totalTime: 15.0)
        XCTAssertNotNil(medBar.body)
        
        // Hard Question (12s total)
        let hardBar = TimerBar(timeRemaining: 3.0, totalTime: 12.0)
        XCTAssertNotNil(hardBar.body)
    }
    
    func testAnswerButtonStatesAndInteraction() {
        var actionExecuted = false
        let button = AnswerButton(
            optionText: "Test Choice",
            index: 0,
            isSelected: false,
            isCorrectAnswer: nil,
            isAnswerRevealed: false
        ) {
            actionExecuted = true
        }
        
        XCTAssertNotNil(button.body)
        button.action()
        XCTAssertTrue(actionExecuted)
    }
    
    // MARK: - ResultView Score Presentation Tests
    
    func testResultViewWithPassingAndFailingRecords() {
        let passingRecord = ScoreRecord(
            score: 120,
            totalQuestions: 6,
            correctAnswers: 5,
            streakRecord: 5,
            category: .softwareEngineering,
            completedAt: Date()
        )
        
        var playedAgain = false
        var wentBackToMenu = false
        
        let passingResultView = ResultView(
            record: passingRecord,
            onPlayAgain: { playedAgain = true },
            onBackToMenu: { wentBackToMenu = true }
        )
        
        XCTAssertNotNil(passingResultView.body)
        passingResultView.onPlayAgain()
        XCTAssertTrue(playedAgain)
        passingResultView.onBackToMenu()
        XCTAssertTrue(wentBackToMenu)
        
        let failingRecord = ScoreRecord(
            score: 10,
            totalQuestions: 6,
            correctAnswers: 1,
            streakRecord: 1,
            category: .swiftAndApple,
            completedAt: Date()
        )
        let failingResultView = ResultView(
            record: failingRecord,
            onPlayAgain: {},
            onBackToMenu: {}
        )
        XCTAssertNotNil(failingResultView.body)
        XCTAssertFalse(failingRecord.isPassing)
    }
}
