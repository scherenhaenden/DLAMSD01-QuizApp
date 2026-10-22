import SwiftUI

/// Main application entry point for Train-your-Brain.
///
/// Lifecycle & State:
/// - Annotated with `@main` to designate the root execution entry of the iOS application.
/// - Instantiates the single source of truth `QuizViewModel` as a `@StateObject`,
///   preserving game state across view graph re-renders.
@main
public struct TrainYourBrainApp: App {
    @StateObject private var viewModel = QuizViewModel()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

/// Root coordinating container routing between Home, Quiz, and Result screens.
public struct ContentView: View {
    @ObservedObject public var viewModel: QuizViewModel
    
    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                HomeView(viewModel: viewModel)
            case .playing, .answered:
                QuizView(viewModel: viewModel)
            case .finished(let record):
                ResultView(
                    record: record,
                    onPlayAgain: {
                        viewModel.startQuiz(category: record.category)
                    },
                    onBackToMenu: {
                        viewModel.resetToMenu()
                    }
                )
            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Error")
                        .font(.title2.bold())
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.resetToMenu()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}
