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

    @Published var randomStylesEnabled: Bool {
        didSet { ImageStylePreferences.randomStylesEnabled = randomStylesEnabled }
    }

    @Published var enabledStyles: Set<String> {
        didSet { ImageStylePreferences.enabledStyles = enabledStyles }
    }

    @Published var customStyles: [String] {
        didSet { ImageStylePreferences.customStyles = customStyles }
    }

    @Published var removeWatermarkEnabled: Bool = false {
        didSet {
            userDefaults?.set(removeWatermarkEnabled, forKey: Keys.removeWatermarkEnabled)
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let removeWatermarkEnabled = "removeWatermarkEnabled"
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        randomStylesEnabled = ImageStylePreferences.randomStylesEnabled
        enabledStyles = ImageStylePreferences.enabledStyles
        customStyles = ImageStylePreferences.customStyles

        let savedWatermark = userDefaults?.bool(forKey: Keys.removeWatermarkEnabled) ?? false
        removeWatermarkEnabled = PurchasesManager.shared.canRemoveWatermark ? savedWatermark : false

        // Reset watermark setting when user loses eligibility (e.g. downgrade,
        // sub expiration, refund). PurchasesManager republishes customerInfo
        // whenever RC reports a change.
        PurchasesManager.shared.$customerInfo
            .sink { [weak self] _ in
                guard let self else { return }
                if !PurchasesManager.shared.canRemoveWatermark {
                    self.removeWatermarkEnabled = false
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Style Management

    /// All available styles (built-in + custom)
    var allStyles: [String] {
        ImageStyles.defaults + customStyles
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
              !ImageStyles.defaults.contains(trimmed),
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

    // MARK: - Watermark (derived from RC entitlement)

    var canRemoveWatermark: Bool {
        PurchasesManager.shared.canRemoveWatermark
    }

    // MARK: - Debug

    func resetSettings() {
        randomStylesEnabled = true
        enabledStyles = Set(ImageStyles.defaults)
        customStyles = []
        removeWatermarkEnabled = false
        userDefaults?.removeObject(forKey: Keys.removeWatermarkEnabled)
    }
}
