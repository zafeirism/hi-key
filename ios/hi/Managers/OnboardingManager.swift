import SwiftUI
import Combine

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case hiKeyPresenter = 1
    case enableSettings = 2
    case openKeyboard = 3
    case referralCredits = 4
    case review = 5
    case paywall = 6
    case complete = 7

    // Retired step. Kept compilable (and renderable from ContentView) but
    // unreachable via goToNextStep/goToPreviousStep so it stays out of the
    // active flow without deleting the view code.
    case tryNow = 99
}

// MARK: - Navigation Direction

enum NavigationDirection {
    case forward
    case backward
}

// MARK: - Onboarding Manager

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    private let appGroupID = "group.ai.hi-key"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var navigationDirection: NavigationDirection = .forward
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let referrerCode = "referrerCode"
        static let referralApplied = "referralApplied"
    }
    
    // MARK: - Computed Properties
    
    var hasCompletedOnboarding: Bool {
        get { userDefaults?.bool(forKey: Keys.hasCompletedOnboarding) ?? false }
        set { 
            userDefaults?.set(newValue, forKey: Keys.hasCompletedOnboarding)
            objectWillChange.send()
        }
    }
    
    /// The referral code entered by this user (from a friend)
    var referrerCode: String? {
        get { userDefaults?.string(forKey: Keys.referrerCode) }
        set {
            userDefaults?.set(newValue, forKey: Keys.referrerCode)
            objectWillChange.send()
        }
    }
    
    /// Whether the user successfully applied a friend's referral code
    var referralApplied: Bool {
        get { userDefaults?.bool(forKey: Keys.referralApplied) ?? false }
        set {
            userDefaults?.set(newValue, forKey: Keys.referralApplied)
            objectWillChange.send()
        }
    }
    
    // MARK: - Init
    
    private init() {
        // Uncomment for debugging - resets onboarding each launch
        // resetOnboarding()
        loadState()
    }
    
    private func loadState() {
        if hasCompletedOnboarding {
            currentStep = .complete
        }
    }
    
    // MARK: - Actions
    
    func goToNextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        navigationDirection = .forward
        withAnimation(HiTheme.animationNormal) {
            currentStep = nextStep
        }
    }

    func goToPreviousStep() {
        guard currentStep.rawValue > 0,
              let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        navigationDirection = .backward
        withAnimation(HiTheme.animationNormal) {
            currentStep = previousStep
        }
    }
    
    func goToStep(_ step: OnboardingStep) {
        withAnimation(HiTheme.animationNormal) {
            currentStep = step
        }
    }
    
    func completeOnboarding() {
        withAnimation(HiTheme.animationSlow) {
            hasCompletedOnboarding = true
            currentStep = .complete
        }
    }
    
    /// Redeem a friend's referral code against the backend. Persists the code
    /// locally on success so the onboarding step can re-render in the applied
    /// state without a network round-trip. Errors propagate to the caller for
    /// user-facing messaging.
    func applyReferralCode(_ code: String) async throws {
        guard isValidReferralCodeFormat(code) else {
            throw APIClient.APIError.invalidReferralCode
        }

        let normalized = code.uppercased()
        try await CreditsManager.shared.redeemReferralCode(normalized)
        referrerCode = normalized
        referralApplied = true
    }

    /// Client-side shape check for the Apply button's enabled state. Actual
    /// validation happens on the backend.
    func isValidReferralCodeFormat(_ code: String) -> Bool {
        let pattern = "^[A-Z]{1,6}-[0-9A-HJKMNP-TV-Z]{6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(code.startIndex..., in: code)
        return regex?.firstMatch(in: code, options: [], range: range) != nil
    }
    
    // MARK: - Debug
    
    func resetOnboarding() {
        userDefaults?.removeObject(forKey: Keys.hasCompletedOnboarding)
        userDefaults?.removeObject(forKey: Keys.referrerCode)
        userDefaults?.removeObject(forKey: Keys.referralApplied)
        currentStep = .welcome
    }
}
