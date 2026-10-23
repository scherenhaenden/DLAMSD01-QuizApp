import SwiftUI

/// Home screen with a direct start action per topic and counts from the loaded catalog.
public struct HomeView: View {
    @ObservedObject public var viewModel: QuizViewModel
    @AppStorage("app_theme") private var selectedTheme: String = AppTheme.system.rawValue
    @State private var showLeaderboard: Bool = false

    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        headerActions

                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            Text("Train-your-Brain")
                                .font(.largeTitle.bold())
                            Text("Software Engineering & iOS Quiz")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Choose a Quiz")
                                .font(.headline)
                            Text(catalogSummary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if let error = viewModel.catalogError {
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("Reload Questions") {
                                    viewModel.loadQuestionCatalog()
                                }
                                .buttonStyle(.bordered)
                            }

                            if viewModel.isCatalogLoaded || viewModel.catalogError == nil {
                                let isLoading = !viewModel.isCatalogLoaded
                                CategoryCard(
                                    category: nil,
                                    questionCount: viewModel.availableQuestionCount,
                                    isLoading: isLoading
                                ) {
                                    viewModel.startQuiz()
                                }

                                ForEach(QuizCategory.allCases) { category in
                                    CategoryCard(
                                        category: category,
                                        questionCount: viewModel.questionCount(for: category),
                                        isLoading: isLoading
                                    ) {
                                        viewModel.startQuiz(category: category)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: 550)
                    .frame(maxWidth: .infinity)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView(viewModel: LeaderboardViewModel(scoreStore: viewModel.scoreStore))
            }
        }
        .task {
            viewModel.loadQuestionCatalog()
        }
    }

    private var catalogSummary: String {
        if viewModel.catalogError != nil { return "Questions unavailable" }
        guard viewModel.isCatalogLoaded else { return "Loading questions…" }
        return "\(viewModel.availableQuestionCount) questions available"
    }

    private var headerActions: some View {
        HStack {
            Button {
                showLeaderboard = true
            } label: {
                Label("Scores", systemImage: "trophy.fill")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color.adaptiveCardBackground)
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("View Leaderboard and High Scores")
            .accessibilityIdentifier("home.scoresButton")

            Spacer(minLength: 0)

            themePicker
        }
    }

    private var themePicker: some View {
        Menu {
            Picker("Appearance", selection: $selectedTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.displayName, systemImage: theme.iconName).tag(theme.rawValue)
                }
            }
        } label: {
            Label(AppTheme(rawValue: selectedTheme)?.displayName ?? "Auto", systemImage: "circle.lefthalf.filled")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.adaptiveCardBackground)
                .clipShape(Capsule())
        }
        .accessibilityLabel("Appearance")
        .accessibilityValue(AppTheme(rawValue: selectedTheme)?.displayName ?? "Auto")
    }
}
