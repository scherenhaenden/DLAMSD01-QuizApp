import SwiftUI

/// Accessible leaderboard and history view presenting recorded high scores,
/// German academic grades, and detailed statistics (US-13, US-14, Stage 62).
public struct LeaderboardView: View {
    @ObservedObject public var viewModel: LeaderboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: LeaderboardViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        summaryStatisticsBar
                        
                        // Mode Segmented Control
                        Picker("Presentation Mode", selection: $viewModel.selectedTab) {
                            ForEach(LeaderboardViewModel.FilterTab.allCases) { tab in
                                Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("leaderboard.segmentPicker")
                        
                        categoryFilterBar
                        
                        if viewModel.displayedRecords.isEmpty {
                            emptyStateView
                        } else {
                            recordsListView
                            
                            clearHistoryButton
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Leaderboard & History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("leaderboard.dismiss")
                }
            }
            .confirmationDialog(
                "Clear History",
                isPresented: $viewModel.showClearConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Delete All Records", role: .destructive) {
                    viewModel.clearAllHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action permanently deletes all saved quiz scores and statistics. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Subviews
    
    var summaryStatisticsBar: some View {
        HStack(spacing: 12) {
            statTile(
                title: "Games",
                value: "\(viewModel.totalGamesCount)",
                icon: "gamecontroller.fill",
                color: .blue
            )
            
            statTile(
                title: "Avg Accuracy",
                value: "\(viewModel.averageAccuracy)%",
                icon: "percent",
                color: .green
            )
            
            statTile(
                title: "Best Score",
                value: "\(viewModel.personalBest?.score ?? 0)",
                icon: "trophy.fill",
                color: .orange
            )
        }
    }
    
    func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.adaptiveCardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryFilterChip(title: "All Topics", category: nil)
                
                ForEach(QuizCategory.allCases) { category in
                    categoryFilterChip(title: category.displayName, category: category)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    func categoryFilterChip(title: String, category: QuizCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectedCategory = category
        } label: {
            HStack(spacing: 6) {
                if let cat = category {
                    Image(systemName: cat.iconName)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.adaptiveCardBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.6))
                .accessibilityHidden(true)
            
            Text("No Games Recorded Yet")
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text("Complete a quiz round to record your high scores, academic grades, and agility metrics here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.adaptiveCardBackground)
        )
        .accessibilityIdentifier("leaderboard.emptyState")
    }
    
    var recordsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(viewModel.displayedRecords.enumerated()), id: \.element.id) { index, record in
                recordCard(index: index, record: record)
            }
        }
    }
    
    func recordCard(index: Int, record: ScoreRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                if viewModel.selectedTab == .highScores {
                    rankBadge(rank: index + 1)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let category = record.category {
                        Label(category.displayName, systemImage: category.iconName)
                            .font(.caption.bold())
                            .foregroundColor(.accentColor)
                    } else {
                        Label("Mixed Topics", systemImage: "square.grid.2x2.fill")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    Text(DateFormatter.localizedString(from: record.completedAt, dateStyle: .medium, timeStyle: .short))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // German academic grade badge (high-contrast WCAG AAA/AA compliant solid capsule)
                Text(record.germanGrade.formattedGrade)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(record.germanGrade.isPassing ? Color.quizCorrectFeedback : Color.quizIncorrectFeedback)
                    )
                    .foregroundColor(.white)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                metricColumn(label: "Score", value: "\(record.score) pts")
                metricColumn(label: "Accuracy", value: "\(record.accuracyPercentage)% (\(record.correctAnswers)/\(record.totalQuestions))")
                metricColumn(label: "Streak", value: "🔥 \(record.streakRecord)")
                metricColumn(label: "Speed", value: record.formattedAverageSpeed)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.adaptiveCardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.selectedTab == .highScores ? "Rank \(index + 1), " : "")\(record.categoryTitle). Score \(record.score) points, Grade \(record.germanGrade.formattedGrade), Accuracy \(record.accuracyPercentage) percent, Streak \(record.streakRecord), Average Speed \(record.formattedAverageSpeed)")
    }
    
    func rankBadge(rank: Int) -> some View {
        let (color, text): (Color, String) = {
            switch rank {
            case 1: return (Color(red: 0.90, green: 0.72, blue: 0.15), "🥇 #1")
            case 2: return (Color.gray, "🥈 #2")
            case 3: return (Color(red: 0.75, green: 0.45, blue: 0.20), "🥉 #3")
            default: return (Color.secondary, "#\(rank)")
            }
        }()
        
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.2)))
            .foregroundColor(color)
    }
    
    func metricColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote.bold().monospacedDigit())
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
    
    var clearHistoryButton: some View {
        Button(role: .destructive) {
            viewModel.showClearConfirmationDialog = true
        } label: {
            Label("Clear All History", systemImage: "trash")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .foregroundColor(.red)
        }
        .buttonStyle(.bordered)
        .padding(.top, 8)
        .accessibilityIdentifier("leaderboard.clearButton")
    }
}
