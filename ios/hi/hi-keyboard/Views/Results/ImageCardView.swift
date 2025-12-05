import SwiftUI
import os

struct ImageCardView: View {
    let image: GeneratedImage
    let onCopy: () -> Void
    let onLoaded: (Data) -> Void
    let onTap: () -> Void
    
    @State private var loadedImage: UIImage?
    @State private var showCopiedFeedback = false
    
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
        .task {
            // Skip polling if already loaded (from cache)
            if let data = image.imageData, let uiImage = UIImage(data: data) {
                loadedImage = uiImage
                return
            }
            await loadImage()
        }
    }
    
    private var copyButton: some View {
        Button {
            onCopy()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Show checkmark feedback
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = true
            }
            
            // Revert after 3 seconds
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
    
    private func loadImage() async {
        guard let url = URL(string: image.url) else { return }
        
        // Polling: 4 times/sec for max 50 sec
        for _ in 1...200 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = uiImage
                        onLoaded(data)
                    }
                    return
                }
            } catch {
                // Silence individual attempt failures, just retry
            }
            
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        HiLogger.api.error("❌ Image failed to load after 50 seconds: \(image.url)")
    }
}

