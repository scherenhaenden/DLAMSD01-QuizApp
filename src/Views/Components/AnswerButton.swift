import SwiftUI

private struct EvaluationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.96 : 1)
    }
}

/// Reusable answer button with explicit evaluation states.
///
/// Ergonomic & Accessibility Features:
/// - Guarantees comfortable touch target size (minimum 56 pt height, exceeding the 44x44 pt HIG baseline).
/// - Multiline text and a scaled option badge to accommodate larger text.
/// - State-dependent chromatic feedback: emerald green for correct choices, crimson red for wrong picks, and dimmed for unselected choices.
/// - Integrated VoiceOver accessibility labeling combining option letter, prompt text, and contextual status hints.
public struct AnswerButton: View {
    
    @ScaledMetric(relativeTo: .subheadline) private var optionBadgeSize: CGFloat = 32

    // MARK: - State Machine Definition
    
    /// Discrete presentation and interaction states for answer evaluation.
    public enum VisualState: Equatable {
        case idle
        case selected
        case correct
        case wrong
        case dimmed
    }
    
    /// Minimum touch target height exceeding Apple's 44 pt HIG requirement.
    public static let minTouchTargetHeight: CGFloat = 56.0
    
    // MARK: - Public Properties
    
    public let optionText: String
    public let index: Int
    public let isSelected: Bool
    public let isCorrectAnswer: Bool?
    public let isAnswerRevealed: Bool
    public let action: () -> Void
    
    public init(
        optionText: String,
        index: Int,
        isSelected: Bool = false,
        isCorrectAnswer: Bool? = nil,
        isAnswerRevealed: Bool = false,
        action: @escaping () -> Void
    ) {
        self.optionText = optionText
        self.index = index
        self.isSelected = isSelected
        self.isCorrectAnswer = isCorrectAnswer
        self.isAnswerRevealed = isAnswerRevealed
        self.action = action
    }
    
    // MARK: - State Resolution Logic
    
    /// Resolves the visual state based on selection, correctness, and evaluation phase.
    public static func resolveVisualState(
        isSelected: Bool,
        isCorrectAnswer: Bool?,
        isAnswerRevealed: Bool
    ) -> VisualState {
        if isAnswerRevealed {
            if isCorrectAnswer == true {
                return .correct
            } else if isSelected && isCorrectAnswer == false {
                return .wrong
            } else {
                return .dimmed
            }
        } else if isSelected {
            return .selected
        } else {
            return .idle
        }
    }
    
    public var visualState: VisualState {
        Self.resolveVisualState(
            isSelected: isSelected,
            isCorrectAnswer: isCorrectAnswer,
            isAnswerRevealed: isAnswerRevealed
        )
    }
    
    // MARK: - Styling & Layout Tokens
    
    private var stateTint: Color {
        switch visualState {
        case .correct: return .quizCorrectFeedback
        case .wrong: return .quizIncorrectFeedback
        case .selected: return .accentColor
        case .idle, .dimmed: return .clear
        }
    }

    private var backgroundColor: Color {
        switch visualState {
        case .correct, .wrong:
            return stateTint
        case .selected:
            return stateTint.opacity(0.12)
        case .idle:
            return Color.adaptiveSecondaryBackground
        case .dimmed:
            return Color.adaptiveTertiaryBackground
        }
    }

    private var feedbackForegroundColor: Color {
        switch visualState {
        case .correct, .wrong: return .white
        case .dimmed: return .secondary
        case .idle, .selected: return .primary
        }
    }

    /// Converts numeric 0-based index to standard multiple-choice letters (A, B, C, D).
    private var optionLetter: String {
        let letters = ["A", "B", "C", "D"]
        return letters.indices.contains(index) ? letters[index] : "?"
    }
    
    // MARK: - Accessibility Helpers
    
    public static func formattedAccessibilityLabel(letter: String, text: String) -> String {
        return "Option \(letter): \(text)"
    }
    
    public static func accessibilityHintText(for state: VisualState) -> String {
        switch state {
        case .idle:
            return "Double tap to select this answer."
        case .selected:
            return "Selected. Double tap to change selection."
        case .correct:
            return "Correct answer."
        case .wrong:
            return "Incorrect answer."
        case .dimmed:
            return "Unselected incorrect option."
        }
    }

    public static func accessibilityValueText(for state: VisualState) -> String {
        switch state {
        case .correct:
            return "Correct answer"
        case .wrong:
            return "Incorrect answer"
        case .dimmed:
            return "Not selected"
        case .selected:
            return "Selected"
        case .idle:
            return ""
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Choice letter badge
                Text(optionLetter)
                    .font(.subheadline.bold())
                    .frame(width: optionBadgeSize, height: optionBadgeSize)
                    .background(
                        Circle().fill(
                            visualState == .correct || visualState == .wrong
                                ? Color.white.opacity(0.2)
                                : Color.primary.opacity(0.08)
                        )
                    )
                
                // Answer text with multi-line wrap support and Dynamic Type scaling
                Text(optionText)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Visual validation icon upon answer reveal (Color-blind redundant indicators)
                if visualState == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                } else if visualState == .wrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: Self.minTouchTargetHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stateTint, lineWidth: 2)
                    .allowsHitTesting(false)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundColor(feedbackForegroundColor)
        }
        .buttonStyle(.plain)
        .disabled(isAnswerRevealed) // Prevent double-tap race conditions after selection
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.formattedAccessibilityLabel(letter: optionLetter, text: optionText))
        .accessibilityHint(Self.accessibilityHintText(for: visualState))
        .accessibilityValue(Self.accessibilityValueText(for: visualState))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityIdentifier("quiz.answer.\(index)")
    }
}
