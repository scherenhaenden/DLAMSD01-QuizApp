import SwiftUI

/// Screen displayed upon round completion, displaying analytics, accuracy %, and academic evaluation tier.
///
/// Features:
/// - Celebratory / encouragement trophy icon matching user performance.
/// - Academic evaluation tier according to German university standards (Sehr Gut, Gut, etc.) and numerical grade (1.0 - 5.0).
/// - Comprehensive performance metric tiles: total score points, accuracy percentage, best streak, and average response speed.
/// - Category breakdown showing performance fraction and visual mini-progress bar for each tested category.
/// - Call to action buttons to initiate another round or return to the main menu.
public struct ResultView: View {
    public let record: ScoreRecord
    public let onPlayAgain: () -> Void
    public let onBackToMenu: () -> Void
    
    public init(
        record: ScoreRecord,
        onPlayAgain: @escaping () -> Void,
        onBackToMenu: @escaping () -> Void
    ) {
        self.record = record
        self.onPlayAgain = onPlayAgain
        self.onBackToMenu = onBackToMenu
    }
    
    /// Chromatic tone reflecting whether the user passed (green) or requires review (orange).
    private var gradeColor: Color {
        return record.isPassing ? .green : .orange
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Achievement icon & Academic seal
                VStack(spacing: 12) {
                    Image(systemName: record.isPassing ? "trophy.fill" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(gradeColor)
                    
                    VStack(spacing: 6) {
                        Text(record.isPassing ? "Round Completed!" : "Good Effort!")
                            .font(.title2.bold())
                        
                        Text(record.germanGrade.formattedGrade)
                            .font(.headline)
                            .foregroundColor(gradeColor)
                        
                        Text(record.academicEvaluationTier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 16)
                
                // Key metrics dashboard card
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        MetricTile(title: "Score", value: "\(record.score)", icon: "star.fill", tint: .yellow)
                        Divider().frame(height: 36)
                        MetricTile(title: "Accuracy", value: record.accuracyDescription, icon: "percent", tint: gradeColor)
                        Divider().frame(height: 36)
                        MetricTile(title: "Streak", value: "\(record.streakRecord)", icon: "flame.fill", tint: .orange)
                        Divider().frame(height: 36)
                        MetricTile(title: "Avg Speed", value: record.formattedAverageSpeed, icon: "timer", tint: .blue)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Detailed fraction & total duration tally
                    HStack {
                        Label("Time Spent: \(record.formattedDuration)", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(record.correctAnswers) of \(record.totalQuestions) Correct")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.adaptiveSecondaryBackground)
                )
                .padding(.horizontal)
                .frame(maxWidth: 550)
                
                // Category breakdown card (if available)
                if !record.categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Performance by Category", systemImage: "chart.bar.xaxis")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        ForEach(record.categoryBreakdown) { item in
                            VStack(spacing: 6) {
                                HStack {
                                    Text(item.categoryTitle)
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(item.correctCount)/\(item.totalCount) (\(item.accuracyDescription))")
                                        .font(.footnote.bold().monospacedDigit())
                                        .foregroundColor(item.accuracyRate >= 0.5 ? .green : .orange)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.15))
                                            .frame(height: 6)
                                        Capsule()
                                            .fill(item.accuracyRate >= 0.5 ? Color.green : Color.orange)
                                            .frame(width: max(6, geo.size.width * item.accuracyRate), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.adaptiveSecondaryBackground)
                    )
                    .padding(.horizontal)
                    .frame(maxWidth: 550)
                }
                
                // Action navigation buttons
                VStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("result.playAgain")
                    
                    Button(action: onBackToMenu) {
                        Text("Return to Menu")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.adaptiveSecondaryBackground)
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("result.returnToMenu")
                }
                .padding(.horizontal)
                .frame(maxWidth: 550)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }
}

/// Small metric tile helper for dashboard analytics.
private struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity)
    }
}
