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
}
