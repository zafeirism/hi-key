import SwiftUI
import Combine

// MARK: - Settings Manager

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let appGroupID = "group.ai.hi-key"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Published State
    
    @Published var randomStylesEnabled: Bool = true {
        didSet {
            userDefaults?.set(randomStylesEnabled, forKey: Keys.randomStylesEnabled)
        }
    }
    
    @Published var enabledStyles: Set<String> = [] {
        didSet {
            userDefaults?.set(Array(enabledStyles), forKey: Keys.enabledStyles)
        }
    }
    
    @Published var customStyles: [String] = [] {
        didSet {
            userDefaults?.set(customStyles, forKey: Keys.customStyles)
        }
    }

    @Published var removeWatermarkEnabled: Bool = false {
        didSet {
            userDefaults?.set(removeWatermarkEnabled, forKey: Keys.removeWatermarkEnabled)
        }
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let randomStylesEnabled = "randomStylesEnabled"
        static let enabledStyles = "enabledStyles"
        static let customStyles = "customStyles"
        static let removeWatermarkEnabled = "removeWatermarkEnabled"
    }
    
    // MARK: - Default Styles
    
    /// All available built-in styles from PromptCategories
    static let defaultStyles: [String] = [
        "Watercolor", "Oil painting", "Pastel", "Charcoal", "Comic book", "Manga",
        "Graphic novel", "Pixar-like", "Ghibli-like", "Disney Renaissance", "90s anime",
        "Impressionist", "Surrealist", "Expressionist", "Pop art", "Vaporwave",
        "Synthwave", "Cyberpunk", "Steampunk", "Photorealistic", "Cinematic",
        "Documentary", "Analog film", "Retro poster", "Minimalism", "Low poly",
        "Pixel art", "Sketch", "Realism", "Hyperrealism", "Baroque", "Rococo",
        "Art Nouveau", "Art Deco", "Cubism", "Fauvism", "Ukiyo-e", "Noir",
        "Film noir", "Neon noir", "Fantasy illustration", "Matte painting",
        "Isometric", "Line art", "Chiaroscuro", "Graffiti", "Street art"
    ]
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        loadState()

        // Reset watermark setting when user loses eligibility (e.g. downgrade)
        CreditsManager.shared.$subscriptionTier
            .sink { [weak self] tier in
                if !tier.canRemoveWatermark {
                    self?.removeWatermarkEnabled = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadState() {
        // Load random styles toggle (default: true)
        if userDefaults?.object(forKey: Keys.randomStylesEnabled) != nil {
            randomStylesEnabled = userDefaults?.bool(forKey: Keys.randomStylesEnabled) ?? true
        } else {
            randomStylesEnabled = true
        }
        
        // Load enabled styles (default: all styles enabled)
        if let savedStyles = userDefaults?.stringArray(forKey: Keys.enabledStyles) {
            enabledStyles = Set(savedStyles)
        } else {
            // Default to all styles enabled
            enabledStyles = Set(Self.defaultStyles)
        }
        
        // Load custom styles
        customStyles = userDefaults?.stringArray(forKey: Keys.customStyles) ?? []

        // Load watermark toggle (reset to false if no longer eligible)
        let savedWatermark = userDefaults?.bool(forKey: Keys.removeWatermarkEnabled) ?? false
        removeWatermarkEnabled = canRemoveWatermark ? savedWatermark : false
    }
    
    // MARK: - Style Management
    
    /// All available styles (built-in + custom)
    var allStyles: [String] {
        Self.defaultStyles + customStyles
    }
    
    /// Toggle a style on/off
    func toggleStyle(_ style: String) {
        if enabledStyles.contains(style) {
            enabledStyles.remove(style)
        } else {
            enabledStyles.insert(style)
        }
    }
    
    /// Check if a style is enabled
    func isStyleEnabled(_ style: String) -> Bool {
        enabledStyles.contains(style)
    }
    
    /// Add a custom style
    func addCustomStyle(_ style: String) {
        let trimmed = style.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !Self.defaultStyles.contains(trimmed),
              !customStyles.contains(trimmed) else {
            return
        }
        customStyles.append(trimmed)
        enabledStyles.insert(trimmed)
    }
    
    /// Remove a custom style
    func removeCustomStyle(_ style: String) {
        customStyles.removeAll { $0 == style }
        enabledStyles.remove(style)
    }
    
    /// Enable all styles
    func enableAllStyles() {
        enabledStyles = Set(allStyles)
    }
    
    /// Disable all styles
    func disableAllStyles() {
        enabledStyles.removeAll()
    }
    
    /// Get random enabled styles for generation
    func getRandomStyles(count: Int) -> [String] {
        let available = Array(enabledStyles)
        guard !available.isEmpty else { return [] }
        return Array(available.shuffled().prefix(count))
    }
    
    // MARK: - Watermark (derived from subscription)
    
    var canRemoveWatermark: Bool {
        CreditsManager.shared.subscriptionTier.canRemoveWatermark
    }
    
    // MARK: - Debug
    
    func resetSettings() {
        randomStylesEnabled = true
        enabledStyles = Set(Self.defaultStyles)
        customStyles = []
        removeWatermarkEnabled = false
        userDefaults?.removeObject(forKey: Keys.randomStylesEnabled)
        userDefaults?.removeObject(forKey: Keys.enabledStyles)
        userDefaults?.removeObject(forKey: Keys.customStyles)
        userDefaults?.removeObject(forKey: Keys.removeWatermarkEnabled)
    }
}
