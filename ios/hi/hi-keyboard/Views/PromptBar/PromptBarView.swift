import SwiftUI

struct PromptBarView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            if viewModel.hasResults && !viewModel.showingResults {
                backButton
            }
            
            PromptFieldView(viewModel: viewModel)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingResults)
    }
    
    private var backButton: some View {
        Button {
            viewModel.showResults()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.001))
                .cornerRadius(8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }
}

