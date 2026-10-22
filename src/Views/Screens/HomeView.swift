import SwiftUI

/// Main home menu view allowing category selection, theme customization, and game initiation.
///
/// Features & Ergonomics:
/// - Hero banner with branding and responsive layout.
/// - Full-width interactive category cards with immediate tactile touch feedback.
/// - In-app Theme Selector (Auto / Light / Dark) dynamically toggling the color scheme.
/// - Fully adaptive for both Dark Mode and Light Mode with high-contrast semantics.
/// - Constrained maximum width (550 pt) ensuring optimal ergonomics on the iPad (9th gen) 10.2" canvas.
public struct HomeView: View {
    @ObservedObject public var viewModel: QuizViewModel
    @State private var selectedCategory: QuizCategory?
    @AppStorage("app_theme") private var selectedTheme: String = AppTheme.system.rawValue
    
    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    /// Resolves the question count for the active selection.
    private var questionCountLabel: String {
        if selectedCategory != nil {
            return "6 Questions Available"
        } else {
            return "24 Questions (6 per Domain)"
        }
    }
    
    /// Dynamic text for the primary action button.
    private var startButtonTitle: String {
        if let selectedCategory = selectedCategory {
            return "Start \(selectedCategory.displayName)"
        } else {
            return "Start Mixed Quiz"
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive canvas background (Light: #F2F2F7, Dark: #000000)
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with theme picker
                        HStack {
                            Spacer()
                            
                            // Compact Theme Switcher (Auto, Light, Dark)
                            HStack(spacing: 4) {
                                ForEach(AppTheme.allCases) { theme in
                                    let isCurrent = selectedTheme == theme.rawValue
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTheme = theme.rawValue
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: theme.iconName)
                                                .font(.caption2.bold())
                                            Text(theme.displayName)
                                                .font(.caption2.bold())
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(isCurrent ? Color.accentColor : Color.clear)
                                        )
                                        .foregroundColor(isCurrent ? .white : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(4)
                            .background(
                                Capsule()
                                    .fill(Color.adaptiveCardBackground)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                                    .allowsHitTesting(false)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        // App Branding Hero
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 58))
                                .foregroundColor(.accentColor)
                                .padding(.top, 4)
                            
                            Text("Train-your-Brain")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                            
                            Text("Software Engineering & iOS Quiz")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 4)
                        
                        // Primary Quick Play CTA Button
                        Button {
                            viewModel.startQuiz(category: selectedCategory)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                    .font(.headline)
                                Text(startButtonTitle)
                                    .font(.headline.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .frame(maxWidth: 550)
                        
                        // Category Selection Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Select Domain Focus")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(questionCountLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // All Categories Tile (Mixed Round)
                            categoryCard(
                                title: "All Topics (Mixed)",
                                subtitle: "Comprehensive cross-discipline challenge (24 questions)",
                                iconName: "square.grid.2x2.fill",
                                isSelected: selectedCategory == nil,
                                onSelect: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = nil
                                    }
                                },
                                onStart: {
                                    viewModel.startQuiz(category: nil)
                                }
                            )
                            
                            // Individual Subject Domain Tiles
                            ForEach(QuizCategory.allCases) { category in
                                categoryCard(
                                    title: category.displayName,
                                    subtitle: category.localizedDescription,
                                    iconName: category.iconName,
                                    isSelected: selectedCategory == category,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = category
                                        }
                                    },
                                    onStart: {
                                        viewModel.startQuiz(category: category)
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: 550)
                    }
                    .padding(.bottom, 32)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    // MARK: - Subviews & Builders
    
    /// Reusable selectable category card with full hit-testing and direct launch support.
    @ViewBuilder
    private func categoryCard(
        title: String,
        subtitle: String,
        iconName: String,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onStart: @escaping () -> Void
    ) -> some View {
        Button {
            if isSelected {
                onStart()
            } else {
                onSelect()
            }
        } label: {
            HStack(spacing: 14) {
                // Category icon badge
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                    )
                
                // Title and description
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Visual selection and direct start cue
                if isSelected {
                    HStack(spacing: 4) {
                        Text("Start")
                            .font(.caption.bold())
                            .foregroundColor(.accentColor)
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary.opacity(0.4))
                        .font(.caption)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.adaptiveCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.adaptiveBorder, lineWidth: isSelected ? 2 : 1)
                    .allowsHitTesting(false)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

/// Custom button style adding subtle scale and opacity feedback on physical touch down.
public struct CardPressButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
