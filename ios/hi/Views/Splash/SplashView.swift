import SwiftUI

struct SplashView: View {
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            HiTheme.backgroundRoot
                .ignoresSafeArea()

            HiLogoView()
                .foregroundStyle(HiTheme.textPrimary)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Fade in + scale up (0.5s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Phase 2: Hold (0.5s) then fade out (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
            
            // Dismiss after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }
}

#Preview {
    SplashView(isPresented: .constant(true))
}
