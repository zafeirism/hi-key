import SwiftUI

struct TryNowView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack {
            LottieView(name: "try-now", loop: true)
                .padding(.horizontal, HiTheme.spacingLG)

            VStack(spacing: 0) {
                OnboardingTopBar(onBack: {
                    onboardingManager.goToPreviousStep()
                })
                .padding(.top, HiTheme.spacingMD)

                Text("Send your first hi.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)

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
                .padding(.bottom, HiTheme.spacingXL)
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
    }
}

#Preview {
    ZStack {
        HiAppBackground()

        TryNowView()
    }
}
