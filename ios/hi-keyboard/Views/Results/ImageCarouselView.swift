import SwiftUI

struct ImageCarouselView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Use sortedImages (loaded first, then pending)
                    ForEach(viewModel.sortedImages) { image in
                        ImageCardView(
                            image: image,
                            onCopy: { viewModel.copyImage(image) },
                            onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) },
                            onTap: { viewModel.openFullscreen(image: image) }
                        )
                        .id(image.id)
                    }
                    
                    if viewModel.isGenerating {
                        ForEach(0..<4, id: \.self) { _ in
                            LoadingPlaceholderView()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.3), value: viewModel.sortedImages.map { $0.id })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Placeholder

struct LoadingPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(width: 200, height: 200)
            .overlay(
                ProgressView()
                    .scaleEffect(1.2)
            )
            .shimmer()
    }
}

