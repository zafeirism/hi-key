import SwiftUI
import Combine

@MainActor
class HiKeyboardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isPromptFocused = false
    @Published var isGenerating = false
    @Published var cursorPosition = 0
    @Published var errorMessage: String?
    
    // All generated images (cumulative)
    @Published var allImages: [GeneratedImage] = []
    
    // Reference to action handler for syncing focus state
    weak var actionHandler: HiActionHandler?
    
    // MARK: - Computed Properties
    
    var hasResults: Bool {
        !allImages.isEmpty
    }
    
    var showingResults: Bool {
        hasResults && !isPromptFocused
    }
    
    // MARK: - Dependencies
    
    private let apiClient = APIClient.shared
    private let tokenStorage = AuthTokenStorage.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
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
        guard cursorPosition > 0 else { return true}

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
    
    // MARK: - Actions
    
    func generate() async {
        guard !prompt.isEmpty else { return }
        
        guard let accessToken = tokenStorage.getAccessToken() else {
            errorMessage = "Not logged in. Open the hi app first."
            return
        }
        
        isGenerating = true
        unfocusPrompt()  // Switch to results view
        errorMessage = nil
        
        do {
            let requestID = apiClient.newRequestID()
            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: accessToken
            )
            
            // Create new image entries
            let newImages = response.signedUrls.map { url in
                GeneratedImage(url: url, prompt: prompt)
            }
            
            // Append to all images (cumulative)
            allImages.append(contentsOf: newImages)
            isGenerating = false
            
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
            isGenerating = false
        }
    }
    
    func copyImage(_ image: GeneratedImage) {
        // TODO: Implement actual copy to pasteboard
        print("Copy image: \(image.url)")
    }
}

// MARK: - Models

struct GeneratedImage: Identifiable {
    let id = UUID()
    let url: String
    let prompt: String
    var isCopied = false
}
