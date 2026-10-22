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
                            CategoryCard(
                                category: nil,
                                questionCount: 24,
                                isSelected: selectedCategory == nil,
                                action: {
                                    if selectedCategory == nil {
                                        viewModel.startQuiz(category: nil)
                                    } else {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = nil
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal)
                            
                            // Individual Subject Domain Tiles
                            ForEach(QuizCategory.allCases) { category in
                                CategoryCard(
                                    category: category,
                                    questionCount: 6,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        if selectedCategory == category {
                                            viewModel.startQuiz(category: category)
                                        } else {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal)
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
}
