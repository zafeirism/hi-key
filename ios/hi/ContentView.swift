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
    }
}

// MARK: - Onboarding Flow Container

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    private var slideTransition: AnyTransition {
        let offset: CGFloat = onboardingManager.navigationDirection == .forward ? 50 : -50
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: offset)),
            removal: .opacity.combined(with: .offset(x: -offset))
        )
    }

    private var canGoBack: Bool {
        switch onboardingManager.currentStep {
        case .enableSettings, .tryNow, .referralCredits, .review:
            return true
        default:
            return false
        }
    }

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
                    .transition(slideTransition)

            case .enableSettings:
                EnableSettingsView()
                    .transition(slideTransition)

            case .tryNow:
                TryNowView()
                    .transition(slideTransition)

            case .referralCredits:
                ReferralCreditsView()
                    .transition(slideTransition)

            case .review:
                ReviewView()
                    .transition(slideTransition)

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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard canGoBack else { return }
                    // Swipe from left edge (within 40pt) with enough horizontal movement
                    let startedFromEdge = value.startLocation.x < 40
                    let swipedRight = value.translation.width > 80
                    let mostlyHorizontal = abs(value.translation.width) > abs(value.translation.height)

                    if startedFromEdge && swipedRight && mostlyHorizontal {
                        onboardingManager.goToPreviousStep()
                    }
                }
        )
        .animation(HiTheme.animationNormal, value: onboardingManager.currentStep)
    }
}

#Preview {
    ContentView()
}
