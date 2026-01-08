import SwiftUI
import Combine

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case demo = 1
    case proofPoints = 2
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
    @Published var demoGenerationsUsed: Int = 0
    
    // MARK: - Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let demoGenerationsUsed = "demoGenerationsUsed"
        static let hasSubscribed = "hasSubscribed"
    }
    
    // MARK: - Computed Properties
    
    var hasCompletedOnboarding: Bool {
        get { userDefaults?.bool(forKey: Keys.hasCompletedOnboarding) ?? false }
        set { 
            userDefaults?.set(newValue, forKey: Keys.hasCompletedOnboarding)
            objectWillChange.send()
        }
    }
    
    var hasSubscribed: Bool {
        get { userDefaults?.bool(forKey: Keys.hasSubscribed) ?? false }
        set { 
            userDefaults?.set(newValue, forKey: Keys.hasSubscribed)
            objectWillChange.send()
        }
    }
    
    var canGenerateDemo: Bool {
        demoGenerationsUsed < 3
    }
    
    var hasGeneratedAtLeastOnce: Bool {
        demoGenerationsUsed > 0
    }
    
    // MARK: - Init
    
    private init() {
        resetOnboarding() // remove after debugging
        loadState()
    }
    
    private func loadState() {
        demoGenerationsUsed = userDefaults?.integer(forKey: Keys.demoGenerationsUsed) ?? 0
        
        // Determine current step based on saved state
        if hasCompletedOnboarding {
            currentStep = .complete
        } else if demoGenerationsUsed > 0 {
            // User has done demo, continue from proof points
            currentStep = .proofPoints
        }
    }
    
    // MARK: - Actions
    
    func incrementDemoGeneration() {
        demoGenerationsUsed += 1
        userDefaults?.set(demoGenerationsUsed, forKey: Keys.demoGenerationsUsed)
    }
    
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
        currentStep = .complete
    }
    
    // MARK: - Debug
    
    func resetOnboarding() {
        userDefaults?.removeObject(forKey: Keys.hasCompletedOnboarding)
        userDefaults?.removeObject(forKey: Keys.demoGenerationsUsed)
        userDefaults?.removeObject(forKey: Keys.hasSubscribed)
        demoGenerationsUsed = 0
        currentStep = .welcome
    }
}

