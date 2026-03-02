import SwiftUI

struct SplashView: View {
    @Binding var isPresented: Bool
    
    @State private var opacity: Double = 1
    
    var body: some View {
        LottieView(name: "splash")
            .scaleEffect(0.5)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPresented = false
                }
            }
    }
}

#Preview {
    ZStack {
        HiAppBackground()
        SplashView(isPresented: .constant(true))
    }
}
