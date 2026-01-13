import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        Group {
            if onboardingManager.hasCompletedOnboarding {
                // User completed onboarding - show home
                HomeView()
            } else {
                // User hasn't completed onboarding
                OnboardingFlowView()
            }
        }
        .animation(HiTheme.animationNormal, value: onboardingManager.hasCompletedOnboarding)
    }
}

// MARK: - Onboarding Flow Container

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        ZStack {
            switch onboardingManager.currentStep {
            case .welcome:
                WelcomeView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .hiKeyPresenter:
                HiKeyPresenterView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .keyboardExplain:
                KeyboardExplainView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .referralCredits:
                ReferralCreditsView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .review:
                ReviewView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .paywall:
                PaywallView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity
                    ))
                
            case .complete:
                // This shouldn't show, but just in case
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(HiTheme.animationNormal, value: onboardingManager.currentStep)
    }
}

#Preview {
    ContentView()
}
