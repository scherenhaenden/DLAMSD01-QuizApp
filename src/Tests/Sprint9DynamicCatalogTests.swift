import XCTest
import Combine
import SwiftUI
@testable import TrainYourBrainCore

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

final class TestScoreStore: ScoreStoreProtocol, @unchecked Sendable {
    private var records: [ScoreRecord] = []
    
    func save(record: ScoreRecord) throws {
        records.append(record)
    }
    
    func loadRecords() -> [ScoreRecord] {
        records.sorted { $0.completedAt > $1.completedAt }
    }
    
    func loadHighScores(limit: Int) -> [ScoreRecord] {
        let sorted = records.sorted { $0.score > $1.score }
        return Array(sorted.prefix(limit))
    }
    
    func bestScore(for category: QuizCategory?) -> ScoreRecord? {
        records.filter { category == nil || $0.category?.rawValue == category?.rawValue }.max { $0.score < $1.score }
    }
    
    func clearAll() throws {
        records.removeAll()
    }
}

@MainActor
final class Sprint9DynamicCatalogTests: XCTestCase {
    private var tempDirectoryURL: URL!
    private var testCatalogURL: URL!
    
    override func setUp() {
        super.setUp()
        CategoryRegistry.shared.resetToDefaults()
        tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        testCatalogURL = tempDirectoryURL.appendingPathComponent("test_custom_catalog.json")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        CategoryRegistry.shared.resetToDefaults()
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    // MARK: - Helper Mock Bundle Provider
    
    private func makeSeedQuestions() -> [Question] {
        [
            try! Question(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                prompt: "Bundled System Question 1",
                options: ["Option A", "Option B", "Option C", "Option D"],
                correctAnswerIndex: 0,
                explanation: "Explanation 1",
                category: .softwareEngineering,
                difficulty: .easy
            )
        ]
    }
    
    private func makeServiceWithSeed() -> LocalQuestionService {
        let seed = makeSeedQuestions()
        let encoder = JSONEncoder()
        let seedData = try! encoder.encode(seed)
        return LocalQuestionService(mockData: seedData, customCatalogURL: testCatalogURL)
    }
    
    private func makeMockURLSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    // MARK: - Test 1: Category Extensibility & Registry
    
    func testCustomCategoryCreationAndRegistry() {
        XCTAssertEqual(QuizCategory.allCases.count, 4)
        
        let cloudCat = QuizCategory(
            id: "cloud_computing",
            displayName: "Cloud Computing",
            iconName: "server.rack",
            description: "Distributed architectures, microservices, and serverless compute."
        )
        
        XCTAssertTrue(cloudCat.isCustom)
        XCTAssertEqual(cloudCat.rawValue, "cloud_computing")
        XCTAssertEqual(cloudCat.displayName, "Cloud Computing")
        XCTAssertEqual(cloudCat.iconName, "server.rack")
        XCTAssertEqual(cloudCat.localizedDescription, "Distributed architectures, microservices, and serverless compute.")
        
        CategoryRegistry.shared.register(cloudCat)
        
        XCTAssertEqual(QuizCategory.allCases.count, 5)
        XCTAssertTrue(QuizCategory.allCases.contains(where: { $0.rawValue == "cloud_computing" }))
        
        // Retrieval by raw value preserves metadata
        let retrieved = QuizCategory(rawValue: "cloud_computing")
        XCTAssertEqual(retrieved.displayName, "Cloud Computing")
        XCTAssertEqual(retrieved.iconName, "server.rack")
        XCTAssertTrue(retrieved.isCustom)
        
        // Custom category fallback names
        let rawOnlyCat = QuizCategory(rawValue: "custom_subject_name")
        XCTAssertEqual(rawOnlyCat.displayName, "Custom Subject Name")
        XCTAssertEqual(rawOnlyCat.iconName, "folder.fill")
        XCTAssertEqual(rawOnlyCat.localizedDescription, "User-defined study subject and question bank.")
    }
    
    // MARK: - Test 2: In-App Question Authoring & Invariants
    
    func testInAppQuestionAuthoringAndInvariants() throws {
        let service = makeServiceWithSeed()
        let scoreStore = TestScoreStore()
        let vm = QuizViewModel(questionService: service, scoreStore: scoreStore)
        vm.loadQuestionCatalog()
        
        let customCat = QuizCategory(
            id: "cybersecurity",
            displayName: "Cybersecurity",
            iconName: "lock.shield",
            description: "Information security and cryptography."
        )
        try vm.addCustomCategory(name: "Cybersecurity", iconName: "lock.shield", description: "Information security and cryptography.")
        
        // Valid custom question addition
        try vm.addCustomQuestion(
            prompt: "What is the primary objective of public-key cryptography?",
            options: ["Asymmetric key pairs", "Faster hashing", "Lossless compression", "Garbage collection"],
            correctAnswerIndex: 0,
            explanation: "Asymmetric cryptography utilizes public/private key pairs for secure exchange.",
            category: customCat,
            difficulty: .hard
        )
        
        XCTAssertEqual(vm.questionCount(for: customCat), 1)
        XCTAssertEqual(vm.customQuestions.count, 1)
        XCTAssertEqual(vm.customQuestions.first?.prompt, "What is the primary objective of public-key cryptography?")
        
        // Invariant: empty prompt must fail
        XCTAssertThrowsError(
            try vm.addCustomQuestion(
                prompt: "   ",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 0,
                explanation: "Expl",
                category: customCat
            )
        )
        
        // Invariant: fewer than 4 options must fail
        XCTAssertThrowsError(
            try vm.addCustomQuestion(
                prompt: "Valid prompt?",
                options: ["A", "B"],
                correctAnswerIndex: 0,
                explanation: "Expl",
                category: customCat
            )
        )
        
        // Invariant: duplicate options must fail
        XCTAssertThrowsError(
            try vm.addCustomQuestion(
                prompt: "Valid prompt?",
                options: ["A", "A", "C", "D"],
                correctAnswerIndex: 0,
                explanation: "Expl",
                category: customCat
            )
        )
        
        // Invariant: out-of-range correct index must fail
        XCTAssertThrowsError(
            try vm.addCustomQuestion(
                prompt: "Valid prompt?",
                options: ["A", "B", "C", "D"],
                correctAnswerIndex: 4,
                explanation: "Expl",
                category: customCat
            )
        )
        
        // Invariant: empty category name throws
        XCTAssertThrowsError(try vm.addCustomCategory(name: "   "))
    }
    
    // MARK: - Test 3: Sandbox Persistence Across Restarts & Cascade Deletions
    
    func testCustomStudyMaterialCRUDAndPersistence() throws {
        let customCat = QuizCategory(
            id: "ios_arch",
            displayName: "iOS Architecture",
            iconName: "iphone",
            description: "Clean Architecture, VIPER, and MVVM."
        )
        
        let qId = UUID()
        let question = try Question(
            id: qId,
            prompt: "What layer contains business use cases in Clean Architecture?",
            options: ["Domain Layer", "Presentation Layer", "Data Layer", "Device Driver"],
            correctAnswerIndex: 0,
            explanation: "The domain layer encapsulates business rules and use cases.",
            category: customCat,
            difficulty: .medium
        )
        
        // Phase 1: Create & Persist
        do {
            let service1 = makeServiceWithSeed()
            try service1.addCategory(customCat)
            try service1.addQuestion(question)
            
            let allQ = try service1.loadAllQuestions()
            XCTAssertEqual(allQ.count, 2) // 1 bundled + 1 custom
            XCTAssertTrue(FileManager.default.fileExists(atPath: testCatalogURL.path))
        }
        
        // Reset registry to simulate fresh app launch
        CategoryRegistry.shared.resetToDefaults()
        XCTAssertEqual(QuizCategory.allCases.count, 4)
        
        // Phase 2: Relaunch from Disk
        do {
            let service2 = makeServiceWithSeed()
            let allQ = try service2.loadAllQuestions()
            XCTAssertEqual(allQ.count, 2)
            
            // Custom category must have been auto-registered upon loading payload
            XCTAssertEqual(QuizCategory.allCases.count, 5)
            let loadedCat = QuizCategory(rawValue: "ios_arch")
            XCTAssertEqual(loadedCat.displayName, "iOS Architecture")
            
            // Phase 3: Edit Custom Question
            let updatedQuestion = try Question(
                id: qId,
                prompt: "What layer contains core business use cases in Clean Architecture? (Updated)",
                options: ["Domain Layer", "Presentation Layer", "Data Layer", "Device Driver"],
                correctAnswerIndex: 0,
                explanation: "Updated explanation.",
                category: customCat,
                difficulty: .hard
            )
            try service2.updateQuestion(updatedQuestion)
            
            let questionsAfterUpdate = try service2.loadQuestions(for: customCat)
            XCTAssertEqual(questionsAfterUpdate.first?.prompt, "What layer contains core business use cases in Clean Architecture? (Updated)")
            
            // Phase 4: Prohibit Deletion of System Curriculum
            XCTAssertThrowsError(try service2.deleteCategory(id: QuizCategory.softwareEngineering.rawValue))
            let bundledId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            XCTAssertThrowsError(try service2.deleteQuestion(id: bundledId))
            
            // Phase 5: Delete Category with Cascade Question Deletion
            try service2.deleteCategory(id: "ios_arch")
            XCTAssertEqual(QuizCategory.allCases.count, 4)
            XCTAssertThrowsError(try service2.loadQuestions(for: customCat))
            XCTAssertEqual(try service2.loadAllQuestions().count, 1) // Only seed remains
        }
    }
    
    // MARK: - Test 4: Transactional Import & Dry-Run Rollback
    
    func testTransactionalImportPayloadAndDryRunRollback() throws {
        let service = makeServiceWithSeed()
        let vm = QuizViewModel(questionService: service, scoreStore: TestScoreStore())
        vm.loadQuestionCatalog()
        
        let validPayloadJSON = """
        {
            "categories": [
                {
                    "id": "artificial_intelligence",
                    "displayName": "Artificial Intelligence",
                    "iconName": "atom",
                    "description": "Deep learning, transformers, and heuristic search."
                }
            ],
            "questions": [
                {
                    "id": "22222222-2222-2222-2222-222222222222",
                    "prompt": "What attention mechanism is used in Transformer architectures?",
                    "options": ["Scaled Dot-Product", "Linear Regression", "Bubble Sort", "Round Robin"],
                    "correctAnswerIndex": 0,
                    "explanation": "Transformers utilize Scaled Dot-Product Multi-Head Attention.",
                    "category": "artificial_intelligence",
                    "difficulty": "hard"
                }
            ]
        }
        """
        
        let validData = validPayloadJSON.data(using: .utf8)!
        let result = try vm.importStudyMaterial(from: validData)
        XCTAssertEqual(result.categoriesCount, 1)
        XCTAssertEqual(result.questionsCount, 1)
        
        let aiCat = QuizCategory(rawValue: "artificial_intelligence")
        XCTAssertEqual(vm.questionCount(for: aiCat), 1)
        
        // Also test array-only question import
        let arrayQuestionsJSON = """
        [
            {
                "id": "44444444-4444-4444-4444-444444444444",
                "prompt": "What is an epoch in deep learning?",
                "options": ["One complete pass over training data", "A learning rate scheduler", "A loss function", "A hardware accelerator"],
                "correctAnswerIndex": 0,
                "explanation": "An epoch represents one complete cycle through the entire training dataset.",
                "category": "deep_learning_concepts",
                "difficulty": "easy"
            }
        ]
        """
        let arrayData = arrayQuestionsJSON.data(using: .utf8)!
        let arrayResult = try vm.importStudyMaterial(from: arrayData)
        XCTAssertEqual(arrayResult.questionsCount, 1)
        XCTAssertTrue(QuizCategory.allCases.contains(where: { $0.rawValue == "deep_learning_concepts" }))
        
        // Malformed Import with Dry-Run Rejection (Corrupted option count)
        let malformedPayloadJSON = """
        {
            "categories": [
                {
                    "id": "corrupt_subject",
                    "displayName": "Corrupt Subject",
                    "iconName": "xmark",
                    "description": "Invalid payload"
                }
            ],
            "questions": [
                {
                    "id": "33333333-3333-3333-3333-333333333333",
                    "prompt": "Corrupt question with only 2 choices?",
                    "options": ["A", "B"],
                    "correctAnswerIndex": 0,
                    "explanation": "Should fail invariants.",
                    "category": "corrupt_subject",
                    "difficulty": "medium"
                }
            ]
        }
        """
        
        let malformedData = malformedPayloadJSON.data(using: .utf8)!
        XCTAssertThrowsError(try vm.importStudyMaterial(from: malformedData))
        
        // Verify state is completely uncorrupted (neither category nor question was committed)
        XCTAssertFalse(QuizCategory.allCases.contains(where: { $0.rawValue == "corrupt_subject" }))
        XCTAssertEqual(vm.questionCount(for: aiCat), 1)
    }
    
    // MARK: - Test 5: Network Remote Importer & Mock Session
    
    func testNetworkCatalogImporter() async throws {
        let mockSession = makeMockURLSession()
        let importer = NetworkCatalogImporter(session: mockSession)
        
        // Case 1: Invalid URL scheme
        let invalidURL = URL(string: "ftp://files.example.com/quiz.json")!
        do {
            _ = try await importer.fetchCatalogData(from: invalidURL)
            XCTFail("Expected invalidURL error")
        } catch let error as NetworkCatalogError {
            XCTAssertEqual(error, NetworkCatalogError.invalidURL)
        }
        
        // Case 2: HTTP 200 Success
        let validURL = URL(string: "https://example.com/catalog.json")!
        let expectedJSON = "{\"categories\":[], \"questions\":[]}"
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedJSON.data(using: .utf8)!)
        }
        
        let downloadedData = try await importer.fetchCatalogData(from: validURL)
        XCTAssertEqual(downloadedData, expectedJSON.data(using: .utf8))
        
        // Case 3: HTTP 404 Error
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        do {
            _ = try await importer.fetchCatalogData(from: validURL)
            XCTFail("Expected invalidHTTPResponse error")
        } catch let error as NetworkCatalogError {
            XCTAssertEqual(error, NetworkCatalogError.invalidHTTPResponse(statusCode: 404))
        }
        
        // Case 4: Empty Response Body
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        do {
            _ = try await importer.fetchCatalogData(from: validURL)
            XCTFail("Expected emptyResponse error")
        } catch let error as NetworkCatalogError {
            XCTAssertEqual(error, NetworkCatalogError.emptyResponse)
        }
    }
    
    // MARK: - Test 6: End-to-End Gameplay with Custom Study Material
    
    func testEndToEndGameplayWithCustomStudyMaterial() throws {
        let service = makeServiceWithSeed()
        let scoreStore = TestScoreStore()
        let vm = QuizViewModel(questionService: service, scoreStore: scoreStore)
        vm.loadQuestionCatalog()
        
        let customCat = QuizCategory(
            id: "quantum_computing",
            displayName: "Quantum Computing",
            iconName: "atom",
            description: "Qubits, superposition, and quantum gates."
        )
        try vm.addCustomCategory(name: "Quantum Computing", iconName: "atom", description: "Qubits and quantum gates.")
        
        // Add 2 custom questions
        try vm.addCustomQuestion(
            prompt: "What is the fundamental unit of quantum information?",
            options: ["Qubit", "Classical Bit", "Byte", "Trit"],
            correctAnswerIndex: 0,
            explanation: "A qubit can exist in a superposition of states |0⟩ and |1⟩.",
            category: customCat,
            difficulty: .medium
        )
        try vm.addCustomQuestion(
            prompt: "Which quantum gate creates an equal superposition from |0⟩?",
            options: ["Hadamard Gate", "Pauli-X Gate", "CNOT Gate", "Phase Gate"],
            correctAnswerIndex: 0,
            explanation: "The Hadamard gate maps basis states into superposition states.",
            category: customCat,
            difficulty: .hard
        )
        
        XCTAssertEqual(vm.questionCount(for: customCat), 2)
        
        // Start quiz filtered specifically by the custom category
        vm.startQuiz(category: customCat)
        XCTAssertEqual(vm.viewState, QuizViewModel.ViewState.playing)
        XCTAssertEqual(vm.totalQuestions, 2)
        
        // Answer Question 1 correctly
        let q1 = vm.currentQuestion!
        XCTAssertEqual(q1.category.rawValue, "quantum_computing")
        vm.selectAnswer(at: q1.correctAnswerIndex)
        XCTAssertEqual(vm.viewState, QuizViewModel.ViewState.answered(selectedIndex: q1.correctAnswerIndex, isCorrect: true))
        vm.nextQuestion()
        
        // Answer Question 2 correctly
        let q2 = vm.currentQuestion!
        XCTAssertEqual(q2.category.rawValue, "quantum_computing")
        vm.selectAnswer(at: q2.correctAnswerIndex)
        XCTAssertEqual(vm.viewState, QuizViewModel.ViewState.answered(selectedIndex: q2.correctAnswerIndex, isCorrect: true))
        vm.nextQuestion()
        
        // Verify quiz concluded with German Academic Grade 1.0 (Sehr Gut)
        guard case .finished(let record) = vm.viewState else {
            XCTFail("Expected quiz to be in .finished state")
            return
        }
        
        XCTAssertEqual(record.correctAnswers, 2)
        XCTAssertEqual(record.totalQuestions, 2)
        XCTAssertEqual(record.accuracyPercentage, 100)
        XCTAssertEqual(record.germanGrade.numericValue, 1.0)
        XCTAssertEqual(record.germanGrade.title, "Sehr Gut")
        XCTAssertEqual(record.category?.rawValue, "quantum_computing")
        XCTAssertEqual(record.categoryBreakdown.first?.categoryId, "quantum_computing")
        XCTAssertEqual(record.categoryBreakdown.first?.categoryTitle, "Quantum Computing")
        XCTAssertEqual(record.categoryBreakdown.first?.correctCount, 2)
        
        // Verify Leaderboard tracking for custom category
        let leaderboardVM = LeaderboardViewModel(scoreStore: scoreStore)
        leaderboardVM.selectedCategory = customCat
        XCTAssertEqual(leaderboardVM.displayedRecords.count, 1)
        XCTAssertEqual(leaderboardVM.displayedRecords.first?.score, Optional(record.score))
    }
    
    // MARK: - Test 7: Custom Models Codable & Roundtrip
    
    func testCustomCatalogModelsCodable() throws {
        let record = CustomCategoryRecord(id: "devops", displayName: "DevOps", iconName: "gear", description: "CI/CD and GitOps")
        let cat = record.toQuizCategory
        XCTAssertEqual(cat.rawValue, "devops")
        XCTAssertEqual(cat.displayName, "DevOps")
        
        let payload = CustomCatalogPayload(categories: [record], questions: makeSeedQuestions())
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CustomCatalogPayload.self, from: data)
        XCTAssertEqual(decoded.categories.count, 1)
        XCTAssertEqual(decoded.questions.count, 1)
        XCTAssertEqual(decoded.categories.first?.id, "devops")
    }
    
    // MARK: - Test 8: Save Failure Full Transactional Rollback
    
    func testSaveFailureRollsBackInMemoryStateAndRegistry() throws {
        // Point service to a write-forbidden path to guarantee persistCustomPayload throws
        let invalidCatalogURL = URL(fileURLWithPath: "/dev/null/forbidden/directory/custom_catalog.json")
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: invalidCatalogURL
        )
        
        let customCat = QuizCategory(
            id: "failing_save_cat",
            displayName: "Failing Save Category",
            iconName: "xmark.circle",
            description: "Should roll back completely",
            isCustom: true
        )
        
        XCTAssertThrowsError(try service.addCategory(customCat)) { error in
            guard case QuestionServiceError.customCatalogSaveFailed = error else {
                XCTFail("Expected customCatalogSaveFailed but got \(error)")
                return
            }
        }
        
        // Assert in-memory registry contains NO trace of the rejected category
        XCTAssertNil(CategoryRegistry.shared.category(for: "failing_save_cat"))
        XCTAssertFalse(QuizCategory.allCases.contains(where: { $0.rawValue == "failing_save_cat" }))
        XCTAssertEqual(try service.loadCustomQuestions().count, 0)
    }
    
    // MARK: - Test 9: Category Metadata Preserved Across Service Relaunch
    
    func testCategoryMetadataPreservedAcrossServiceRelaunch() throws {
        let initialService = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        
        let customCat = QuizCategory(
            id: "cloud",
            displayName: "Cloud / Redes",
            iconName: "cloud.sun.fill",
            description: "AWS and GCP Cloud Infrastructure",
            isCustom: true
        )
        try initialService.addCategory(customCat)
        
        let question = try Question(
            id: UUID(),
            prompt: "What is an S3 bucket?",
            options: ["Object store", "Relational DB", "Block storage", "Queue"],
            correctAnswerIndex: 0,
            explanation: "S3 provides managed object storage.",
            category: customCat,
            difficulty: .medium
        )
        try initialService.addQuestion(question)
        
        // Simulate app restart: reset registry and construct a completely new service instance
        CategoryRegistry.shared.resetToDefaults()
        let restartedService = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        
        let loadedQuestions = try restartedService.loadCustomQuestions()
        XCTAssertEqual(loadedQuestions.count, 1)
        
        let loadedQuestion = loadedQuestions.first!
        XCTAssertEqual(loadedQuestion.category.rawValue, "cloud")
        XCTAssertEqual(loadedQuestion.category.displayName, "Cloud / Redes", "Display name must be preserved exactly without capitalized fallback")
        XCTAssertEqual(loadedQuestion.category.iconName, "cloud.sun.fill", "Icon name must be preserved exactly")
        
        // Test QuizSession categoryBreakdown retains correct custom title
        var session = QuizSession(questions: [loadedQuestion], category: loadedQuestion.category)
        session.start()
        session.submitAnswer(optionIndex: 0)
        
        let breakdown = session.categoryBreakdown
        XCTAssertEqual(breakdown.count, 1)
        XCTAssertEqual(breakdown.first?.categoryId, "cloud")
        XCTAssertEqual(breakdown.first?.categoryTitle, "Cloud / Redes")
    }
    
    // MARK: - Test 10: Unreadable Corrupted Catalog Creates Emergency Backup
    
    func testUnreadableCorruptedCatalogGeneratesEmergencyBackup() throws {
        // Write corrupted non-JSON data into the catalog file
        let corruptedData = "INVALID_CORRUPT_NOT_A_JSON_PAYLOAD_<<<>>>".data(using: .utf8)!
        try corruptedData.write(to: testCatalogURL)
        
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        
        let customQuestions = try service.loadCustomQuestions()
        XCTAssertEqual(customQuestions.count, 0)
        XCTAssertNotNil(service.lastLoadWarning)
        
        // Verify emergency backup file was created and verified
        let dirContents = try FileManager.default.contentsOfDirectory(atPath: tempDirectoryURL.path)
        let backupFiles = dirContents.filter { $0.contains("corrupted") && $0.hasSuffix(".bak") }
        XCTAssertEqual(backupFiles.count, 1, "An emergency backup file must be created to prevent data loss")
        let backupURL = tempDirectoryURL.appendingPathComponent(backupFiles[0])
        let backupBytes = try Data(contentsOf: backupURL)
        XCTAssertEqual(backupBytes, corruptedData, "Backup file content must match corrupted original byte-by-byte")
        XCTAssertFalse(service.isCatalogSaveBlockedToPreventDataLoss, "Save should not be blocked when backup succeeded and was verified")
    }
    
    // MARK: - Test 11: Category Update CRUD Operation
    
    func testCategoryUpdateAndCRUDOperations() throws {
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        let vm = QuizViewModel(questionService: service, scoreStore: TestScoreStore())
        
        try vm.addCustomCategory(name: "DevOps", iconName: "gear", description: "CI/CD basics")
        let catId = "devops"
        
        try vm.addCustomQuestion(
            prompt: "What is CI?",
            options: ["Continuous Integration", "Compute Instance", "Cloud Index", "Code Input"],
            correctAnswerIndex: 0,
            explanation: "Automated test integration.",
            category: QuizCategory(rawValue: catId),
            difficulty: .easy
        )
        
        // Perform Update
        try vm.updateCustomCategory(
            id: catId,
            displayName: "Platform Engineering & SRE",
            iconName: "server.rack",
            description: "Advanced reliability engineering"
        )
        
        let updatedCat = CategoryRegistry.shared.category(for: catId)
        XCTAssertNotNil(updatedCat)
        XCTAssertEqual(updatedCat?.displayName, "Platform Engineering & SRE")
        XCTAssertEqual(updatedCat?.iconName, "server.rack")
        
        // Verify in-memory question also updated its category title
        let questions = vm.customQuestions
        XCTAssertEqual(questions.first?.category.displayName, "Platform Engineering & SRE")
    }
    
    // MARK: - Test 12: Duplicate Category IDs Do Not Crash Process
    
    func testDuplicateCategoryIDsInImportDoesNotCrash() throws {
        // Reproduce exact Codex audit scenario: JSON with duplicate category IDs
        let duplicateCategoryJSON = """
        {
            "categories": [
                {
                    "id": "same",
                    "displayName": "Initial Category",
                    "iconName": "folder.fill",
                    "description": "First instance"
                },
                {
                    "id": "same",
                    "displayName": "Overridden Category",
                    "iconName": "book.fill",
                    "description": "Duplicate instance"
                }
            ],
            "questions": [
                {
                    "id": "11111111-1111-1111-1111-111111111111",
                    "prompt": "Test Prompt for duplicate category check",
                    "options": ["A", "B", "C", "D"],
                    "correctAnswerIndex": 0,
                    "explanation": "Valid explanation.",
                    "category": "same",
                    "difficulty": "medium"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        // Must decode without throwing Fatal error: Duplicate values for key
        let payload = try decoder.decode(CustomCatalogPayload.self, from: duplicateCategoryJSON)
        XCTAssertEqual(payload.categories.count, 1, "Duplicate category IDs must be deduplicated")
        XCTAssertEqual(payload.questions.count, 1)
        XCTAssertEqual(payload.questions.first?.category.rawValue, "same")
        
        // Also test importing via LocalQuestionService
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        let result = try service.importCatalog(from: duplicateCategoryJSON)
        XCTAssertEqual(result.categoriesCount, 1)
        XCTAssertEqual(result.questionsCount, 1)
        
        let loaded = try service.loadCustomQuestions()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.category.rawValue, "same")
    }
    
    // MARK: - Test 13: Corrupted Catalog With Failed Backup Blocks Save Operation
    
    func testCorruptedCatalogWithFailedBackupBlocksSaveOperation() throws {
        // Place corrupted data
        let corruptedData = "NOT_A_VALID_JSON_CORRUPTED_PAYLOAD".data(using: .utf8)!
        try corruptedData.write(to: testCatalogURL)
        
        // Guarantee backup failure by making the parent directory read-only (0o555).
        // This causes copyItem to throw Permission Denied (EACCES) deterministically.
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: tempDirectoryURL.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: tempDirectoryURL.path)
        }
        
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(makeSeedQuestions()),
            customCatalogURL: testCatalogURL
        )
        
        _ = try service.loadCustomQuestions()
        
        // Mandatory non-conditional assertions:
        XCTAssertTrue(service.isCatalogSaveBlockedToPreventDataLoss, "Service must unconditionally activate isCatalogSaveBlockedToPreventDataLoss when backup creation fails")
        XCTAssertTrue(service.lastLoadWarning?.contains("CRITICAL") ?? false, "Warning must include CRITICAL diagnostic message")
        
        // Any attempt to write must fail and protect the original corrupted file
        XCTAssertThrowsError(try service.addCategory(QuizCategory(rawValue: "new_cat"))) { error in
            guard case QuestionServiceError.customCatalogSaveFailed(let msg) = error else {
                XCTFail("Expected customCatalogSaveFailed error, got: \(error)")
                return
            }
            XCTAssertTrue(msg.contains("blocked"), "Must indicate write operation was blocked")
        }
        
        // Confirm the original corrupted file content was NOT overwritten
        let existingData = try Data(contentsOf: testCatalogURL)
        XCTAssertEqual(existingData, corruptedData, "Corrupted file must be preserved intact")
    }
    
    // MARK: - Test 14: Collision with Bundled Question UUID Reassigns New ID and Preserves Manageability
    
    func testImportQuestionCollidingWithBundledQuestionAssignsNewUUIDAndRemainsManageable() throws {
        let seed = makeSeedQuestions()
        guard let collidingBundledQuestion = seed.first else {
            XCTFail("Seed questions must not be empty")
            return
        }
        let collidingId = collidingBundledQuestion.id
        
        let service = LocalQuestionService(
            mockData: try! JSONEncoder().encode(seed),
            customCatalogURL: testCatalogURL
        )
        
        // 1. Verify direct addQuestion with colliding bundled UUID is strictly rejected
        let directQuestion = try Question(
            id: collidingId,
            prompt: "Direct add colliding prompt",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 0,
            explanation: "Direct add test.",
            category: QuizCategory(rawValue: "custom_subject"),
            difficulty: .easy
        )
        XCTAssertThrowsError(try service.addQuestion(directQuestion)) { error in
            guard case QuestionServiceError.systemQuestionDeletionNotAllowed = error else {
                XCTFail("Expected systemQuestionDeletionNotAllowed on direct add collision, got: \(error)")
                return
            }
        }
        
        // 2. Prepare imported payload where an imported question has the exact same UUID as the bundled question
        let importedCollidingJSON = """
        {
            "categories": [
                {
                    "id": "quantum_physics",
                    "displayName": "Quantum Physics",
                    "iconName": "atom",
                    "description": "Subatomic particles"
                }
            ],
            "questions": [
                {
                    "id": "\(collidingId.uuidString)",
                    "prompt": "What is quantum superposition?",
                    "options": ["A state of multiple possibilities", "Only zero", "Only one", "Gravity"],
                    "correctAnswerIndex": 0,
                    "explanation": "Linear combination of quantum states.",
                    "category": "quantum_physics",
                    "difficulty": "hard"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importResult = try service.importCatalog(from: importedCollidingJSON)
        XCTAssertEqual(importResult.categoriesCount, 1)
        XCTAssertEqual(importResult.questionsCount, 1)
        
        // 3. Verify custom questions loaded: exactly 1 question, but with a FRESH unique UUID
        let customQuestions = try service.loadCustomQuestions()
        XCTAssertEqual(customQuestions.count, 1)
        guard let importedCustom = customQuestions.first else {
            XCTFail("Imported question must be present")
            return
        }
        XCTAssertNotEqual(importedCustom.id, collidingId, "Imported custom question must be assigned a new unique UUID to prevent collision")
        XCTAssertEqual(importedCustom.prompt, "What is quantum superposition?")
        
        // 4. Verify combined catalog has 100% unique IDs across all items
        let allQuestions = try service.loadAllQuestions()
        let uniqueAllIDs = Set(allQuestions.map { $0.id })
        XCTAssertEqual(allQuestions.count, uniqueAllIDs.count, "Combined questions must have zero duplicate IDs")
        XCTAssertEqual(allQuestions.count, seed.count + 1)
        
        // 5. Verify the imported custom question can be edited and deleted normally without hitting system protection
        let updatedQuestion = try Question(
            id: importedCustom.id,
            prompt: "What is quantum entanglement?",
            options: ["Spooky action at a distance", "Classical spin", "Static charge", "Thermal noise"],
            correctAnswerIndex: 0,
            explanation: "Entangled particles share states.",
            category: importedCustom.category,
            difficulty: .hard
        )
        XCTAssertNoThrow(try service.updateQuestion(updatedQuestion), "Custom question with reassigned ID must be editable")
        
        XCTAssertNoThrow(try service.deleteQuestion(id: importedCustom.id), "Custom question with reassigned ID must be deletable")
        let finalCustom = try service.loadCustomQuestions()
        XCTAssertEqual(finalCustom.count, 0, "Custom question should be deleted")
        
        // 6. Verify bundled question remains completely unharmed
        let finalAll = try service.loadAllQuestions()
        XCTAssertEqual(finalAll.count, seed.count, "Bundled questions must remain intact")
        XCTAssertTrue(finalAll.contains(where: { $0.id == collidingId }))
    }
}
