import SwiftUI

/// Modular presentation card for a quiz category or domain focus.
///
/// Features:
/// - Distinctive domain icon and metadata chips.
/// - Adaptive high-contrast colors matching light and dark themes.
/// - Minimum 56 pt touch target ergonomics with decoupled hit testing.
/// - Integrated VoiceOver accessibility labeling.
public struct CategoryCard: View {
    public let category: QuizCategory?
    public let questionCount: Int
    public let isSelected: Bool
    public let action: () -> Void
    
    public init(
        category: QuizCategory?,
        questionCount: Int = 6,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.questionCount = questionCount
        self.isSelected = isSelected
        self.action = action
    }
    
    // MARK: - Computed Metadata
    
    public var title: String {
        return category?.displayName ?? "All Topics (Mixed)"
    }
    
    public var iconName: String {
        return category?.iconName ?? "square.grid.2x2.fill"
    }
    
    public var subtitle: String {
        if let cat = category {
            return cat.localizedDescription
        }
        return "Comprehensive cross-discipline challenge (\(questionCount) questions)"
    }
    
    private var isMixed: Bool {
        return category == nil
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Category Icon Badge
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isMixed ? .white : .accentColor)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isMixed ? Color.accentColor : Color.accentColor.opacity(0.12))
                    )
                
                // Content Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Action Target Pill
                HStack(spacing: 4) {
                    Text("Start")
                        .font(.subheadline.bold())
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(questionCount) questions. \(subtitle)")
        .accessibilityHint("Double tap to start quiz in this category.")
        .accessibilityAddTraits(.isButton)
    }
}
