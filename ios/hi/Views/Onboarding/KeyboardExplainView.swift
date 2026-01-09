import SwiftUI

struct KeyboardExplainView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mock keyboard visual
            mockKeyboardVisual
            
            Spacer()
            
            // Title
            Text("A keyboard like no other")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, HiTheme.spacingLG)
            
            Spacer()
            
            // Feature bullets
            VStack(spacing: HiTheme.spacingLG) {
                FeatureBullet(
                    icon: "keyboard.fill",
                    text: "Works in any app — iMessage, WhatsApp, Instagram..."
                )
                
                FeatureBullet(
                    icon: "sparkles",
                    text: "Describe what you want, get 4 images in seconds"
                )
                
                FeatureBullet(
                    icon: "doc.on.clipboard",
                    text: "Tap to copy, paste anywhere"
                )
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
    
    // MARK: - Mock Keyboard Visual
    
    private var mockKeyboardVisual: some View {
        VStack(spacing: HiTheme.spacingSM) {
            // App icons row representing different apps
            HStack(spacing: HiTheme.spacingMD) {
                AppIconMock(systemName: "message.fill", color: .green)
                AppIconMock(systemName: "phone.fill", color: .blue)
                AppIconMock(systemName: "camera.fill", color: .purple)
                AppIconMock(systemName: "envelope.fill", color: .cyan)
            }
            
            // Mock keyboard
            VStack(spacing: 6) {
                // Prompt bar
                HStack {
                    Text("A cat astronaut on Mars")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.horizontal, HiTheme.spacingMD)
                .padding(.vertical, HiTheme.spacingSM)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusXL))
                
                // Image preview row
                HStack(spacing: HiTheme.spacingSM) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .padding(.vertical, HiTheme.spacingSM)
            }
            .padding(HiTheme.spacingMD)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
        }
        .padding(.horizontal, HiTheme.spacingXL)
    }
}

// MARK: - Feature Bullet

private struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: HiTheme.spacingMD) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - App Icon Mock

private struct AppIconMock: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    KeyboardExplainView()
}
