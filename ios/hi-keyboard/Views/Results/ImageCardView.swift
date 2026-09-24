import SwiftUI

struct ImageCardView: View {
    let image: GeneratedImage
    let onCopy: () -> Void
    let onLoaded: (Data) -> Void
    let onTap: () -> Void
    
    // Use weak reference pattern - don't store UIImage in @State
    @State private var loadedImage: UIImage?
    @State private var showCopiedFeedback = false
    @State private var loadTask: Task<Void, Never>?

    private let copyHapticGenerator = UINotificationFeedbackGenerator()
    private let displaySize = CGSize(width: 200, height: 200)
    
    var body: some View {
        ZStack {
            // Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 200, height: 200)
                .shimmer()
                .opacity(loadedImage == nil ? 1 : 0)
            
            // Actual image with fade-in
            if let uiImage = loadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
                    .overlay(alignment: .topTrailing) {
                        copyButton
                    }
                    .onTapGesture {
                        onTap()
                    }
            } else {
                ProgressView()
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            loadImageIfNeeded()
        }
        .onDisappear {
            // CRITICAL: Cancel task and release image when scrolled off screen
            loadTask?.cancel()
            loadTask = nil
            // Only release if we're truly off-screen, not just rebuilding
        }
    }
    
    private var copyButton: some View {
        Button {
            onCopy()
            copyHapticGenerator.notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopiedFeedback = false
                }
            }
        } label: {
            Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                .font(.system(.body, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .padding(8)
        .contentTransition(.symbolEffect(.replace))
    }
    
    private func loadImageIfNeeded() {
        // Already loaded with downsampled image
        if loadedImage != nil { return }

        // Try to load from cached data first (downsampled)
        if let data = image.imageData,
           let downsampled = ImageLoader.downsample(data: data, to: displaySize) {
            loadedImage = downsampled
            // Image visible → user may tap copy. Warm the Taptic Engine.
            copyHapticGenerator.prepare()
            return
        }

        // Need to fetch from network
        loadTask = Task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = URL(string: image.url) else { return }

        // Poll until cancelled. The deadline is owned by the view model
        // (it removes the placeholder after `placeholderTimeout`, which
        // unmounts this card and cancels this task). 2x/sec is enough to
        // feel instant once the bytes are available; the status poller
        // tells the VM about errors out-of-band.
        while !Task.isCancelled {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    // CRITICAL: Downsample immediately, never store full-size UIImage
                    guard let downsampled = ImageLoader.downsample(data: data, to: displaySize) else {
                        continue
                    }

                    await MainActor.run {
                        self.loadedImage = downsampled
                        onLoaded(data) // Store raw data for fullscreen/copy
                        // Image visible → user may tap copy. Warm the Taptic Engine.
                        copyHapticGenerator.prepare()
                    }
                    return
                }
            } catch {
                // Retry silently
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}

