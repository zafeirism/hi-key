import SwiftUI
import Combine

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case keyboardExplain = 1
    case referralCredits = 2
    case paywall = 3
    case complete = 4
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
        withAnimation(HiTheme.animationNormal) {
            currentStep = nextStep
        }
    }
    
    func goToStep(_ step: OnboardingStep) {
        withAnimation(HiTheme.animationNormal) {
            currentStep = step
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation(HiTheme.animationNormal) {
            currentStep = .complete
        }
    }
    
    /// Apply a referral code from a friend
    func applyReferralCode(_ code: String) -> Bool {
        // Validate format: NAME-CODE (NAME up to 6 chars, CODE is 6 chars Crockford Base32)
        guard isValidReferralCodeFormat(code) else {
            return false
        }
        
        referrerCode = code.uppercased()
        referralApplied = true
        return true
    }
    
    /// Validate referral code format (client-side only)
    func isValidReferralCodeFormat(_ code: String) -> Bool {
        let pattern = "^[A-Z0-9]{1,6}-[0-9A-HJKMNP-TV-Z]{6}$"
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
