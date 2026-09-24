import SwiftUI

struct ImageCarouselView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel

    var body: some View {
        VStack {
            Spacer()

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.visibleImages, id: \.id) { image in
                            ImageCardView(
                                image: image,
                                onCopy: { viewModel.copyImage(image) },
                                onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) },
                                onTap: { viewModel.openFullscreen(image: image) }
                            )
                            .id(image.id)
                        }

                        if viewModel.isGenerating {
                            ForEach(0..<4, id: \.self) { index in
                                LoadingPlaceholderView()
                                    .id("placeholder-\(index)")
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.visibleImages.map { $0.id })
                }
                .task {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("placeholder-0", anchor: UnitPoint(x: 0.2, y: 0))
                    }
                }
                .onChange(of: viewModel.isGenerating) { _, generating in
                    guard generating else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("placeholder-0", anchor: UnitPoint(x: 0.2, y: 0))
                    }
                }
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
