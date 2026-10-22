import SwiftUI

/// Reusable answer selection button conforming to Apple Human Interface Guidelines (HIG).
/// Guarantees comfortable touch target (minimum 50 pt height, adaptable width) and stateful color feedback.
public struct AnswerButton: View {
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
    
    private var backgroundColor: Color {
        if isAnswerRevealed {
            if isCorrectAnswer == true {
                return Color.green.opacity(0.85)
            } else if isSelected && isCorrectAnswer == false {
                return Color.red.opacity(0.85)
            }
        } else if isSelected {
            return Color.accentColor.opacity(0.8)
        }
        return Color.adaptiveSecondaryBackground
    }
    
    private var foregroundColor: Color {
        if isAnswerRevealed && (isCorrectAnswer == true || isSelected) {
            return .white
        }
        return .primary
    }
    
    private var optionLetter: String {
        let letters = ["A", "B", "C", "D"]
        return index < letters.count ? letters[index] : "\(index + 1)"
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(optionLetter)
                    .font(.subheadline.bold())
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
                
                Text(optionText)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)
                
                Spacer()
                
                if isAnswerRevealed {
                    if isCorrectAnswer == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    } else if isSelected && isCorrectAnswer == false {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isAnswerRevealed && isCorrectAnswer == true ? Color.green : Color.clear, lineWidth: 2)
            )
            .foregroundColor(foregroundColor)
        }
        .buttonStyle(.plain)
        .disabled(isAnswerRevealed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Option \(optionLetter): \(optionText)")
    }
}
