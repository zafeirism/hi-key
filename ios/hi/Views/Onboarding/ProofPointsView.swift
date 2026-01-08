import SwiftUI
import StoreKit
import Combine

struct ProofPointsView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    // Sample reviews
    private let reviews: [(name: String, text: String)] = [
        ("Sarah M.", "Finally a keyboard that actually works! Generated amazing birthday memes for my friends 🎉"),
        ("Alex K.", "The speed is insane. I describe something and boom, 4 images in seconds!"),
        ("Jordan T.", "My group chats have never been more fun. Everyone asks how I make these images so fast."),
        ("Chris L.", "Worth every penny. I use this daily in my messages and social posts."),
        ("Maya R.", "Love how easy it is. Just type what you want and magic happens ✨"),
    ]
    
    @State private var currentReviewIndex = 0
    @State private var reviewOpacity: Double = 1.0
    @State private var hasRequestedReview = false
    
    private let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: HiTheme.spacingXL) {
                Spacer()
                
                // Main headline
                headlineSection
                
                // Feature highlights
                featureHighlights
                
                Spacer()
                
                // Reviews carousel
                reviewsSection
                
                Spacer()
                
                // CTA
                ctaButton
            }
            .padding(.horizontal, HiTheme.spacingLG)
            .padding(.bottom, HiTheme.spacingXL)
        }
        .onAppear {
            requestReview()
        }
    }
    
    // MARK: - Headline
    
    private var headlineSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            HStack(spacing: 4) {
                Text("The real experience is")
                    .font(HiTheme.title(28))
                    .foregroundColor(.primary)
                
                Text("10×")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(HiTheme.mint)
            }
            
            Text("With your custom keyboard, you can\ngenerate on the spot in any chat")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Feature Highlights
    
    private var featureHighlights: some View {
        VStack(spacing: HiTheme.spacingMD) {
            FeatureRow(icon: "bolt.fill", text: "Generate directly in any app")
            FeatureRow(icon: "keyboard.fill", text: "Works in iMessage, WhatsApp & more")
            FeatureRow(icon: "doc.on.clipboard.fill", text: "Copy & paste in one tap")
        }
        .padding(.horizontal, HiTheme.spacingMD)
    }
    
    // MARK: - Reviews
    
    private var reviewsSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            // Stars
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                }
            }
            
            // Review card
            VStack(spacing: HiTheme.spacingSM) {
                Text("\"\(reviews[currentReviewIndex].text)\"")
                    .font(HiTheme.body())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("— \(reviews[currentReviewIndex].name)")
                    .font(HiTheme.caption())
                    .foregroundColor(.secondary)
            }
            .padding(HiTheme.spacingLG)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(HiTheme.radiusLG)
            .opacity(reviewOpacity)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                reviewOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentReviewIndex = (currentReviewIndex + 1) % reviews.count
                withAnimation(.easeIn(duration: 0.25)) {
                    reviewOpacity = 1
                }
            }
        }
    }
    
    // MARK: - CTA Button
    
    private var ctaButton: some View {
        Button {
            onboardingManager.goToNextStep()
        } label: {
            Text("Continue")
                .hiButtonStyle()
        }
    }
    
    // MARK: - Request Review
    
    private func requestReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        
        // Small delay before showing review prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: HiTheme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(HiTheme.mint)
                .frame(width: 32)
            
            Text(text)
                .font(HiTheme.body())
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    ProofPointsView()
}

