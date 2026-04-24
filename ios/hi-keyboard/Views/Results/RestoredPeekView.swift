import SwiftUI

/// A faded, narrow peek at the most recent restored image, shown to the left
/// of newly-generated images after the user has generated in this session.
/// Tapping expands the carousel to reveal all restored images.
struct RestoredPeekView: View {
    let image: GeneratedImage
    let onTap: () -> Void

    @State private var loadedImage: UIImage?
    @State private var loadTask: Task<Void, Never>?

    private let peekWidth: CGFloat = 100
    private let fullHeight: CGFloat = 200
    private let fullWidth: CGFloat = 200

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: peekWidth, height: fullHeight)
                    .shimmer()
                    .opacity(loadedImage == nil ? 1 : 0)

                if let uiImage = loadedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: fullWidth, height: fullHeight, alignment: .leading)
                        .clipped()
                        .frame(width: peekWidth, height: fullHeight, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .saturation(0.3)
                        .opacity(0.5)
                        .transition(.opacity.animation(.easeIn(duration: 0.3)))
                }

                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .padding(8)
            }
            .frame(width: peekWidth, height: fullHeight)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onAppear { loadIfNeeded() }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadIfNeeded() {
        guard loadedImage == nil else { return }

        if let data = image.imageData,
           let downsampled = ImageLoader.downsample(data: data, to: CGSize(width: fullWidth, height: fullHeight)) {
            loadedImage = downsampled
            return
        }

        loadTask = Task { await fetchImage() }
    }

    private func fetchImage() async {
        guard let url = URL(string: image.url) else { return }

        for _ in 1...200 {
            guard !Task.isCancelled else { return }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    guard let downsampled = ImageLoader.downsample(
                        data: data,
                        to: CGSize(width: fullWidth, height: fullHeight)
                    ) else { continue }

                    await MainActor.run {
                        self.loadedImage = downsampled
                    }
                    return
                }
            } catch {
                // Retry silently
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }
}
