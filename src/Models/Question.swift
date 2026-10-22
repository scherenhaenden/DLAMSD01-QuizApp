import Foundation

/// Core domain entity representing a single multiple-choice question.
/// Fulfills IU requirements: prompt, 4 choices, single valid answer index, and pedagogical rationale.
public struct Question: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let prompt: String
    public let options: [String]
    public let correctAnswerIndex: Int
    public let explanation: String
    public let category: QuizCategory
    public let difficulty: Difficulty
    
    public enum ValidationError: LocalizedError, Equatable {
        case emptyPrompt
        case insufficientOptions(count: Int)
        case invalidCorrectIndex(index: Int, optionsCount: Int)
        case duplicateOptions
        case emptyExplanation
        
        public var errorDescription: String? {
            switch self {
            case .emptyPrompt:
                return "The question prompt cannot be empty."
            case .insufficientOptions(let count):
                return "A question must provide at least 2 options (expected 4, found \(count))."
            case .invalidCorrectIndex(let index, let optionsCount):
                return "Correct answer index \(index) is out of range for \(optionsCount) options."
            case .duplicateOptions:
                return "Question options must be unique to prevent ambiguity."
            case .emptyExplanation:
                return "A pedagogical explanation is required for feedback."
            }
        }
    }
    
    public init(
        id: UUID = UUID(),
        prompt: String,
        options: [String],
        correctAnswerIndex: Int,
        explanation: String,
        category: QuizCategory,
        difficulty: Difficulty = .medium
    ) throws {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw ValidationError.emptyPrompt
        }
        
        guard options.count >= 2 else {
            throw ValidationError.insufficientOptions(count: options.count)
        }
        
        guard correctAnswerIndex >= 0 && correctAnswerIndex < options.count else {
            throw ValidationError.invalidCorrectIndex(index: correctAnswerIndex, optionsCount: options.count)
        }
        
        let uniqueOptions = Set(options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        guard uniqueOptions.count == options.count else {
            throw ValidationError.duplicateOptions
        }
        
        let trimmedExplanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedExplanation.isEmpty else {
            throw ValidationError.emptyExplanation
        }
        
        self.id = id
        self.prompt = trimmedPrompt
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = trimmedExplanation
        self.category = category
        self.difficulty = difficulty
    }
    
    // MARK: - Codable Custom Decoding for Robustness
    
    private enum CodingKeys: String, CodingKey {
        case id
        case prompt
        case options
        case correctAnswerIndex
        case explanation
        case category
        case difficulty
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let prompt = try container.decode(String.self, forKey: .prompt)
        let options = try container.decode([String].self, forKey: .options)
        let correctAnswerIndex = try container.decode(Int.self, forKey: .correctAnswerIndex)
        let explanation = try container.decode(String.self, forKey: .explanation)
        let category = try container.decode(QuizCategory.self, forKey: .category)
        let difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .medium
        
        try self.init(
            id: decodedId,
            prompt: prompt,
            options: options,
            correctAnswerIndex: correctAnswerIndex,
            explanation: explanation,
            category: category,
            difficulty: difficulty
        )
    }
    
    // MARK: - Domain Logic
    
    /// Evaluates if a given selected index corresponds to the correct answer.
    public func isCorrect(selectedOptionIndex: Int) -> Bool {
        return selectedOptionIndex == correctAnswerIndex
    }
    
    /// Text of the correct answer.
    public var correctAnswerText: String {
        return options[correctAnswerIndex]
    }
    
    /// Returns a shuffled version of the question choices, recalculating the correct answer index
    /// to preserve domain consistency while preventing memorization of option positions.
    public func shuffledOptions<T: RandomNumberGenerator>(using generator: inout T) -> Question {
        let correctOptionText = self.options[self.correctAnswerIndex]
        let shuffled = self.options.shuffled(using: &generator)
        guard let newCorrectIndex = shuffled.firstIndex(of: correctOptionText) else {
            return self
        }
        
        do {
            return try Question(
                id: self.id,
                prompt: self.prompt,
                options: shuffled,
                correctAnswerIndex: newCorrectIndex,
                explanation: self.explanation,
                category: self.category,
                difficulty: self.difficulty
            )
        } catch {
            return self
        }
    }
    
    public func shuffledOptions() -> Question {
        var rng = SystemRandomNumberGenerator()
        return shuffledOptions(using: &rng)
    }
}
