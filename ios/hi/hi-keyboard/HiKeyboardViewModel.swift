import SwiftUI
import Combine

@MainActor
class HiKeyboardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isPromptFocused = false
    @Published var isGenerating = false
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
    
    func appendToPrompt(_ text: String) {
        prompt.append(text)
    }
    
    func deleteLastCharacter() {
        if !prompt.isEmpty {
            prompt.removeLast()
        }
    }
    
    // MARK: - Focus Management
    
    func focusPrompt() {
        isPromptFocused = true
        actionHandler?.isInterceptingInput = true
    }
    
    func unfocusPrompt() {
        isPromptFocused = false
        actionHandler?.isInterceptingInput = false
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
