import XCTest
@testable import TrainYourBrainCore

final class LocalQuestionServiceTests: XCTestCase {
    
    func testLoadQuestionsFromValidMockData() throws {
        let jsonString = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111001",
            "prompt": "What does MVC stand for?",
            "options": ["Model View Controller", "Main Virtual Core", "Memory View Cache", "Module Variable Call"],
            "correctAnswerIndex": 0,
            "explanation": "MVC stands for Model-View-Controller.",
            "category": "software_engineering",
            "difficulty": "easy"
          },
          {
            "id": "11111111-1111-1111-1111-111111111002",
            "prompt": "What keyword declares an immutable constant in Swift?",
            "options": ["var", "let", "const", "val"],
            "correctAnswerIndex": 1,
            "explanation": "In Swift, 'let' declares immutable constants.",
            "category": "swift_apple",
            "difficulty": "easy"
          }
        ]
        """
        
        let data = Data(jsonString.utf8)
        let service = LocalQuestionService(mockData: data)
        
        let questions = try service.loadAllQuestions()
        XCTAssertEqual(questions.count, 2)
        XCTAssertEqual(questions[0].prompt, "What does MVC stand for?")
        XCTAssertEqual(questions[1].prompt, "What keyword declares an immutable constant in Swift?")
        
        let swiftQuestions = try service.loadQuestions(for: .swiftAndApple)
        XCTAssertEqual(swiftQuestions.count, 1)
        XCTAssertEqual(swiftQuestions[0].category, .swiftAndApple)
    }
    
    func testLoadQuestionsThrowsOnMalformedJSON() {
        let malformedJson = "{ not a valid json }"
        let service = LocalQuestionService(mockData: Data(malformedJson.utf8))
        
        XCTAssertThrowsError(try service.loadAllQuestions()) { error in
            guard case QuestionServiceError.decodingFailed = error else {
                XCTFail("Expected decodingFailed error, got \(error)")
                return
            }
        }
    }
    
    func testLoadQuestionsThrowsOnEmptyArray() {
        let emptyJson = "[]"
        let service = LocalQuestionService(mockData: Data(emptyJson.utf8))
        
        XCTAssertThrowsError(try service.loadAllQuestions()) { error in
            guard case QuestionServiceError.emptyQuestionSet = error else {
                XCTFail("Expected emptyQuestionSet error, got \(error)")
                return
            }
        }
    }
    
    func testLoadQuestionsThrowsWhenCategoryHasNoMatches() throws {
        let jsonString = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111001",
            "prompt": "Sample Question",
            "options": ["A", "B", "C", "D"],
            "correctAnswerIndex": 0,
            "explanation": "Explanation",
            "category": "software_engineering",
            "difficulty": "easy"
          }
        ]
        """
        let service = LocalQuestionService(mockData: Data(jsonString.utf8))
        
        XCTAssertThrowsError(try service.loadQuestions(for: .testingAndQuality)) { error in
            guard case QuestionServiceError.emptyQuestionSet = error else {
                XCTFail("Expected emptyQuestionSet error, got \(error)")
                return
            }
        }
    }
}
