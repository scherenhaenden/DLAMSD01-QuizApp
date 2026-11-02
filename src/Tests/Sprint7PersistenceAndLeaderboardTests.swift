import XCTest
import SwiftUI
@testable import TrainYourBrainCore

final class Sprint7PersistenceAndLeaderboardTests: XCTestCase {
    private var testUserDefaults: UserDefaults!
    private let testSuiteName = "com.trainyourbrain.tests.sprint7"
    private let testStorageKey = "test.scores.key"
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: testSuiteName)
        testUserDefaults.removePersistentDomain(forName: testSuiteName)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: testSuiteName)
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - 1. UserDefaultsScoreStore Save & Load Chronological
    
    func testUserDefaultsScoreStoreSavesAndLoadsRecordsChronologically() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey,
            maxCapacity: 50
        )
        
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let date3 = Date(timeIntervalSince1970: 1500)
        
        let record1 = ScoreRecord(score: 50, totalQuestions: 10, correctAnswers: 5, completedAt: date1)
        let record2 = ScoreRecord(score: 80, totalQuestions: 10, correctAnswers: 8, completedAt: date2)
        let record3 = ScoreRecord(score: 65, totalQuestions: 10, correctAnswers: 6, completedAt: date3)
        
        try store.save(record: record1)
        try store.save(record: record2)
        try store.save(record: record3)
        
        let loaded = store.loadRecords()
        XCTAssertEqual(loaded.count, 3)
        // Expected order: date2 (2000) -> date3 (1500) -> date1 (1000)
        XCTAssertEqual(loaded[0].score, 80)
        XCTAssertEqual(loaded[1].score, 65)
        XCTAssertEqual(loaded[2].score, 50)
    }
    
    // MARK: - 2. High Scores Sorting & Tie-Breaking
    
    func testUserDefaultsScoreStoreSortsHighScoresWithTieBreakers() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey
        )
        
        let now = Date()
        let older = now.addingTimeInterval(-3600)
        
        // r1: 100 pts, 90% accuracy, streak 4, older
        let r1 = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 9, streakRecord: 4, completedAt: older)
        // r2: 100 pts, 90% accuracy, streak 5, older (wins tie on streak)
        let r2 = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 9, streakRecord: 5, completedAt: older)
        // r3: 100 pts, 100% accuracy, streak 3 (wins tie on accuracy)
        let r3 = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, streakRecord: 3, completedAt: older)
        // r4: 120 pts (highest overall score)
        let r4 = ScoreRecord(score: 120, totalQuestions: 10, correctAnswers: 8, streakRecord: 2, completedAt: older)
        // r5: 50 pts
        let r5 = ScoreRecord(score: 50, totalQuestions: 10, correctAnswers: 5, streakRecord: 1, completedAt: older)
        
        try store.save(record: r1)
        try store.save(record: r2)
        try store.save(record: r3)
        try store.save(record: r4)
        try store.save(record: r5)
        
        let highScores = store.loadHighScores(limit: 10)
        XCTAssertEqual(highScores.count, 5)
        XCTAssertEqual(highScores[0].score, 120) // r4
        XCTAssertEqual(highScores[1].accuracyPercentage, 100) // r3
        XCTAssertEqual(highScores[2].streakRecord, 5) // r2
        XCTAssertEqual(highScores[3].streakRecord, 4) // r1
        XCTAssertEqual(highScores[4].score, 50) // r5
    }
    
    // MARK: - 3. Capacity Capping
    
    func testScoreStoreEnforcesCapacityCap() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey,
            maxCapacity: 3
        )
        
        for i in 1...6 {
            let record = ScoreRecord(
                score: i * 10,
                totalQuestions: 10,
                correctAnswers: i,
                completedAt: Date(timeIntervalSince1970: TimeInterval(i * 100))
            )
            try store.save(record: record)
        }
        
        let loaded = store.loadRecords()
        XCTAssertEqual(loaded.count, 3, "Store must cap records at maxCapacity")
        // The retained entries should be the newest 3: 60, 50, 40
        XCTAssertEqual(loaded.map { $0.score }, [60, 50, 40])
    }
    
    // MARK: - 4. Best Score Retrieval by Category and Global
    
    func testBestScoreRetrievalByCategoryAndGlobal() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey
        )
        
        let swift1 = ScoreRecord(score: 70, totalQuestions: 10, correctAnswers: 7, category: .swiftAndApple)
        let swift2 = ScoreRecord(score: 95, totalQuestions: 10, correctAnswers: 9, category: .swiftAndApple)
        let arch1 = ScoreRecord(score: 110, totalQuestions: 10, correctAnswers: 10, category: .softwareEngineering)
        
        try store.save(record: swift1)
        try store.save(record: swift2)
        try store.save(record: arch1)
        
        XCTAssertEqual(store.bestScore(for: .swiftAndApple)?.score, 95)
        XCTAssertEqual(store.bestScore(for: .softwareEngineering)?.score, 110)
        XCTAssertNil(store.bestScore(for: .testingAndQuality))
        XCTAssertEqual(store.bestScore(for: nil)?.score, 110)
    }
    
    // MARK: - 5. Corrupted Data Recovery
    
    func testCorruptedDataRecoveryInUserDefaultsScoreStore() {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey
        )
        
        // Write corrupted arbitrary bytes into the key
        let corruptRaw = "Corrupted JSON Payload {invalid".data(using: .utf8)!
        testUserDefaults.set(corruptRaw, forKey: testStorageKey)
        
        let loaded = store.loadRecords()
        XCTAssertTrue(loaded.isEmpty, "Corrupted storage must recover safely with empty array")
        XCTAssertNil(testUserDefaults.data(forKey: testStorageKey), "Corrupted payload must be discarded from active key")
        XCTAssertEqual(store.loadCorruptedBackupData(), corruptRaw, "Corrupted payload must be preserved in backup key")
        
        // Repeated load should remain empty and preserve backup
        let reloaded = store.loadRecords()
        XCTAssertTrue(reloaded.isEmpty)
        XCTAssertEqual(store.loadCorruptedBackupData(), corruptRaw)
        
        // Subsequent save should write to active key without destroying backup
        try? store.save(record: ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10))
        XCTAssertEqual(store.loadRecords().count, 1)
        XCTAssertEqual(store.loadCorruptedBackupData(), corruptRaw)
    }
    
    // MARK: - 6. Clear All Records
    
    func testClearAllRemovesStoredRecords() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey
        )
        
        try store.save(record: ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10))
        try store.save(record: ScoreRecord(score: 80, totalQuestions: 10, correctAnswers: 8))
        XCTAssertEqual(store.loadRecords().count, 2)
        
        try store.clearAll()
        XCTAssertTrue(store.loadRecords().isEmpty)
    }
    
    // MARK: - 7. QuizViewModel Auto-Saves on Completion
    
    @MainActor
    func testQuizViewModelAutoSavesRecordOnSessionCompletion() throws {
        let memoryStore = InMemoryScoreStore()
        let q1 = try Question(
            prompt: "P1",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Explanation 1",
            category: .swiftAndApple
        )
        let mockService = MockQuestionService(preloaded: [q1])
        let viewModel = QuizViewModel(
            questionService: mockService,
            scoreStore: memoryStore
        )
        
        viewModel.loadQuestionCatalog()
        viewModel.startQuiz(category: .swiftAndApple)
        XCTAssertEqual(viewModel.viewState, .playing)
        
        guard let correctIndex = viewModel.currentQuestion?.correctAnswerIndex else {
            XCTFail("Missing current question")
            return
        }
        viewModel.selectAnswer(at: correctIndex)
        XCTAssertEqual(memoryStore.loadRecords().count, 0, "Record is not saved before nextQuestion")
        
        viewModel.nextQuestion() // Completes session
        guard case .finished(let record) = viewModel.viewState else {
            XCTFail("ViewModel should transition to .finished")
            return
        }
        
        let savedRecords = memoryStore.loadRecords()
        XCTAssertEqual(savedRecords.count, 1)
        XCTAssertEqual(savedRecords.first?.id, record.id)
        XCTAssertEqual(savedRecords.first?.score, record.score)
        XCTAssertEqual(savedRecords.first?.correctAnswers, 1)
    }
    
    // MARK: - 8. LeaderboardViewModel Filtering & Aggregation
    
    @MainActor
    func testLeaderboardViewModelFilteringAndAggregation() {
        let store = InMemoryScoreStore()
        let r1 = ScoreRecord(score: 80, totalQuestions: 10, correctAnswers: 8, category: .swiftAndApple)
        let r2 = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, category: .swiftAndApple)
        let r3 = ScoreRecord(score: 60, totalQuestions: 10, correctAnswers: 6, category: .softwareEngineering)
        
        try? store.save(record: r1)
        try? store.save(record: r2)
        try? store.save(record: r3)
        
        let vm = LeaderboardViewModel(scoreStore: store)
        XCTAssertEqual(vm.totalGamesCount, 3)
        XCTAssertEqual(vm.displayedRecords.count, 3)
        // High scores tab sorts by score desc: 100, 80, 60
        XCTAssertEqual(vm.displayedRecords[0].score, 100)
        XCTAssertEqual(vm.displayedRecords[1].score, 80)
        XCTAssertEqual(vm.displayedRecords[2].score, 60)
        // Average accuracy: (80 + 100 + 60) / 3 = 80%
        XCTAssertEqual(vm.averageAccuracy, 80)
        XCTAssertEqual(vm.personalBest?.score, 100)
        
        // Filter by category
        vm.selectedCategory = .swiftAndApple
        XCTAssertEqual(vm.totalGamesCount, 2)
        XCTAssertEqual(vm.displayedRecords.count, 2)
        XCTAssertEqual(vm.averageAccuracy, 90) // (80 + 100) / 2 = 90%
        
        // Filter with no matches
        vm.selectedCategory = .testingAndQuality
        XCTAssertEqual(vm.totalGamesCount, 0)
        XCTAssertTrue(vm.displayedRecords.isEmpty)
        XCTAssertEqual(vm.averageAccuracy, 0)
        XCTAssertNil(vm.personalBest)
    }
    
    // MARK: - 9. LeaderboardViewModel Clear History
    
    @MainActor
    func testLeaderboardViewModelClearHistory() {
        let store = InMemoryScoreStore()
        try? store.save(record: ScoreRecord(score: 90, totalQuestions: 10, correctAnswers: 9))
        
        let vm = LeaderboardViewModel(scoreStore: store)
        XCTAssertEqual(vm.totalGamesCount, 1)
        
        vm.clearAllHistory()
        XCTAssertEqual(vm.totalGamesCount, 0)
        XCTAssertTrue(vm.displayedRecords.isEmpty)
        XCTAssertEqual(vm.averageAccuracy, 0)
        XCTAssertNil(vm.personalBest)
    }
    
    // MARK: - 10. LeaderboardView Body Rendering
    
    @MainActor
    func testLeaderboardViewRendersWithoutCrashing() {
        let store = InMemoryScoreStore()
        let vmEmpty = LeaderboardViewModel(scoreStore: store)
        let viewEmpty = LeaderboardView(viewModel: vmEmpty)
        XCTAssertNotNil(viewEmpty.body)
        
        try? store.save(record: ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, category: .swiftAndApple))
        let vmPopulated = LeaderboardViewModel(scoreStore: store)
        let viewPopulated = LeaderboardView(viewModel: vmPopulated)
        XCTAssertNotNil(viewPopulated.body)
    }
    
    // MARK: - 11. ScoreStoreError Descriptions & Protocol Extension
    
    func testScoreStoreErrorDescriptionsAndProtocolExtension() {
        let encError = ScoreStoreError.encodingFailed("test-enc")
        XCTAssertTrue(encError.errorDescription?.contains("test-enc") == true)
        
        let decError = ScoreStoreError.decodingFailed("test-dec")
        XCTAssertTrue(decError.errorDescription?.contains("test-dec") == true)
        
        let persError = ScoreStoreError.persistenceFailed("test-pers")
        XCTAssertTrue(persError.errorDescription?.contains("test-pers") == true)
        
        let corruptError = ScoreStoreError.corruptedDataDiscarded
        XCTAssertNotNil(corruptError.errorDescription)
        
        // Protocol default overload test
        let store = InMemoryScoreStore()
        try? store.save(record: ScoreRecord(score: 50, totalQuestions: 10, correctAnswers: 5))
        XCTAssertEqual(store.loadHighScores().count, 1)
    }
    
    // MARK: - 12. LeaderboardViewModel Tab Properties & History Sorting
    
    @MainActor
    func testLeaderboardViewModelTabPropertiesAndHistorySorting() {
        XCTAssertEqual(LeaderboardViewModel.FilterTab.highScores.iconName, "trophy.fill")
        XCTAssertEqual(LeaderboardViewModel.FilterTab.highScores.id, "High Scores")
        XCTAssertEqual(LeaderboardViewModel.FilterTab.history.iconName, "clock.arrow.circlepath")
        XCTAssertEqual(LeaderboardViewModel.FilterTab.history.id, "Recent Games")
        
        let store = InMemoryScoreStore()
        let olderDate = Date(timeIntervalSince1970: 1000)
        let newerDate = Date(timeIntervalSince1970: 2000)
        
        let olderHighScore = ScoreRecord(score: 150, totalQuestions: 10, correctAnswers: 10, completedAt: olderDate)
        let newerLowerScore = ScoreRecord(score: 50, totalQuestions: 10, correctAnswers: 5, completedAt: newerDate)
        
        try? store.save(record: olderHighScore)
        try? store.save(record: newerLowerScore)
        
        let vm = LeaderboardViewModel(scoreStore: store)
        // High scores tab: 150 first, 50 second
        XCTAssertEqual(vm.displayedRecords.first?.score, 150)
        
        // History tab: newer (50) first, older (150) second
        vm.selectedTab = .history
        XCTAssertEqual(vm.displayedRecords.first?.score, 50)
        XCTAssertEqual(vm.displayedRecords.last?.score, 150)
    }
    
    // MARK: - 13. LeaderboardView Subviews Direct Evaluation
    
    @MainActor
    func testLeaderboardViewSubviewsDirectEvaluation() {
        let store = InMemoryScoreStore()
        let sample = ScoreRecord(score: 100, totalQuestions: 10, correctAnswers: 10, category: .swiftAndApple)
        try? store.save(record: sample)
        
        let vm = LeaderboardViewModel(scoreStore: store)
        let view = LeaderboardView(viewModel: vm)
        
        XCTAssertNotNil(view.summaryStatisticsBar)
        XCTAssertNotNil(view.statTile(title: "Test", value: "100", icon: "star", color: .blue))
        XCTAssertNotNil(view.categoryFilterBar)
        XCTAssertNotNil(view.categoryFilterChip(title: "All", category: nil))
        XCTAssertNotNil(view.categoryFilterChip(title: "Swift", category: .swiftAndApple))
        XCTAssertNotNil(view.emptyStateView)
        XCTAssertNotNil(view.recordsListView)
        XCTAssertNotNil(view.recordCard(index: 0, record: sample))
        XCTAssertNotNil(view.rankBadge(rank: 1))
        XCTAssertNotNil(view.rankBadge(rank: 2))
        XCTAssertNotNil(view.rankBadge(rank: 3))
        XCTAssertNotNil(view.rankBadge(rank: 4))
        XCTAssertNotNil(view.metricColumn(label: "Score", value: "100"))
        XCTAssertNotNil(view.clearHistoryButton)
    }
    
    // MARK: - 14. Personal Best Survives 100+ Subsequent Low-Score Games (US-13)
    
    func testPersonalBestSurvivesHistoryTruncationOver100SubsequentGames() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey,
            maxCapacity: 100
        )
        
        // 1. User scores a massive personal best
        let recordDate = Date(timeIntervalSince1970: 1000)
        let personalBest = ScoreRecord(
            score: 1000,
            totalQuestions: 10,
            correctAnswers: 10,
            streakRecord: 10,
            category: .swiftAndApple,
            completedAt: recordDate
        )
        try store.save(record: personalBest)
        XCTAssertEqual(store.bestScore(for: nil)?.score, 1000)
        XCTAssertEqual(store.bestScore(for: .swiftAndApple)?.score, 1000)
        
        // 2. User subsequently plays 105 quick low-score games (scores 10 to 50)
        for i in 1...105 {
            let subsequentGame = ScoreRecord(
                score: 10,
                totalQuestions: 10,
                correctAnswers: 1,
                streakRecord: 1,
                category: .algorithmsAndDataStructures,
                completedAt: Date(timeIntervalSince1970: TimeInterval(2000 + i))
            )
            try store.save(record: subsequentGame)
        }
        
        // 3. Verify total records capped at maxCapacity, but personal best is strictly preserved
        let loaded = store.loadRecords()
        XCTAssertEqual(loaded.count, 100)
        
        // The personal best must not have been evicted!
        let bestGlobal = store.bestScore(for: nil)
        XCTAssertEqual(bestGlobal?.id, personalBest.id)
        XCTAssertEqual(bestGlobal?.score, 1000)
        
        let bestCategory = store.bestScore(for: .swiftAndApple)
        XCTAssertEqual(bestCategory?.id, personalBest.id)
        XCTAssertEqual(bestCategory?.score, 1000)
    }
    
    // MARK: - 15. Canonical Tie-Breaking Consistency Across Leaderboard and BestScore
    
    @MainActor
    func testCanonicalTieBreakingAcrossLeaderboardAndBestScoreAndPersonalBest() throws {
        let store = UserDefaultsScoreStore(
            userDefaults: testUserDefaults,
            storageKey: testStorageKey
        )
        
        let date = Date(timeIntervalSince1970: 5000)
        // Two games with equal points (100) and equal accuracy (90%), but gameA has higher streak (5 vs 3)
        let gameA = ScoreRecord(
            score: 100,
            totalQuestions: 10,
            correctAnswers: 9,
            streakRecord: 5,
            completedAt: date
        )
        let gameB = ScoreRecord(
            score: 100,
            totalQuestions: 10,
            correctAnswers: 9,
            streakRecord: 3,
            completedAt: date
        )
        
        try store.save(record: gameB)
        try store.save(record: gameA)
        
        // 1. Check UserDefaultsScoreStore.bestScore
        let storeBest = store.bestScore(for: nil)
        XCTAssertEqual(storeBest?.id, gameA.id, "bestScore must choose gameA on streak tie-breaker")
        
        // 2. Check UserDefaultsScoreStore.loadHighScores
        let highScores = store.loadHighScores(limit: 10)
        XCTAssertEqual(highScores.first?.id, gameA.id, "loadHighScores must rank gameA as #1")
        
        // 3. Check LeaderboardViewModel.personalBest & displayedRecords
        let vm = LeaderboardViewModel(scoreStore: store)
        XCTAssertEqual(vm.personalBest?.id, gameA.id, "ViewModel personalBest must match gameA")
        XCTAssertEqual(vm.displayedRecords.first?.id, gameA.id, "Leaderboard #1 card must match gameA")
    }
}

// MARK: - Mock Question Service Helper

private final class MockQuestionService: QuestionServiceProtocol, @unchecked Sendable {
    private let questions: [Question]
    
    init(preloaded: [Question]) {
        self.questions = preloaded
    }
    
    func loadAllQuestions() throws -> [Question] {
        return questions
    }
    
    func loadQuestions(for category: QuizCategory) throws -> [Question] {
        return questions.filter { $0.category == category }
    }
}
