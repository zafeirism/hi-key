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

            if viewModel.isShowingMenu {
                KeyboardMenuView(viewModel: viewModel)
            } else if viewModel.showingResults || viewModel.isGenerating {
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
                services: services,
                buttonContent: { params in
                    if case .primary(.go) = params.item.action {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                    } else {
                        params.view
                    }
                },
                buttonView: { $0.view },
                collapsedView: { $0.view },
                emojiKeyboard: { $0.view },
                toolbar: { $0.view }
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
