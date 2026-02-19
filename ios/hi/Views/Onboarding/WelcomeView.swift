import SwiftUI

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    var body: some View {
        ZStack{
            LottieView(name: "parallax")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top
                (Text("Picture this: instant AI images ").foregroundColor(HiTheme.textPrimary) +
                 Text("wherever you type").foregroundColor(HiTheme.accentSecondary) +
                 Text(".").foregroundColor(HiTheme.textPrimary))
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingXXL)
                
                Spacer()
                
                // CTA at bottom
                Button {
                    onboardingManager.goToNextStep()
                } label: {
                    Text("Go on...")
                }
                .buttonStyle(HiPrimaryButtonStyle())
                .padding(.bottom, HiTheme.spacingXXL)
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
    }
}

#Preview {
    ZStack {
        HiAppBackground()
        
        WelcomeView()
    }
}
