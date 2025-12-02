import SwiftUI
import KeyboardKit
import os

struct HiKeyboardView: View {
    
    let services: Keyboard.Services
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            promptBar
            
            // Show results OR keyboard based on state
            if viewModel.showingResults || viewModel.isGenerating {
                resultsView
            } else {
                KeyboardView(
                    layout: nil,
                    services: services
                )
            }
        }
    }
    
    // MARK: - Prompt Bar
    
    private var promptBar: some View {
        HStack(spacing: 8) {
            // Back button for results
            if viewModel.hasResults && !viewModel.showingResults {
                Button {
                    viewModel.showResults()  // Use the new function
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.001)) // Essentially invisible but tappable
                        .cornerRadius(8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            promptField
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingResults)
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                // Error state
                errorView(message: error)
            } else {
                // Results carousel
                imageCarousel
            }
        }
        .frame(height: 264) // Same as keyboard height
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.generate()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var imageCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Use sortedImages (loaded first, then pending)
                ForEach(viewModel.sortedImages) { image in
                    ImageCard(
                        image: image,
                        onCopy: { viewModel.copyImage(image) },
                        onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) }
                    )
                    .id(image.id)  // Important for SwiftUI to track correctly
                }
                
                if viewModel.isGenerating {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 240, height: 240)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.2)
                            )
                            .shimmer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.3), value: viewModel.sortedImages.map { $0.id })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Prompt Field

    private var promptField: some View {
        HStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Cursor at start - always reserve space so that placeholder doesn't jump
                        BlinkingCursor()
                            .opacity(viewModel.isPromptFocused && viewModel.prompt.isEmpty ? 1 : 0)
                        
                        if viewModel.prompt.isEmpty {
                            Text("Describe an image")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(viewModel.prompt.enumerated()), id: \.offset) { index, character in
                                ZStack(alignment: .leading) {
                                    if viewModel.isPromptFocused && viewModel.cursorPosition == index {
                                        BlinkingCursor()
                                            .id("cursor")
                                    }
                                    
                                    Text(String(character))
                                        .foregroundColor(.primary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.focusPrompt()
                                    viewModel.setCursorPosition(index)
                                }
                            }
                            // Cursor at end (after last character)
                            if viewModel.isPromptFocused && viewModel.cursorPosition == viewModel.prompt.count {
                                BlinkingCursor()
                                    .id("cursor")
                            }
                        }
                    }
                    .padding(.trailing, 24) // Small buffer so text is far from clear-button
                }
                .onChange(of: viewModel.cursorPosition) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("cursor", anchor: .center)
                    }
                }
                .onChange(of: viewModel.prompt) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("cursor", anchor: .center)
                    }
                }
            }
            
            // Clear button
            Button {
                viewModel.clearPrompt()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.leading, 8)
            .opacity(viewModel.prompt.isEmpty || !viewModel.isPromptFocused ? 0 : 1)
            .disabled(viewModel.prompt.isEmpty || !viewModel.isPromptFocused)
        }
        .frame(height: 36)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.focusPrompt()
        }
        .disabled(viewModel.isGenerating)
    }
}

// MARK: - Image Card Component

struct ImageCard: View {
    let image: GeneratedImage
    let onCopy: () -> Void
    let onLoaded: (Data) -> Void  // NEW: callback when loaded
    
    @State private var loadedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 240, height: 240)
                .shimmer()
                .opacity(loadedImage == nil ? 1 : 0)
            
            // Actual image with fade-in
            if let uiImage = loadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            } else {
                ProgressView()
            }
        }
        .frame(width: 240, height: 240)
        .onTapGesture {
            if loadedImage != nil {
                onCopy()
            }
        }
        .task {
            // Skip polling if already loaded (from cache)
            if let data = image.imageData, let uiImage = UIImage(data: data) {
                loadedImage = uiImage
                return
            }
            await loadImage()
        }
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
                        onLoaded(data)  // Report back to ViewModel
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

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Blinking Cursor (existing)

struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2, height: 18)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
