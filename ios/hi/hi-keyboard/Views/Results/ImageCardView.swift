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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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
            return
        }
        
        // Need to fetch from network
        loadTask = Task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = URL(string: image.url) else { return }
        
        // Polling: 4 times/sec for max 50 sec
        for _ in 1...200 {
            guard !Task.isCancelled else { return }
            
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

