import SwiftUI

struct KeyboardExplainView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    var body: some View {
        ZStack{
            LottieView(name: "enable-settings", loop: true)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top
                Text("Enable hi-key in Settings.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingXXL)
                
                Text("Allow Full Access so hi-key can generate images from your prompts.")
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
                        Text("I'll do this later")
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
