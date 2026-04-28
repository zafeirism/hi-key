import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    viewModel.dismissError()
                }
            } else {
                ZStack{
                    ImageCarouselView(viewModel: viewModel)

                    VStack{
                        StatusBarView(transientMessage: viewModel.transientStatusMessage)
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 274) // Same as keyboard height (in iOS 26)
    }
}

