import SwiftUI

struct KeyboardExplainView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Title at top
            Text("Add hi-key in Settings, then try it in a chat with a friend.")
                .font(.title.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingXXL)
            
            Spacer()
            
            // Middle space for future assets
            
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
                    Text("Not now")
                }
                .buttonStyle(HiTertiaryButtonStyle())
            }
            .padding(.bottom, HiTheme.spacingXL)
        }
        .padding(.horizontal, HiTheme.spacingLG)
    }
    
    // MARK: - Actions
    
    private func openKeyboardSettings() {
        // Try to open keyboard settings directly
        if let url = URL(string: "App-prefs:root=General&path=Keyboard/KEYBOARDS") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to app settings
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        KeyboardExplainView()
    }
}
