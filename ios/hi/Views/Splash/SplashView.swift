import SwiftUI
import Combine

struct SplashView: View {
    @Binding var isPresented: Bool
    
    @State private var currentStyleIndex = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = 0
    
    // Different artistic style representations
    private let styles: [IconStyle] = [
        IconStyle(name: "Original", backgroundColor: Color(hex: "CEF0C4"), textColor: .black, effect: .none),
        IconStyle(name: "Neon", backgroundColor: Color(hex: "1a1a2e"), textColor: Color(hex: "00ff88"), effect: .neon),
        IconStyle(name: "Sunset", backgroundColor: Color(hex: "ff6b6b"), textColor: .white, effect: .brush),
        IconStyle(name: "Ocean", backgroundColor: Color(hex: "667eea"), textColor: .white, effect: .wave),
        IconStyle(name: "Pixel", backgroundColor: Color(hex: "2d3436"), textColor: Color(hex: "74b9ff"), effect: .pixel),
    ]
    
    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background that morphs with icon style
            styles[currentStyleIndex].backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: currentStyleIndex)
            
            // Animated icon
            iconView
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            startAnimation()
        }
        .onReceive(timer) { _ in
            morphToNextStyle()
        }
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            // Icon background with shadow
            RoundedRectangle(cornerRadius: 32)
                .fill(styles[currentStyleIndex].backgroundColor)
                .frame(width: 140, height: 140)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // "hi" text with style effects
            hiText
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
    }
    
    @ViewBuilder
    private var hiText: some View {
        let style = styles[currentStyleIndex]
        
        switch style.effect {
        case .none:
            Text("hi")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(style.textColor)
            
        case .neon:
            Text("hi")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(style.textColor)
                .shadow(color: Color(hex: "00ff88").opacity(0.8), radius: 12)
                .shadow(color: Color(hex: "00ff88").opacity(0.5), radius: 24)
            
        case .brush:
            ZStack {
                Text("hi")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(style.textColor.opacity(0.3))
                    .offset(x: 3, y: 3)
                
                Text("hi")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(style.textColor)
            }
            
        case .wave:
            Text("hi")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(style.textColor)
                .shadow(color: .white.opacity(0.6), radius: 8)
            
        case .pixel:
            Text("hi")
                .font(.system(size: 68, weight: .black, design: .monospaced))
                .foregroundStyle(style.textColor)
        }
    }
    
    // MARK: - Animations
    
    private func startAnimation() {
        // Initial scale up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
        }
    }
    
    private func morphToNextStyle() {
        let nextIndex = currentStyleIndex + 1
        
        if nextIndex >= styles.count {
            // End of animation - dismiss
            dismissSplash()
        } else {
            // Morph to next style with slight rotation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStyleIndex = nextIndex
                rotation += 8
            }
        }
    }
    
    private func dismissSplash() {
        timer.upstream.connect().cancel()
        
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.1
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Icon Style

private struct IconStyle {
    let name: String
    let backgroundColor: Color
    let textColor: Color
    let effect: StyleEffect
}

private enum StyleEffect {
    case none
    case neon
    case brush
    case wave
    case pixel
}

// MARK: - Preview

#Preview {
    SplashView(isPresented: .constant(true))
}
