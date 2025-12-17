import KeyboardKit

extension KeyboardApp {
    
    /// The hi-key keyboard app configuration
    static var hi: KeyboardApp {
        KeyboardApp(
            name: "hi",
            // licenseKey: "...",  // Only needed for KeyboardKit Pro
            appGroupId: "group.ai.havingfunwith.hi",  // Your App Group
            locales: [.english],  // Start with English only
            deepLinks: KeyboardApp.DeepLinks(app: "hi://")  // Optional: for opening main app
        )
    }
}
