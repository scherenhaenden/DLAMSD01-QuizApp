import SwiftUI

/// One action starts either a category round or a mixed round.
/// The Start pill is part of the card label, not a nested button.
public struct CategoryCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let category: QuizCategory?
    public let questionCount: Int
    public let isLoading: Bool
    public let isSelected: Bool
    public let action: () -> Void

    public init(
        category: QuizCategory?,
        questionCount: Int = 6,
        isLoading: Bool = false,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.questionCount = questionCount
        self.isLoading = isLoading
        self.isSelected = isSelected
        self.action = action
    }

    public var title: String {
        category?.displayName ?? "All Topics (Mixed)"
    }

    public var iconName: String {
        category?.iconName ?? "square.grid.2x2.fill"
    }

    public var subtitle: String {
        category?.localizedDescription ?? "A mixed round across all available topics."
    }

    private var countLabel: String {
        if isLoading { return "Loading questions…" }
        guard questionCount > 0 else { return "No questions available" }
        return "\(questionCount) \(questionCount == 1 ? "question" : "questions")"
    }

    private var startLabel: some View {
        Label("Start", systemImage: "play.fill")
            .font(.subheadline.bold())
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.15))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(category == nil ? .white : .accentColor)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(category == nil ? Color.accentColor : Color.accentColor.opacity(0.12))
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(countLabel).font(.caption).foregroundColor(.secondary)
                        if !isLoading && questionCount > 0 { startLabel }
                    }
                } else {
                    HStack {
                        Text(countLabel).font(.caption).foregroundColor(.secondary)
                        Spacer()
                        if !isLoading && questionCount > 0 { startLabel }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.adaptiveSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                    .allowsHitTesting(false)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading || questionCount <= 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(countLabel). \(subtitle)")
        .accessibilityHint(
            isLoading
                ? "Question availability is loading."
                : questionCount > 0
                    ? "Double tap to start this quiz."
                    : "No questions are available for this topic."
        )
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityIdentifier("home.category.\(category?.rawValue ?? "mixed")")
    }
}
