import SwiftUI

struct TryNowView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack {
            // TODO: Replace with final Lottie animation
            // LottieView(name: "try-now")
            //     .frame(maxWidth: 330)

            VStack(spacing: 0) {
                OnboardingTopBar(onBack: {
                    onboardingManager.goToPreviousStep()
                })
                .padding(.top, HiTheme.spacingSM)

                Text("Send your first hi.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingLG)

                Text("You have 5 free credits. Open any chat and send your first hi.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)

                Spacer()

                Button {
                    onboardingManager.goToNextStep()
                } label: {
                    Text("I'll try it later")
                }
                .buttonStyle(HiTertiaryButtonStyle())
                .padding(.bottom, HiTheme.spacingXXL)
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
    }
}

#Preview {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()

        TryNowView()
    }
}
