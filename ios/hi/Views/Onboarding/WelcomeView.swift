import SwiftUI

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @State private var isLottieFinished = false
    
    var body: some View {
        ZStack{
            LottieView(name: "parallax", isFinished: $isLottieFinished)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top
                (Text("Picture this: instant AI images ") + Text("in all your apps.").foregroundColor(.accentColor))
                    .font(.title.bold())
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
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        WelcomeView()
    }
}
