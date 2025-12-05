import SwiftUI

struct FullscreenImageView: View {
    let images: [GeneratedImage]
    let currentIndex: Int
    let onClose: () -> Void
    let onCopy: (GeneratedImage) -> Void
    let onNavigate: (Int) -> Void
    
    @State private var selectedIndex: Int = 0
    @State private var showCopiedFeedback = false
    
    private var currentImage: GeneratedImage? {
        guard selectedIndex >= 0 && selectedIndex < images.count else { return nil }
        return images[selectedIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Single UIKit component handles everything
            ImageGalleryViewController(
                images: images,
                currentIndex: currentIndex,
                onPageChange: { index in
                    selectedIndex = index
                    onNavigate(index)
                }
            )
            .ignoresSafeArea()
            
            // Top bar overlay
            topBar
        }
        .onAppear { selectedIndex = currentIndex }
    }
    
    private var topBar: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                if let image = currentImage {
                    copyButton(for: image)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Spacer()
        }
    }
    
    private var closeButton: some View {
        Button { onClose() } label: {
            Image(systemName: "xmark")
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    private func copyButton(for image: GeneratedImage) -> some View {
        Button {
            onCopy(image)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { showCopiedFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showCopiedFeedback = false }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                    .contentTransition(.symbolEffect(.replace))
                Text(showCopiedFeedback ? "Copied" : "Copy")
            }
            .font(.system(.headline, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
        }
    }
}

