import SwiftUI

/// Main home menu view allowing category selection and game initiation.
public struct HomeView: View {
    @ObservedObject public var viewModel: QuizViewModel
    @State private var selectedCategory: QuizCategory?
    
    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App title banner
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 56))
                            .foregroundColor(.accentColor)
                            .padding(.top, 12)
                        
                        Text("Train-your-Brain")
                            .font(.largeTitle.bold())
                        
                        Text("Software Engineering & iOS Quiz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Quick play button
                    Button(action: {
                        viewModel.startQuiz(category: selectedCategory)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(selectedCategory == nil ? "Start Mixed Quiz" : "Start \(selectedCategory!.displayName)")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 550)
                    
                    // Category Selection Grid
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Select Domain Focus")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // All categories tile
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            HStack {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("All Topics (Mixed)")
                                        .font(.subheadline.bold())
                                    Text("Comprehensive cross-discipline challenge")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedCategory == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedCategory == nil ? Color.accentColor.opacity(0.1) : Color.adaptiveSecondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selectedCategory == nil ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        ForEach(QuizCategory.allCases) { category in
                            let isSelected = selectedCategory == category
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack {
                                    Image(systemName: category.iconName)
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.displayName)
                                            .font(.subheadline.bold())
                                        Text(category.localizedDescription)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.adaptiveSecondaryBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: 550)
                }
                .padding(.bottom, 24)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
