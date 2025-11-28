import SwiftUI
import Combine

@MainActor
class HiKeyboardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isGenerating = false
    @Published var isEditing = false  // When text field is focused
    @Published var errorMessage: String?
    
    // All generated images (cumulative - new ones added to the end)
    @Published var allImages: [GeneratedImage] = []
    
    // MARK: - Computed Properties
    
    var hasResults: Bool {
        !allImages.isEmpty
    }
    
    // MARK: - Dependencies
    
    private let apiClient = APIClient.shared
    private let tokenStorage = AuthTokenStorage.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
    }
    
    // MARK: - Actions
    
    func generate() async {
        guard !prompt.isEmpty else { return }
        
        guard let accessToken = tokenStorage.getAccessToken() else {
            errorMessage = "Not logged in. Open the hi app first."
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let requestID = apiClient.newRequestID()
            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: accessToken
            )
            
            // Create new image entries (pending state)
            let newImages = response.signedUrls.map { url in
                GeneratedImage(url: url, prompt: prompt)
            }
            
            // Append to all images (cumulative)
            allImages.append(contentsOf: newImages)
            
            isGenerating = false
            isEditing = false  // Switch to results view
            
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
            isGenerating = false
        }
    }
    
    func showResults() {
        isEditing = false
    }
    
    func startEditing() {
        isEditing = true
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
