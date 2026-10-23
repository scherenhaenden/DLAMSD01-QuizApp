import SwiftUI

/// Question content with metadata that can stack on narrow screens or at large text sizes.
public struct QuestionCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let question: Question
    public let questionNumber: Int
    public let totalQuestions: Int

    public init(question: Question, questionNumber: Int, totalQuestions: Int) {
        self.question = question
        self.questionNumber = questionNumber
        self.totalQuestions = totalQuestions
    }

    public var combinedAccessibilityLabel: String {
        "Question \(questionNumber) of \(totalQuestions), Category: \(question.category.displayName), Difficulty: \(question.difficulty.displayName), time limit: \(Int(question.difficulty.timeLimitSeconds)) seconds. \(question.prompt)"
    }

    private var difficultyColor: Color {
        switch question.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .purple
        }
    }

    private var categoryBadge: some View {
        Label(question.category.displayName, systemImage: question.category.iconName)
            .font(.subheadline)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var difficultyBadge: some View {
        HStack(spacing: 4) {
            Circle().fill(difficultyColor).frame(width: 6, height: 6)
            Text("\(question.difficulty.displayName) (\(Int(question.difficulty.timeLimitSeconds))s)")
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(difficultyColor.opacity(0.10))
        .clipShape(Capsule())
    }

    private var progressLabel: some View {
        Text("Question \(questionNumber) / \(totalQuestions)")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var stackedMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            categoryBadge
            difficultyBadge
            progressLabel
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if dynamicTypeSize.isAccessibilitySize {
                stackedMetadata
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        categoryBadge.fixedSize()
                        difficultyBadge.fixedSize()
                        Spacer(minLength: 0)
                        progressLabel.fixedSize()
                    }
                    stackedMetadata
                }
            }

            Text(question.prompt)
                .font(.title2.bold())
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(combinedAccessibilityLabel)
    }
}
