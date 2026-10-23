import Foundation
import Combine

/// Presentation view model coordinating leaderboard scores, history tracking, and statistical aggregation.
///
/// Designed under MVVM with `@MainActor` isolation to drive `LeaderboardView` smoothly,
/// supporting tabbed presentation ("High Scores" vs "Recent Games"), category filtering,
/// and clearing data with confirmation dialogs.
@MainActor
public final class LeaderboardViewModel: ObservableObject {
    /// Presentation tabs available in the leaderboard interface.
    public enum FilterTab: String, CaseIterable, Identifiable {
        case highScores = "High Scores"
        case history = "Recent Games"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .highScores: return "trophy.fill"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }
    
    // MARK: - Published Properties
    
    /// Active tab filter driving the record sorting strategy.
    @Published public var selectedTab: FilterTab = .highScores {
        didSet { refresh() }
    }
    
    /// Optional category filter (`nil` indicates all categories combined).
    @Published public var selectedCategory: QuizCategory? = nil {
        didSet { refresh() }
    }
    
    /// Filtered and sorted records presented in the UI list.
    @Published public private(set) var displayedRecords: [ScoreRecord] = []
    
    /// Total number of rounds played matching current category filter.
    @Published public private(set) var totalGamesCount: Int = 0
    
    /// Average accuracy percentage across all matching rounds (0-100%).
    @Published public private(set) var averageAccuracy: Int = 0
    
    /// Personal best score record for the selected filter context.
    @Published public private(set) var personalBest: ScoreRecord? = nil
    
    /// Controls presentation of the destructive "Clear All History" confirmation dialog.
    @Published public var showClearConfirmationDialog: Bool = false
    
    // MARK: - Dependencies
    
    private let scoreStore: ScoreStoreProtocol
    
    /// Initializes the view model with a score store instance.
    ///
    /// - Parameter scoreStore: Service conforming to `ScoreStoreProtocol` (defaults to standard `UserDefaultsScoreStore`).
    public init(scoreStore: ScoreStoreProtocol = UserDefaultsScoreStore()) {
        self.scoreStore = scoreStore
        refresh()
    }
    
    // MARK: - Intent Methods
    
    /// Reloads records from the store and computes aggregated metrics.
    public func refresh() {
        let allRecords = scoreStore.loadRecords()
        
        // Filter by category if selected
        let matchingRecords = allRecords.filter { record in
            guard let category = selectedCategory else { return true }
            return record.category == category
        }
        
        self.totalGamesCount = matchingRecords.count
        
        if matchingRecords.isEmpty {
            self.displayedRecords = []
            self.averageAccuracy = 0
            self.personalBest = nil
            return
        }
        
        // Calculate average accuracy
        let totalAccuracySum = matchingRecords.reduce(0) { $0 + $1.accuracyPercentage }
        self.averageAccuracy = totalAccuracySum / matchingRecords.count
        
        // Compute personal best (highest score, highest accuracy)
        self.personalBest = matchingRecords.max { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score < rhs.score
            }
            return lhs.accuracyPercentage < rhs.accuracyPercentage
        }
        
        // Sort according to active tab
        switch selectedTab {
        case .highScores:
            self.displayedRecords = matchingRecords.sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                if lhs.accuracyPercentage != rhs.accuracyPercentage {
                    return lhs.accuracyPercentage > rhs.accuracyPercentage
                }
                if lhs.streakRecord != rhs.streakRecord {
                    return lhs.streakRecord > rhs.streakRecord
                }
                return lhs.completedAt > rhs.completedAt
            }
        case .history:
            self.displayedRecords = matchingRecords.sorted {
                $0.completedAt > $1.completedAt
            }
        }
    }
    
    /// Permanently removes all stored records and updates the UI state.
    public func clearAllHistory() {
        do {
            try scoreStore.clearAll()
            refresh()
        } catch {
            // Graceful fallback: refresh state to match storage
            refresh()
        }
    }
}
