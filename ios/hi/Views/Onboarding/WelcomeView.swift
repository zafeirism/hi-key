import SwiftUI

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo section
            VStack(spacing: HiTheme.spacingLG) {
                HiLogoView()
                    .padding(.bottom, HiTheme.spacingMD)
                
                Image(systemName: "wand.and.sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Title section
            VStack(spacing: HiTheme.spacingMD) {
                Text("Create images while you chat")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("Generate AI images directly from your keyboard in any app")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, HiTheme.spacingLG)
            
            Spacer()
            Spacer()
            
            // CTA Button
            Button {
                onboardingManager.goToNextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .padding(.horizontal, HiTheme.spacingMD)
            .padding(.bottom, HiTheme.spacingXL)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    WelcomeView()
}
