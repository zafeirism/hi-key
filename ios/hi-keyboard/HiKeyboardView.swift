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
                    images: viewModel.visibleImages,
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
            PromptBarView(viewModel: viewModel)
            
            if viewModel.showingResults || viewModel.isGenerating {
                ResultsView(viewModel: viewModel)
            } else {
                KeyboardArea
            }
        }
    }
    
    // MARK: - Keyboard Area
    
    @ViewBuilder
    private var KeyboardArea: some View {
        ZStack {
            KeyboardView(
                layout: nil,
                services: services
            )
            .keyboardButtonStyle{params in
                var style = params.standardStyle()
                style.fontWeight = .regular
                return style
            }
            // TODO: Uncomment this to hide keyboard effects when screen recording for videos
            // .keyboardCalloutStyle(
            //     .init(
            //         backgroundColor: .clear,
            //         borderColor: .clear,
            //         foregroundColor: .clear,
            //         shadowColor: .clear,
            //         shadowRadius: 0
            //     )
            // )
            
            VStack {
                SuggestionBarView(viewModel: viewModel)
                
                Spacer()
            }
            
        }
    }
}
