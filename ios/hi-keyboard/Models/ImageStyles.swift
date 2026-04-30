import Foundation

// MARK: - Canonical Style List

/// Single source of truth for the built-in image styles. Shared across the
/// main app (settings UI) and the keyboard extension (suggestion bar +
/// generation request).
enum ImageStyles {
    static let defaults: [String] = [
        "Watercolor", "Oil painting", "Pastel", "Charcoal", "Comic book",
        "Manga", "Graphic novel", "Pixar style", "Ghibli style", "Disney style",
        "Anime", "Impressionist", "Surrealist", "Expressionist", "Pop art",
        "Cyberpunk", "Steampunk", "Photorealistic", "Cinematic", "Documentary",
        "Analog film", "Retro poster", "Minimalism", "Low poly", "Pixel art",
        "Sketch style", "Baroque", "Cubism", "Noir style", "Fantasy illustration",
        "Isometric", "Line art", "Chiaroscuro", "Graffiti", "Stencil"
    ]
}

// MARK: - Shared Preferences Store

/// Thin static facade over the app-group `UserDefaults` for style-related
/// preferences. Both targets read through this; the main app writes via
/// `SettingsManager`'s @Published properties.
enum ImageStylePreferences {
    private static let appGroupID = "group.ai.hi-key"

    private static var store: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private enum Keys {
        static let randomStylesEnabled = "randomStylesEnabled"
        static let enabledStyles = "enabledStyles"
        static let customStyles = "customStyles"
    }

    static var randomStylesEnabled: Bool {
        get { store?.object(forKey: Keys.randomStylesEnabled) as? Bool ?? true }
        set { store?.set(newValue, forKey: Keys.randomStylesEnabled) }
    }

    static var enabledStyles: Set<String> {
        get {
            if let saved = store?.stringArray(forKey: Keys.enabledStyles) {
                return Set(saved)
            }
            return Set(ImageStyles.defaults)
        }
        set { store?.set(Array(newValue), forKey: Keys.enabledStyles) }
    }

    static var customStyles: [String] {
        get { store?.stringArray(forKey: Keys.customStyles) ?? [] }
        set { store?.set(newValue, forKey: Keys.customStyles) }
    }

    /// Enabled styles intersected with the union of built-in defaults and
    /// the user's custom list. Filters out stale entries (e.g. a default
    /// style that was renamed in a release).
    static var enabledForDisplay: [String] {
        let valid = Set(ImageStyles.defaults).union(customStyles)
        return Array(enabledStyles.intersection(valid))
    }

    /// Random subset of `enabledForDisplay`.
    static func randomEnabledStyles(count: Int) -> [String] {
        Array(enabledForDisplay.shuffled().prefix(count))
    }
}
