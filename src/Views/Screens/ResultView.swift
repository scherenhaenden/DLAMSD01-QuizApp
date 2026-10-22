import SwiftUI

/// Screen displayed upon round completion, displaying analytics, accuracy %, and academic evaluation tier.
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
    
    private var gradeColor: Color {
        return record.isPassing ? .green : .orange
    }
    
    public var body: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Achievement icon
            Image(systemName: record.isPassing ? "trophy.fill" : "arrow.triangle.2.circlepath")
                .font(.system(size: 64))
                .foregroundColor(gradeColor)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                Text(record.isPassing ? "Round Completed!" : "Good Effort!")
                    .font(.title.bold())
                
                Text(record.academicEvaluationTier)
                    .font(.headline)
                    .foregroundColor(gradeColor)
            }
            
            // Score analytics card
            VStack(spacing: 16) {
                HStack {
                    MetricTile(title: "Score", value: "\(record.score)", icon: "star.fill", tint: .yellow)
                    Divider().frame(height: 40)
                    MetricTile(title: "Accuracy", value: record.accuracyDescription, icon: "percent", tint: gradeColor)
                    Divider().frame(height: 40)
                    MetricTile(title: "Best Streak", value: "\(record.streakRecord)", icon: "flame.fill", tint: .orange)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                HStack {
                    Text("Correct Answers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(record.correctAnswers) of \(record.totalQuestions)")
                        .font(.subheadline.bold())
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.adaptiveSecondaryBackground)
            )
            .padding(.horizontal)
            .frame(maxWidth: 550)
            
            Spacer()
            
            // Action buttons
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
                
                Button(action: onBackToMenu) {
                    Text("Return to Menu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.adaptiveSecondaryBackground)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: 550)
            .padding(.bottom, 20)
        }
    }
}

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
