import SwiftUI
import Combine

struct WelcomeView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    // Sample hero images with prompts - replace with actual images later
    private let heroContent: [(image: String, prompt: String)] = [
        ("hero_1", "A cozy coffee shop on a rainy day"),
        ("hero_2", "Astronaut floating through a nebula"),
        ("hero_3", "Vintage car on Route 66 at sunset"),
        ("hero_4", "Underwater city with bioluminescent life"),
        ("hero_5", "Japanese garden in autumn mist"),
    ]
    
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [HiTheme.mint.opacity(0.3), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hero Image Section
                heroImageSection
                
                Spacer()
                
                // Title & Subtitle
                titleSection
                
                Spacer()
                
                // CTA Button
                ctaButton
            }
            .padding(.horizontal, HiTheme.spacingLG)
            .padding(.bottom, HiTheme.spacingXL)
        }
    }
    
    // MARK: - Hero Image Section
    
    private var heroImageSection: some View {
        ZStack {
            // Placeholder gradient background
            RoundedRectangle(cornerRadius: HiTheme.radiusXL)
                .fill(
                    LinearGradient(
                        colors: [
                            HiTheme.mint,
                            HiTheme.mint.opacity(0.6),
                            Color.purple.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 320)
                .overlay(
                    // Placeholder icon
                    VStack(spacing: HiTheme.spacingMD) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(heroContent[currentIndex].prompt)
                            .font(HiTheme.caption())
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                )
                .opacity(opacity)
            
            // Dreamy blur effect on edges
            RoundedRectangle(cornerRadius: HiTheme.radiusXL)
                .fill(.clear)
                .frame(height: 320)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .padding(.top, HiTheme.spacingXL)
        .onReceive(timer) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex = (currentIndex + 1) % heroContent.count
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Text("Welcome to ")
                .font(HiTheme.title(34))
                .foregroundColor(.primary)
            +
            Text("hi-key")
                .font(HiTheme.title(34))
                .foregroundColor(.primary)
            
            Text("Add creativity to your chats\nwith instant AI images")
                .font(HiTheme.subtitle())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
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
}

#Preview {
    WelcomeView()
}

