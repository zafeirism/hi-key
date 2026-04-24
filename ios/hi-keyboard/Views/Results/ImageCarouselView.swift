import SwiftUI

struct ImageCarouselView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel

    private var showsPeek: Bool {
        viewModel.hasRestoredImages
            && !viewModel.restoredSectionExpanded
            && (!viewModel.newImages.isEmpty || viewModel.isGenerating)
    }

    private var carouselImages: [GeneratedImage] {
        let base = viewModel.visibleImages
        return showsPeek ? base.filter { !$0.isRestored } : base
    }

    private var firstNewImageID: String? {
        viewModel.newImages.first.map { $0.id }
    }

    private var lastRestoredImageID: String? {
        viewModel.restoredImages.last.map { $0.id }
    }

    var body: some View {
        VStack {
            Spacer()

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if showsPeek, let peekImage = viewModel.restoredImages.last {
                            RestoredPeekView(image: peekImage) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.unlockRestoredSection()
                                }
                            }
                            .id("restored-peek")
                        }

                        ForEach(Array(carouselImages.enumerated()), id: \.element.id) { index, image in
                            ImageCardView(
                                image: image,
                                onCopy: { viewModel.copyImage(image) },
                                onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) },
                                onTap: { viewModel.openFullscreen(image: image) }
                            )
                            .id(image.id)

                            if shouldShowDividerAfter(index: index, in: carouselImages) {
                                RestoredSectionDivider()
                            }
                        }

                        if viewModel.isGenerating {
                            ForEach(0..<4, id: \.self) { index in
                                LoadingPlaceholderView()
                                    .id("placeholder-\(index)")
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .animation(.easeInOut(duration: 0.3), value: carouselImages.map { $0.id })
                    .animation(.easeInOut(duration: 0.25), value: showsPeek)
                }
                .task {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("placeholder-0", anchor: UnitPoint(x: 0.2, y: 0))
                    }
                }
                .onChange(of: viewModel.isGenerating) { _, generating in
                    // When generation starts, anchor the scroll to the
                    // leftmost content so the peek (if any) and the first
                    // placeholders are visible together.
                    guard generating else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if showsPeek {
                            proxy.scrollTo("restored-peek", anchor: .leading)
                        } else {
                            proxy.scrollTo("placeholder-0", anchor: UnitPoint(x: 0.2, y: 0))
                        }
                    }
                }
                .onChange(of: viewModel.restoredSectionExpanded) { _, expanded in
                    // When the user taps the peek, reveal the restored
                    // section but keep the first new image roughly in place —
                    // shift just enough that the last restored image pokes
                    // ~20pt out of the left edge as a "scroll for more" hint.
                    guard expanded else { return }
                    let target = firstNewImageID ?? lastRestoredImageID
                    guard let target else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(target, anchor: UnitPoint(x: 0.25, y: 0))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Show a divider immediately after the last restored image when the
    /// carousel is fully expanded and both restored and new images exist.
    private func shouldShowDividerAfter(index: Int, in images: [GeneratedImage]) -> Bool {
        guard viewModel.restoredSectionExpanded,
              viewModel.hasRestoredImages,
              !viewModel.newImages.isEmpty
        else { return false }

        let image = images[index]
        guard image.isRestored else { return false }

        let next = index + 1
        return next >= images.count || !images[next].isRestored
    }
}

// MARK: - Restored Section Divider

struct RestoredSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1, height: 140)
            .padding(.horizontal, 4)
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
