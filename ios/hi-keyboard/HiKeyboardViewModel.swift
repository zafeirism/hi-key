import SwiftUI
import Combine

// MARK: - Keyboard Mode

enum KeyboardMode: Equatable {
    case composing              // Typing prompt, showing suggestions + keyboard
    case browsingSuggestions    // Showing category picker instead of keyboard
    case results                // Showing image carousel
}

// MARK: - View Model

@MainActor
class HiKeyboardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isPromptFocused = true
    @Published var isGenerating = false
    @Published var cursorPosition = 0
    @Published var errorMessage: String?
    @Published var showingResults = false
    @Published var showSuggestions = false
    @Published var fullscreenImageIndex: Int?
    @Published var mode: KeyboardMode = .composing

    // All generated images (cumulative)
    @Published var allImages: [GeneratedImage] = []

    // Reference to action handler for syncing focus state
    weak var actionHandler: HiActionHandler?

    // MARK: - Computed Properties

    var hasResults: Bool {
        !allImages.isEmpty
    }

    var isShowingFullscreen: Bool {
        fullscreenImageIndex != nil
    }

    // Images sorted for display: grouped into batches by generation time
    // (oldest batch first), and within each batch by their first-reveal
    // time (loadedAt) — ascending, with not-yet-revealed images last. The
    // loadedAt is persisted across sessions, so restored images keep the
    // original order they were first shown in.
    var sortedImages: [GeneratedImage] {
        let groups = Dictionary(grouping: allImages, by: \.generatedAt)
        return groups.keys.sorted().flatMap { key in
            sortByLoaded(groups[key] ?? [])
        }
    }

    private func sortByLoaded(_ images: [GeneratedImage]) -> [GeneratedImage] {
        images.sorted { lhs, rhs in
            switch (lhs.loadedAt, rhs.loadedAt) {
            case let (l?, r?): return l < r
            case (_?, nil):    return true
            case (nil, _?):    return false
            case (nil, nil):   return false
            }
        }
    }

    // Images the carousel should actually render. A placeholder is only
    // shown while the image still has a reasonable chance to load; once it
    // has aged past `placeholderTimeout` without being loaded, we hide it
    // so stale URLs don't leave lingering shimmer tiles.
    var visibleImages: [GeneratedImage] {
        let now = Date()
        return sortedImages.filter { image in
            image.isLoaded || now.timeIntervalSince(image.generatedAt) < Self.placeholderTimeout
        }
    }
    
    // MARK: - Dependencies
    
    private let apiClient = APIClient.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
        self.showingResults = false
        self.mode = .composing

        hydrateFromStore()
    }

    private func hydrateFromStore() {
        let generations = RecentGenerationsStore.loadValid()
        guard !generations.isEmpty else { return }

        let hydrated: [GeneratedImage] = generations.flatMap { gen in
            gen.images.map {
                GeneratedImage(
                    id: $0.id,
                    url: $0.url,
                    prompt: gen.prompt,
                    generatedAt: gen.generatedAt,
                    loadedAt: $0.loadedAt
                )
            }
        }

        allImages = hydrated

        for image in hydrated {
            startLoadTracking(for: image)
        }

        if let lastPrompt = generations.last?.prompt {
            prompt = lastPrompt
            cursorPosition = lastPrompt.count
        }

        showingResults = true
        mode = .results
        isPromptFocused = false

        HiLogger.info("Hydrated \(hydrated.count) restored images from \(generations.count) generations", category: .keyboard)
    }
    
    // MARK: - Prompt Editing (called by action handler)
    
    func addToPrompt(_ text: String) {
        // Insert at cursor position instead of end
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition)
        prompt.insert(contentsOf: text, at: index)
        setCursorPosition(cursorPosition + text.count)
    }
    
    func deleteCharacter() {
        // Delete character before cursor position
        guard cursorPosition > 0 else { return }
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition - 1)
        prompt.remove(at: index)
        setCursorPosition(cursorPosition - 1)
    }
    
    // MARK: - Cursor Management
    
    func setCursorPosition(_ position: Int) {
        cursorPosition = min(max(0, position), prompt.count)
        autoCapitalizeIfNeeded()
    }
    
    func moveCursorToEnd() {
        setCursorPosition(prompt.count)
    }
    
    func promptUpToCursor() -> String {
        guard cursorPosition > 0 else { return "" }
        
        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition)
        let promptUpToCursor = String(prompt[..<index])
        return promptUpToCursor
    }
    
    // MARK: - Focus Management
    
    func focusPrompt() {
        isPromptFocused = true
        moveCursorToEnd()
        showingResults = false
        mode = .composing
    }
    
    func clearPrompt() {
        prompt = ""
        setCursorPosition(0)
        // Keep focus so user can start typing again
    }
    
    func unfocusPrompt() {
        isPromptFocused = false
    }
    
    // MARK: - Auto-Capitalization Logic
    
    func autoCapitalizeIfNeeded() {
        guard let actionHandler = actionHandler else { return }
        
        let shouldCapitalize = shouldAutoCapitalize()
        actionHandler.autoCapitalize(shouldCapitalize: shouldCapitalize)
    }
    
    private func shouldAutoCapitalize() -> Bool {
        guard cursorPosition > 0 else { return true }
        
        let promptUpToCursor = promptUpToCursor()
        
        let trimmed = promptUpToCursor.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        
        // Capitalize after sentence-ending punctuation followed by space
        if let lastChar = trimmed.last {
            let sentenceEnders: Set<Character> = [".", "!", "?"]
            if sentenceEnders.contains(lastChar) && promptUpToCursor.last == " " {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Generation
    
    private let maxStoredImages = 16
    
    func generate() async {
        guard !prompt.isEmpty else {
            HiLogger.warning("Generate called with empty prompt", category: .keyboard)
            return
        }

        isGenerating = true
        unfocusPrompt()
        showingResults = true
        mode = .results
        errorMessage = nil

        do {
            let requestID = apiClient.newRequestID()

            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID
            )

            HiLogger.info("✅ Got \(response.images.count) urls back for requestID \(requestID)", category: .keyboard)

            let batchGeneratedAt = Date()
            let newImages = response.images.map { image in
                GeneratedImage(
                    id: image.id,
                    url: image.signedUrl,
                    prompt: prompt,
                    generatedAt: batchGeneratedAt
                )
            }

            let totalAfterAdd = allImages.count + newImages.count
            if totalAfterAdd > maxStoredImages {
                let removeCount = totalAfterAdd - maxStoredImages
                allImages.removeFirst(removeCount)
            }

            allImages.append(contentsOf: newImages)

            for image in newImages {
                startLoadTracking(for: image)
            }

            let stored = StoredGeneration(
                prompt: prompt,
                generatedAt: batchGeneratedAt,
                images: newImages.map { StoredImage(id: $0.id, url: $0.url) }
            )
            RecentGenerationsStore.append(stored)

            isGenerating = false

        } catch {
            HiLogger.error("Generate failed!", error: error, category: .keyboard)
            errorMessage = error.localizedDescription
            isGenerating = false
        }
    }

    static let placeholderTimeout: TimeInterval = 120
    private static let staleFetchTimeout: TimeInterval = 30

    /// Fresh images (age < placeholderTimeout) load through `ImageCardView`;
    /// we just schedule a deadline-based removal if they never load. Stale
    /// images (age >= placeholderTimeout) are hidden by `visibleImages`, so
    /// the card never appears to kick off a fetch — we drive the fetch from
    /// here, and remove the image if the fetch never succeeds.
    private func startLoadTracking(for image: GeneratedImage) {
        let age = Date().timeIntervalSince(image.generatedAt)
        if age >= Self.placeholderTimeout {
            fetchStaleImage(imageID: image.id, urlString: image.url)
        } else {
            scheduleRemovalAtDeadline(imageID: image.id, delay: Self.placeholderTimeout - age)
        }
    }

    private func scheduleRemovalAtDeadline(imageID: String, delay: TimeInterval) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self,
                  let idx = self.allImages.firstIndex(where: { $0.id == imageID }),
                  !self.allImages[idx].isLoaded
            else { return }
            self.allImages.remove(at: idx)
            HiLogger.info("Removed fresh image placeholder at deadline", category: .keyboard)
        }
    }

    private func fetchStaleImage(imageID: String, urlString: String) {
        Task { [weak self] in
            guard let url = URL(string: urlString) else { return }

            let deadline = Date().addingTimeInterval(Self.staleFetchTimeout)
            while Date() < deadline {
                guard !Task.isCancelled else { return }

                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                        guard let self,
                              let idx = self.allImages.firstIndex(where: { $0.id == imageID })
                        else { return }
                        self.allImages[idx].isLoaded = true
                        if self.allImages[idx].loadedAt == nil {
                            self.allImages[idx].loadedAt = Date()
                        }
                        self.allImages[idx].imageData = data

                        if let loadedAt = self.allImages[idx].loadedAt {
                            RecentGenerationsStore.updateLoadedAt(imageID: imageID, loadedAt: loadedAt)
                        }
                        return
                    }
                } catch {
                    // Retry silently
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            // Fetch failed — drop the image so it doesn't linger invisibly.
            guard let self,
                  let idx = self.allImages.firstIndex(where: { $0.id == imageID }),
                  !self.allImages[idx].isLoaded
            else { return }
            self.allImages.remove(at: idx)
            HiLogger.info("Stale image fetch timed out; removed", category: .keyboard)
        }
    }
    
    // MARK: - Image Actions
    
    func copyImage(_ image: GeneratedImage) {
        guard let data = image.imageData, let watermarkedImage = Watermark.add(to: data)
        else { return }

        UIPasteboard.general.image = watermarkedImage
        HiLogger.info("Image copied to pasteboard: \(image.url)")
        markAsCopied(image.id)

        Task {
            try? await apiClient.reportCopy(generationId: image.id)
        }
    }
    
    func markImageLoaded(_ imageID: String, data: Data) {
        guard let index = allImages.firstIndex(where: { $0.id == imageID }) else { return }

        allImages[index].isLoaded = true
        if allImages[index].loadedAt == nil {
            // Only stamp loadedAt on the first reveal. Restored images carry
            // their original loadedAt from storage, and we preserve it so the
            // within-batch order stays stable across sessions.
            allImages[index].loadedAt = Date()
        }
        allImages[index].imageData = data

        if let loadedAt = allImages[index].loadedAt {
            RecentGenerationsStore.updateLoadedAt(imageID: imageID, loadedAt: loadedAt)
        }
    }
    
    private func markAsCopied(_ imageID: String) {
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isCopied = true
        }
    }
    
    // MARK: - Navigation
    
    func showResults() {
        isPromptFocused = false
        showingResults = true
        mode = .results
    }
    
    func openFullscreen(image: GeneratedImage) {
        if let index = visibleImages.firstIndex(where: { $0.id == image.id }) {
            fullscreenImageIndex = index
        }
    }

    func closeFullscreen() {
        fullscreenImageIndex = nil
    }

    func navigateToImage(index: Int) {
        guard index >= 0 && index < visibleImages.count else { return }
        fullscreenImageIndex = index
    }

    // MARK: - Mode Switching

    func toggleCategoryPicker() {
        if mode == .browsingSuggestions {
            mode = .composing
        } else {
            mode = .browsingSuggestions
        }
    }
}
