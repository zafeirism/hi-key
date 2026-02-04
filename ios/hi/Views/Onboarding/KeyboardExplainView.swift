import SwiftUI

struct KeyboardExplainView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack{
            LottieView(name: "enable-settings", loop: true)
                //.frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top
                Text("Enable hi-key, then try it in a chat with a friend.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingXXL)
                
                Text("hi-key only reads prompts you submit to generate images.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)
                
                Spacer()
                
                // CTAs at bottom
                VStack(spacing: HiTheme.spacingLG) {
                    Button {
                        openKeyboardSettings()
                    } label: {
                        Text("Open Settings")
                    }
                    .buttonStyle(HiPrimaryButtonStyle())
                    
                    Button {
                        onboardingManager.goToNextStep()
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(HiTertiaryButtonStyle())
                }
                .padding(.bottom, HiTheme.spacingXL)
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
    }
    
    // MARK: - Actions
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()
        
        KeyboardExplainView()
    }
}
