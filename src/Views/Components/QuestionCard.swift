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
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                // Category badge chip with domain icon
                Label(question.category.displayName, systemImage: question.category.iconName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
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
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}
