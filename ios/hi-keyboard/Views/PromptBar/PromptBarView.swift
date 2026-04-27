import SwiftUI

struct PromptBarView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel

    var body: some View {
        HStack(spacing: 8) {
            if viewModel.hasResults && !viewModel.showingResults && !viewModel.isShowingMenu {
                backButton
            }

            PromptFieldView(viewModel: viewModel)

            menuButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingResults)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isShowingMenu)
    }

    private var backButton: some View {
        Button {
            viewModel.showResults()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(.title3, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.001))
                .cornerRadius(8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    private var menuButton: some View {
        Button {
            viewModel.toggleMenu()
        } label: {
            ZStack {
                Image(systemName: "slider.horizontal.3")
                    .opacity(viewModel.isShowingMenu ? 0 : 1)
                Image(systemName: "xmark")
                    .opacity(viewModel.isShowingMenu ? 1 : 0)
            }
            .font(.system(.title3, weight: .medium))
            .foregroundColor(.primary)
            .frame(width: 36, height: 36)
            .background(Color.white.opacity(0.001))
            .cornerRadius(8)
            .animation(.easeOut(duration: 0.12), value: viewModel.isShowingMenu)
        }
    }
}

