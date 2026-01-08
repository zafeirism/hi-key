import SwiftUI
import Combine

// MARK: - Demo View Model

/// Simplified version of HiKeyboardViewModel for the main app demo experience.
/// Removes keyboard-specific dependencies while keeping core generation functionality.
@MainActor
class DemoViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var prompt = ""
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showingResults = false
    
    // All generated images (cumulative)
    @Published var allImages: [GeneratedImage] = []
    
    // MARK: - Computed Properties
    
    var hasResults: Bool {
        !allImages.isEmpty
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
    private let onboardingManager = OnboardingManager.shared
    private var sessionID: String
    
    // MARK: - Init
    
    init() {
        self.sessionID = apiClient.newSessionID()
    }
    
    // MARK: - Prompt Management
    
    func clearPrompt() {
        prompt = ""
    }
    
    func setPrompt(_ text: String) {
        prompt = text
    }
    
    // MARK: - Generation
    
    private let maxStoredImages = 12
    
    func generate() async {
        guard !prompt.isEmpty else {
            HiLogger.warning("Generate called with empty prompt", category: .app)
            return
        }
        
        guard onboardingManager.canGenerateDemo else {
            errorMessage = "You've used all demo generations. Continue to subscribe!"
            return
        }
        
        isGenerating = true
        showingResults = true
        errorMessage = nil
        
        do {
            let requestID = apiClient.newRequestID()
            
            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID
            )
            
            HiLogger.info("✅ Got \(response.signedUrls.count) urls back for requestID \(requestID)", category: .app)
            
            // Create new image entries
            let newImages = response.signedUrls.map { url in
                GeneratedImage(url: url, prompt: prompt)
            }
            
            let totalAfterAdd = allImages.count + newImages.count
            if totalAfterAdd > maxStoredImages {
                let removeCount = totalAfterAdd - maxStoredImages
                allImages.removeFirst(removeCount)
            }
            
            allImages.append(contentsOf: newImages)
            isGenerating = false
            
            // Increment demo generation counter
            onboardingManager.incrementDemoGeneration()
            
        } catch {
            HiLogger.error("Generate failed!", error: error, category: .app)
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
    }
    
    func markImageLoaded(_ imageID: UUID, data: Data) {
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isLoaded = true
            allImages[index].loadedAt = Date()
            allImages[index].imageData = data
        }
    }
    
    private func markAsCopied(_ imageID: UUID) {
        if let index = allImages.firstIndex(where: { $0.id == imageID }) {
            allImages[index].isCopied = true
        }
    }
    
    // MARK: - Navigation
    
    func hideResults() {
        showingResults = false
    }
    
    func showResultsView() {
        showingResults = true
    }
}

