import SwiftUI

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Title at top
            (Text("Picture this: instant AI images ") + Text("in all your apps.").foregroundColor(.accentColor))
                .font(.title.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingXXL)
            
            Spacer()
            
            // Middle space for future assets
            
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

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        WelcomeView()
    }
}
