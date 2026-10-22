import SwiftUI

/// Animated countdown progress bar that shifts color dynamically as time elapses.
public struct TimerBar: View {
    public let timeRemaining: TimeInterval
    public let totalTime: TimeInterval
    
    public init(timeRemaining: TimeInterval, totalTime: TimeInterval = 15.0) {
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
    }
    
    private var progress: Double {
        guard totalTime > 0 else { return 0.0 }
        return min(max(timeRemaining / totalTime, 0.0), 1.0)
    }
    
    private var barColor: Color {
        if timeRemaining <= 3.0 {
            return .red
        } else if timeRemaining <= 6.0 {
            return .orange
        } else {
            return .blue
        }
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label("\(Int(ceil(timeRemaining)))s", systemImage: "timer")
                    .font(.caption.bold())
                    .foregroundColor(barColor)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.linear(duration: 0.25), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
