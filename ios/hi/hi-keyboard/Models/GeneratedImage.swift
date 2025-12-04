import Foundation

struct GeneratedImage: Identifiable {
    let id = UUID()
    let url: String
    let prompt: String
    var isCopied = false
    var isLoaded = false
    var loadedAt: Date?
    var imageData: Data?
}

