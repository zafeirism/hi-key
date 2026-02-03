# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

hi-key is an iOS app with a custom keyboard extension that generates AI images from text prompts. Users open the keyboard in any app (iMessage, WhatsApp, etc.), describe a scene, and receive AI-generated images within seconds that can be copied anywhere.

**Two targets:**
- `hi` - Main iOS app (onboarding, settings, home dashboard)
- `hi-keyboard` - Custom keyboard extension (image generation UI)

## Build Commands

```bash
# Open project in Xcode (no workspace - uses Swift Package Manager)
open hi.xcodeproj

# Build from command line
xcodebuild -scheme hi -configuration Debug build

# Run tests
xcodebuild -scheme hi test

# Build for release
xcodebuild -scheme hi -configuration Release build
```

## Architecture

### State Management
- **Singleton managers** with `@MainActor` and `@Published` properties
- **App Groups** (`group.ai.hi-key`) for sharing state between app and keyboard extension
- Key managers: `AuthManager`, `OnboardingManager`, `CreditsManager`, `SettingsManager`

### Networking
- `APIClient.swift` - Backend communication with async/await
- Base URL: `https://app.havingfunwith.ai`
- Bearer token auth via Supabase session
- Auto-retry with token refresh on 401

### Keyboard Extension
- `KeyboardViewController.swift` - UIInputViewController bridging to SwiftUI
- `HiKeyboardViewModel.swift` - Keyboard state machine (composing → results → browsingSuggestions)
- Uses KeyboardKit framework for input handling

### Design System
- `HiTheme.swift` - All design tokens (colors, spacing, animations, button styles)
- **Dark-first design**: Main app uses dark background with accent-sparse approach
- **Fixed dark mode**: App always renders in dark mode regardless of system settings (`.preferredColorScheme(.dark)`)
- **Color Roles:**
  - Surfaces: `backgroundRoot` (#0F1115), `surfacePrimary` (#171A20), `surfaceSecondary` (#1E222B), `divider` (#2A2F3A)
  - Text: `textPrimary` (#E6E8EC), `textSecondary` (#9AA1AD), `textTertiary` (#6E7482), `iconDefault` (#C7CBD4)
  - Accents: `accentPrimary` (#E4FF97 lime), `accentSecondary` (#B48CFF purple)
  - Status: `statusError` (#FF6B6B), `statusWarning` (#FFB86B), `statusInfo` (#6EA8FF)
- **Button Styles:**
  - `HiPrimaryButtonStyle` - Solid lime background with dark text (main CTA)
  - `HiSecondaryButtonStyle` - Outlined with lime border (secondary actions)
  - `HiTertiaryButtonStyle` - Lime text only (skip, cancel actions)
- **Legacy colors:** Mint (`CEF0C4`) kept for keyboard extension backward compatibility
- **Reusable components:** `HiCard` (uses surfacePrimary background)

### Shared Code Between Targets
Files in `hi/` folder used by keyboard extension:
- `APIClient.swift`, `AuthManager.swift`, `SupabaseManager.swift`, `AuthKeychainStorage.swift`

Files in `hi-keyboard/` folder used by main app:
- `GeneratedImage.swift`, `ImageLoader.swift`, `Logger.swift`, `Watermark.swift`

## Key Patterns

### Manager Pattern
```swift
@MainActor
class SomeManager: ObservableObject {
    static let shared = SomeManager()
    @Published var state: StateType
    private init() { }
}
```

### API Calls
All use async/await with Bearer token:
```swift
let response = try await APIClient.shared.generate(prompt: prompt)
```

### Persistence
UserDefaults with app group for cross-target sharing:
```swift
UserDefaults(suiteName: "group.ai.hi-key")
```

## Testing the Keyboard

1. Build and run the `hi` scheme on simulator/device
2. Go to iOS Settings → General → Keyboard → Keyboards
3. Add "hi-key" keyboard
4. Enable "Full Access" (required for network requests)
5. Open any app with text input and switch to hi-key keyboard

## Dependencies (Swift Package Manager)

- **Supabase** - Auth and database
- **KeyboardKit** - Custom keyboard framework
- **Lottie** - Animations (onboarding)
- **Sentry** - Error tracking

## File Organization

```
hi/                          # Main app target
├── hiApp.swift              # @main entry point
├── ContentView.swift        # Root navigation
├── APIClient.swift          # Backend API
├── AuthManager.swift        # Auth state
├── Managers/                # State managers
├── Theme/HiTheme.swift      # Design system
└── Views/                   # UI by feature
    ├── Onboarding/
    ├── Home/
    ├── Settings/
    └── Shared/

hi-keyboard/                 # Keyboard extension
├── KeyboardViewController.swift  # UIKit entry
├── HiKeyboardView.swift     # SwiftUI root
├── HiKeyboardViewModel.swift # State management
├── Handlers/                # Input handling
├── Models/                  # Data structures
├── Utilities/               # Helpers (logging, images)
└── Views/                   # Keyboard UI components
```

## Onboarding Flow

Steps defined in `OnboardingManager.swift`:
`welcome` → `hiKeyPresenter` → `keyboardExplain` → `referralCredits` → `review` → `paywall` → `complete`

## Logging

Use `HiLogger` (in keyboard extension) for Sentry + OSLog:
```swift
HiLogger.info("Message", category: .keyboard)
HiLogger.error("Error occurred", error: error)
```
