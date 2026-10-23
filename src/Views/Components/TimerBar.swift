import SwiftUI

/// Animated countdown progress bar that shifts color dynamically as time elapses.
///
/// Chromatic Alert Logic (Relative Proportional Thresholds):
/// - Normal (Blue): > 50% of the total question duration remaining.
/// - Warning (Amber / Orange): Between 20% and 50% remaining.
/// - Critical (Crimson Red): <= 20% remaining.
public struct TimerBar: View {
    
    /// Urgency tiers defining visual chromatic alerting based on relative time remaining.
    public enum UrgencyPhase: String, CaseIterable, Equatable {
        case normal
        case warning
        case critical
    }
    
    public let timeRemaining: TimeInterval
    public let totalTime: TimeInterval
    
    public init(timeRemaining: TimeInterval, totalTime: TimeInterval = 15.0) {
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
    }
    
    /// Fractional ratio in range `[0.0, 1.0]` driving horizontal bar scale.
    public var progress: Double {
        guard totalTime > 0 else { return 0.0 }
        return min(max(timeRemaining / totalTime, 0.0), 1.0)
    }
    
    /// Resolves urgency tier dynamically from remaining time ratio.
    public static func resolveUrgencyPhase(progress: Double) -> UrgencyPhase {
        if progress <= 0.20 {
            return .critical
        } else if progress <= 0.50 {
            return .warning
        } else {
            return .normal
        }
    }
    
    /// Maps an urgency phase to its semantic UI presentation color.
    public static func resolveColor(for phase: UrgencyPhase) -> Color {
        switch phase {
        case .normal:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    /// Current urgency phase evaluated from active progress.
    public var currentUrgencyPhase: UrgencyPhase {
        Self.resolveUrgencyPhase(progress: progress)
    }
    
    /// Resolves the urgency indicator color based on proportional progress.
    public var barColor: Color {
        Self.resolveColor(for: currentUrgencyPhase)
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // Numeric countdown label
            HStack {
                Label("\(Int(ceil(max(timeRemaining, 0.0))))s", systemImage: "timer")
                    .font(.caption.bold())
                    .foregroundColor(barColor)
                Spacer()
            }
            
            // Dynamic width bar with smooth linear animation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time remaining: \(Int(ceil(max(timeRemaining, 0.0)))) seconds")
        .accessibilityIdentifier("quiz.timerBar")
    }
}
