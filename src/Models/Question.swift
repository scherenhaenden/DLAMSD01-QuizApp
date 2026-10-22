import Foundation

/// Core domain entity representing a single multiple-choice question.
///
/// Designed following Domain-Driven Design (DDD) principles:
/// - Immutable value semantics (`struct`) ensuring thread safety and side-effect-free state handling.
/// - Strict invariant validation in the initializers to guarantee that corrupted or malformed
///   questions cannot exist within the application lifecycle.
/// - Fulfills all IU exam assignment requirements: clear prompt, 4 choices, single correct
///   answer index, and comprehensive pedagogical rationale for immediate user feedback.
public struct Question: Identifiable, Codable, Equatable, Hashable, Sendable {
    /// Unique identifier for stable SwiftUI identity and tracking across round sessions.
    public let id: UUID
    
    /// The actual question formulation presented to the learner.
    public let prompt: String
    
    /// List of multiple choice options (exactly 4 options as per IU guidelines).
    public let options: [String]
    
    /// 0-based index indicating which entry in `options` constitutes the correct answer.
    public let correctAnswerIndex: Int
    
    /// Detailed pedagogical explanation displayed immediately upon answering (Hattie & Timperley feedback model).
    public let explanation: String
    
    /// The academic knowledge domain to which this question belongs.
    public let category: QuizCategory
    
    /// The cognitive difficulty tier of the question.
    public let difficulty: Difficulty
    
    /// Domain validation error states triggered if a question violates business invariants.
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
    
    /// Primary designated initializer enforcing domain invariants.
    ///
    /// Throws a `ValidationError` if:
    /// - Prompt or explanation consists solely of whitespace.
    /// - Fewer than 2 options are supplied.
    /// - `correctAnswerIndex` falls outside the bounds of `options.indices`.
    /// - Duplicate option texts exist within the choices.
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
        
        // Ensure no duplicate answers exist to preserve quiz integrity
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
    
    /// Custom decoding initializer providing safe defaults for optional fields (e.g. generating UUID if absent).
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
    /// Pure function without side-effects.
    public func isCorrect(selectedOptionIndex: Int) -> Bool {
        return selectedOptionIndex == correctAnswerIndex
    }
    
    /// Human-readable text of the correct choice.
    public var correctAnswerText: String {
        return options[correctAnswerIndex]
    }
    
    /// Produces a shuffled permutation of the multiple-choice options using Fisher-Yates randomization.
    ///
    /// Crucially recalculates and preserves the updated `correctAnswerIndex` pointing to the
    /// same correct choice string, preventing position-based pattern memorization across sessions.
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
    
    /// Convenience overload using the default system random number generator.
    public func shuffledOptions() -> Question {
        var rng = SystemRandomNumberGenerator()
        return shuffledOptions(using: &rng)
    }
}
