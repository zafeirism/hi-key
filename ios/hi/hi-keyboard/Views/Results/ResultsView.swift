import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.generate() }
                }
            } else {
                // Future: StatusBarView goes here
                ImageCarouselView(viewModel: viewModel)
            }
        }
        .frame(height: 264) // Same as keyboard height
    }
}

