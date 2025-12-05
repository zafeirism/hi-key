import SwiftUI
import KeyboardKit

struct HiKeyboardView: View {
    
    let services: Keyboard.Services
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        ZStack {
            mainContent
                .opacity(viewModel.isShowingFullscreen ? 0 : 1)
            
            if viewModel.isShowingFullscreen {
                FullscreenImageView(
                    images: viewModel.sortedImages,
                    currentIndex: viewModel.fullscreenImageIndex ?? 0,
                    onClose: { viewModel.closeFullscreen() },
                    onCopy: { viewModel.copyImage($0) },
                    onNavigate: { viewModel.navigateToImage(index: $0) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isShowingFullscreen)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            PromptBarView(viewModel: viewModel)//.border(.red)
            
            if viewModel.showingResults || viewModel.isGenerating {
                ResultsView(viewModel: viewModel)
            } else if viewModel.showSuggestions {
                CategoryPickerView(viewModel: viewModel)
            } else {
                KeyboardArea
            }
        }
    }
    
    // MARK: - Keyboard Area
    
    @ViewBuilder
    private var KeyboardArea: some View {
        ZStack {
            // Future: Toggle between KeyboardView and CategoryPickerView

            // based on viewModel.mode or a toggle button
            KeyboardView(
                layout: nil,
                services: services
            )
                        
            VStack {
                SuggestionBarView(viewModel: viewModel)
                
                Spacer()
            }
            
        }
    }
}
