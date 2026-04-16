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

            // Create new image entries
            let newImages = response.images.map { image in
                GeneratedImage(id: image.id, url: image.signedUrl, prompt: prompt)
            }
            
            let totalAfterAdd = allImages.count + newImages.count
            if totalAfterAdd > maxStoredImages {
                let removeCount = totalAfterAdd - maxStoredImages
                // Remove oldest images (and their data)
                allImages.removeFirst(removeCount)
            }
            
            allImages.append(contentsOf: newImages)
            isGenerating = false
            
        } catch {
            HiLogger.error("Generate failed!", error: error, category: .keyboard)
            errorMessage = error.localizedDescription
            isGenerating = false
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
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isLoaded = true
            allImages[index].loadedAt = Date()
            allImages[index].imageData = data
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
        if let index = sortedImages.firstIndex(where: { $0.id == image.id }) {
            fullscreenImageIndex = index
        }
    }
    
    func closeFullscreen() {
        fullscreenImageIndex = nil
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
