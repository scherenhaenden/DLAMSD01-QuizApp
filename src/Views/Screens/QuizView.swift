import SwiftUI

/// Core gameplay view where the user answers questions against the timer.
///
/// Interaction Design & Flow:
/// - Header displaying active streak indicator with fire badge, running score tally, and close button.
/// - Dynamic countdown timer bar animating horizontally with color shifts as deadline approaches.
/// - Question card rendering the category chip, question counter, and prompt text.
/// - 4 multiple choice buttons with immediate chromatic feedback upon tap.
/// - Bottom explanation sheet revealing the pedagogical rationale and advance action button.
public struct QuizView: View {
    @ObservedObject public var viewModel: QuizViewModel
    
    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header: score, timer, and streak
            HStack {
                Button(action: {
                    viewModel.resetToMenu()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("quiz.close")
                
                Spacer()
                
                // Streak indicator badge (displays only when streak >= 2)
                if viewModel.streak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.streak) Streak")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Current score display
                VStack(alignment: .trailing) {
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.currentScore)")
                        .font(.headline.monospacedDigit())
                }
            }
            .padding(.horizontal)
            
            // Countdown timer bar
            if case .playing = viewModel.viewState {
                TimerBar(
                    timeRemaining: viewModel.timeRemaining,
                    totalTime: viewModel.currentQuestion?.difficulty.timeLimitSeconds ?? 15.0
                )
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    if let question = viewModel.currentQuestion {
                        // Question card
                        QuestionCard(
                            question: question,
                            questionNumber: viewModel.questionIndex + 1,
                            totalQuestions: viewModel.totalQuestions
                        )
                        
                        // Option buttons
                        VStack(spacing: 12) {
                            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                let isSelected = viewModel.selectedAnswerIndex == index
                                let isAnswerRevealed = viewModel.selectedAnswerIndex != nil
                                let isCorrect = isAnswerRevealed ? (index == question.correctAnswerIndex) : nil
                                
                                AnswerButton(
                                    optionText: option,
                                    index: index,
                                    isSelected: isSelected,
                                    isCorrectAnswer: isCorrect,
                                    isAnswerRevealed: isAnswerRevealed
                                ) {
                                    viewModel.selectAnswer(at: index)
                                }
                            }
                        }
                        
                        // Pedagogical explanation on answer reveal (Immediate Feedback Principle)
                        if case .answered(_, let isCorrect) = viewModel.viewState {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: isCorrect ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(isCorrect ? .quizCorrectFeedback : .quizIncorrectFeedback)
                                    Text(isCorrect ? "Correct!" : "Incorrect")
                                        .font(.headline)
                                        .foregroundColor(isCorrect ? .quizCorrectFeedback : .quizIncorrectFeedback)
                                }
                                
                                Text(question.explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(3)
                                
                                Button(action: {
                                    viewModel.nextQuestion()
                                }) {
                                    Text(viewModel.questionIndex + 1 < viewModel.totalQuestions ? "Next Question" : "View Results")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .accessibilityIdentifier("quiz.advance")
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.adaptiveTertiaryBackground)
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: 600) // Constrained max width for iPad 9th gen ergonomics
        .onChange(of: viewModel.viewState) { _, newState in
            guard case .answered = newState else { return }
            announceAnswerFeedback(for: newState)
        }
    }

    private func announceAnswerFeedback(for state: QuizViewModel.ViewState) {
        #if os(iOS)
        guard case let .answered(selectedIndex, isCorrect) = state,
              let question = viewModel.currentQuestion else { return }

        let message: String
        if selectedIndex < 0 {
            message = "Time is up. The correct answer is \(question.correctAnswerText). Your score is \(viewModel.currentScore) points."
        } else if isCorrect {
            message = "Correct. Your score is \(viewModel.currentScore) points."
        } else {
            message = "Incorrect. The correct answer is \(question.correctAnswerText). Your score is \(viewModel.currentScore) points."
        }

        AccessibilityNotification.Announcement(message).post()
        #endif
    }
}
