import SwiftUI
import Combine
import os

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
    @Published var isPromptFocused = false
    @Published var isGenerating = false
    @Published var cursorPosition = 0
    @Published var errorMessage: String?
    @Published var showingResults = false
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
    
    // Computed property: images sorted by load time (loaded first, then pending)
    var sortedImages: [GeneratedImage] {
        let loaded = allImages.filter { $0.isLoaded }.sorted { 
            ($0.loadedAt ?? .distantPast) < ($1.loadedAt ?? .distantPast) 
        }
        let pending = allImages.filter { !$0.isLoaded }
        return loaded + pending
    }
    
    // MARK: - Dependencies
    
    private let apiClient = APIClient.shared
    private let tokenStorage = AuthTokenStorage.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
        self.showingResults = false
        self.mode = .composing
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
    
    // MARK: - Focus Management
    
    func focusPrompt() {
        isPromptFocused = true
        actionHandler?.isInterceptingInput = true
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
        actionHandler?.isInterceptingInput = false
    }

    // MARK: - Auto-Capitalization Logic

    func autoCapitalizeIfNeeded() {
        guard let actionHandler = actionHandler else { return }
        
        let shouldCapitalize = shouldAutoCapitalize()
        actionHandler.autoCapitalize(shouldCapitalize: shouldCapitalize)
    }

    private func shouldAutoCapitalize() -> Bool {
        guard cursorPosition > 0 else { return true }

        let index = prompt.index(prompt.startIndex, offsetBy: cursorPosition)
        let promptUpToCursor = String(prompt[..<index])

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
    
    func generate() async {
        HiLogger.api.info("🚀 Generate called with prompt: \(self.prompt)")
        
        guard !prompt.isEmpty else {
            HiLogger.api.warning("⚠️ Generate called with empty prompt")
            return
        }
        
        guard let accessToken = tokenStorage.getAccessToken() else {
            HiLogger.api.error("❌ No access token found - user not logged in")
            errorMessage = "Not logged in. Open the hi app first."
            return
        }
        
        HiLogger.api.info("✅ Access token found, starting generation")
        isGenerating = true
        unfocusPrompt()
        showingResults = true
        mode = .results
        errorMessage = nil
        
        do {
            let requestID = apiClient.newRequestID()
            HiLogger.api.info("📡 Calling API with requestID: \(requestID)")
            
            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: accessToken
            )
            
            HiLogger.api.info("✅ Got \(response.signedUrls.count) urls back")
            
            // Create new image entries
            let newImages = response.signedUrls.map { url in
                GeneratedImage(url: url, prompt: prompt)
            }
            
            // Append to all images (cumulative)
            allImages.append(contentsOf: newImages)
            isGenerating = false
            
        } catch {
            HiLogger.api.error("❌ Generate failed: \(error.localizedDescription)")
            errorMessage = "Failed: \(error.localizedDescription)"
            isGenerating = false
        }
    }
    
    // MARK: - Image Actions
    
    func copyImage(_ image: GeneratedImage) {
        HiLogger.ui.info("📋 Copying image to pasteboard: \(image.url)")
        
        Task {
            guard let url = URL(string: image.url),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let uiImage = UIImage(data: data) else {
                HiLogger.ui.error("❌ Failed to load image for copy")
                return
            }
            
            await MainActor.run {
                UIPasteboard.general.image = uiImage
                HiLogger.ui.info("✅ Image copied to pasteboard")
                
                // Mark as copied for UI feedback
                if let index = allImages.firstIndex(where: { $0.id == image.id }) {
                    allImages[index].isCopied = true
                }
            }
        }
    }

    func markImageLoaded(_ imageID: UUID, data: Data) {
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isLoaded = true
            allImages[index].loadedAt = Date()
            allImages[index].imageData = data
            HiLogger.ui.info("✅ Image loaded: \(imageID)")
        }
    }

    // MARK: - Navigation

    func showResults() {
        HiLogger.ui.info("⬅️ Back button tapped - showing results")
        isPromptFocused = false
        actionHandler?.isInterceptingInput = false
        showingResults = true
        mode = .results
    }

    func openFullscreen(image: GeneratedImage) {
        if let index = sortedImages.firstIndex(where: { $0.id == image.id }) {
            fullscreenImageIndex = index
            HiLogger.ui.info("🔍 Opened fullscreen for image at index \(index)")
        }
    }

    func closeFullscreen() {
        fullscreenImageIndex = nil
        HiLogger.ui.info("✖️ Closed fullscreen view")
    }

    func navigateToImage(index: Int) {
        guard index >= 0 && index < sortedImages.count else { return }
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
