import SwiftUI
import StoreKit

struct ReviewView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var hasRequestedReview: Bool = false
    @State private var showCTA: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Title at top
            Text("Send hi-key to the stars.")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingXXL)
            
            Text("Early reviews make a huge difference. Help hi-key reach more creative people.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingMD)
            
            Spacer()
                        
            // CTA at bottom
            Button {
                onboardingManager.goToNextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .opacity(showCTA ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: showCTA)
            .padding(.bottom, HiTheme.spacingXXL)
        }
        .padding(.horizontal, HiTheme.spacingLG)
        .onAppear {
            requestReview()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCTA = true
            }
        }
    }
    
    // MARK: - Review Request
    
    private func requestReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        
        // Request review after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

#Preview {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()
        
        ReviewView()
    }
}
