import SwiftUI
import Supabase

@main
struct hiApp: App {
    @State private var showSplash = true
    
    init() {
        HiLogger.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash ? 0 : 1)
                
                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
        }
    }
}
