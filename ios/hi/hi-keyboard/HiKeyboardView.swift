import SwiftUI
import KeyboardKit
import os

struct HiKeyboardView: View {
    
    let services: Keyboard.Services
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        ZStack {
            // Regular keyboard view
            VStack(spacing: 0) {
                promptBar
                
                if viewModel.showingResults || viewModel.isGenerating {
                    resultsView
                } else {
                    KeyboardView(
                        layout: nil,
                        services: services
                    )
                }
            }
            .opacity(viewModel.isShowingFullscreen ? 0 : 1)
            
            // Fullscreen overlay
            if viewModel.isShowingFullscreen {
                FullscreenImageView(
                    images: viewModel.sortedImages,
                    currentIndex: viewModel.fullscreenImageIndex ?? 0,
                    onClose: { viewModel.closeFullscreen() },
                    onCopy: { viewModel.copyImage($0) },
                    onNavigate: { viewModel.navigateToImage(index: $0) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isShowingFullscreen)
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.001)) // Essentially invisible but tappable
                        .cornerRadius(8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            promptField
        }
        .padding(.horizontal, 8)
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
        VStack {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Use sortedImages (loaded first, then pending)
                    ForEach(viewModel.sortedImages) { image in
                        ImageCard(
                            image: image,
                            onCopy: { viewModel.copyImage(image) },
                            onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) },
                            onTap: { viewModel.openFullscreen(image: image) }
                        )
                        .id(image.id)  // Important for SwiftUI to track correctly
                    }
                    
                    if viewModel.isGenerating {
                        ForEach(0..<4, id: \.self) { index in
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
                }
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.3), value: viewModel.sortedImages.map { $0.id })
            }
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .padding(8)
        .contentTransition(.symbolEffect(.replace))  // Smooth icon transition
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

// MARK: - Fullscreen Image View (Simplified)

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
            VStack {
                HStack {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if let image = currentImage {
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
            }
        }
        .onAppear { selectedIndex = currentIndex }
    }
}

// MARK: - Image Gallery (UIPageViewController wrapper)

struct ImageGalleryViewController: UIViewControllerRepresentable {
    let images: [GeneratedImage]
    let currentIndex: Int
    let onPageChange: (Int) -> Void
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        pageVC.view.backgroundColor = .clear
        
        // Set initial page
        if let initialVC = context.coordinator.viewController(for: currentIndex) {
            pageVC.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        
        return pageVC
    }
    
    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        context.coordinator.images = images
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(images: images, onPageChange: onPageChange)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var images: [GeneratedImage]
        let onPageChange: (Int) -> Void
        
        init(images: [GeneratedImage], onPageChange: @escaping (Int) -> Void) {
            self.images = images
            self.onPageChange = onPageChange
        }
        
        func viewController(for index: Int) -> ZoomableImageVC? {
            guard index >= 0 && index < images.count else { return nil }
            let vc = ZoomableImageVC()
            vc.index = index
            vc.image = images[index]
            return vc
        }
        
        func pageViewController(_ pageVC: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let zoomVC = vc as? ZoomableImageVC else { return nil }
            return viewController(for: zoomVC.index - 1)
        }
        
        func pageViewController(_ pageVC: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let zoomVC = vc as? ZoomableImageVC else { return nil }
            return viewController(for: zoomVC.index + 1)
        }
        
        func pageViewController(_ pageVC: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let zoomVC = pageVC.viewControllers?.first as? ZoomableImageVC else { return }
            onPageChange(zoomVC.index)
        }
    }
}

// MARK: - Zoomable Image View Controller (Pure UIKit)

class ZoomableImageVC: UIViewController, UIScrollViewDelegate {
    var index: Int = 0
    var image: GeneratedImage?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup scroll view
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        // Setup image view
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        
        // Load image
        if let data = image?.imageData {
            imageView.image = UIImage(data: data)
        }
        
        // Double-tap gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = view.bounds.size
        imageView.frame = view.bounds
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center image when smaller than scroll view
        let boundsSize = scrollView.bounds.size
        var frame = imageView.frame
        
        frame.origin.x = frame.width < boundsSize.width ? (boundsSize.width - frame.width) / 2 : 0
        frame.origin.y = frame.height < boundsSize.height ? (boundsSize.height - frame.height) / 2 : 0
        
        imageView.frame = frame
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let size = CGSize(width: view.bounds.width / 2.5, height: view.bounds.height / 2.5)
            let origin = CGPoint(x: location.x - size.width / 2, y: location.y - size.height / 2)
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
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

// MARK: - Blinking Cursor

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
