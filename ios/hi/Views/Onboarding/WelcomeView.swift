import SwiftUI

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            
            // Title section with app icon
            VStack(spacing: HiTheme.spacingMD) {
                Image("watermark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                
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
    }
}

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        WelcomeView()
    }
}
