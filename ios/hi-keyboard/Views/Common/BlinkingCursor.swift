import SwiftUI

struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2, height: UIFont.preferredFont(forTextStyle: .title2).pointSize)
            .cornerRadius(4)
            .opacity(isVisible ? 1 : 0) // change 1 to 0.001 to hide the cursor when screen recording for videos
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

