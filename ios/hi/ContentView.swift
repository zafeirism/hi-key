import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // User is not logged in - show login
                LoginView()
            } else if onboardingManager.hasCompletedOnboarding {
                // User completed onboarding - show home
                NewHomeView()
            } else {
                // User is logged in but hasn't completed onboarding
                OnboardingFlowView()
            }
        }
        .animation(HiTheme.animationNormal, value: authManager.isAuthenticated)
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
                
            case .demo:
                DemoGenerationView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 50)),
                        removal: .opacity.combined(with: .offset(x: -50))
                    ))
                
            case .proofPoints:
                ProofPointsView()
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
                NewHomeView()
                    .transition(.opacity)
            }
        }
        .animation(HiTheme.animationNormal, value: onboardingManager.currentStep)
    }
}

#Preview {
    ContentView()
}
