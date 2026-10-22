import SwiftUI

/// Card view presenting the question prompt, category badge, and difficulty indicator.
///
/// Designed with continuous rounded corners (`style: .continuous`) and subtle elevation
/// to maintain a clean, distraction-free visual hierarchy matching Apple system apps.
public struct QuestionCard: View {
    public let question: Question
    public let questionNumber: Int
    public let totalQuestions: Int
    
    public init(question: Question, questionNumber: Int, totalQuestions: Int) {
        self.question = question
        self.questionNumber = questionNumber
        self.totalQuestions = totalQuestions
    }
    
    /// Combined accessibility description for assistive technologies (VoiceOver).
    public var combinedAccessibilityLabel: String {
        return "Question \(questionNumber) of \(totalQuestions), Category: \(question.category.displayName), Difficulty: \(question.difficulty.displayName). \(question.prompt)"
    }
    
    /// Semantic tint color mapped to difficulty tier.
    private var difficultyColor: Color {
        switch question.difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .purple
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                // Category badge chip with domain icon
                Label(question.category.displayName, systemImage: question.category.iconName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
                
                // Difficulty & time limit indicator pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(difficultyColor)
                        .frame(width: 6, height: 6)
                    Text("\(question.difficulty.displayName) (\(Int(question.difficulty.timeLimitSeconds))s)")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(difficultyColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(difficultyColor.opacity(0.10))
                .clipShape(Capsule())
                
                Spacer()
                
                // Question progress counter
                Text("Question \(questionNumber) / \(totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Question prompt text with comfortable line spacing for readability
            Text(question.prompt)
                .font(.title3.weight(.semibold))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.adaptiveSecondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedAccessibilityLabel)
    }
}
