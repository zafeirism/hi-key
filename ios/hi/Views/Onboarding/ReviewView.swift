import SwiftUI
import StoreKit

struct ReviewView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var hasRequestedReview: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title at top
            Text("Send hi-key to the stars.")
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
                Text("Continue")
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .padding(.bottom, HiTheme.spacingXXL)
        }
        .padding(.horizontal, HiTheme.spacingLG)
        .onAppear {
            requestReview()
        }
    }
    
    // MARK: - Review Request
    
    private func requestReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        
        // Request review after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        ReviewView()
    }
}
