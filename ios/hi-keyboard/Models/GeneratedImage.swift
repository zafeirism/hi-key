import Foundation

struct GeneratedImage: Identifiable {
    let id: String
    let url: String
    let prompt: String
    let generatedAt: Date
    var isCopied = false
    var isLoaded = false
    var loadedAt: Date?
    var imageData: Data?
}

