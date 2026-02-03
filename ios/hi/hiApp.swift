import SwiftUI
import Supabase

@main
struct hiApp: App {
    @State private var showSplash = true
    
    init() {
        HiLogger.configure()
        
        // Initialize Supabase anonymous auth
        Task {
            await hiApp.initializeAuth()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HiTheme.backgroundRoot
                    .ignoresSafeArea()
            
                ContentView()
                    .opacity(showSplash ? 0 : 1)
                
                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Auth Initialization
    
    private static func initializeAuth() async {
        // Use Supabase anonymous sign in
        // This creates a user without requiring email/password
        do {
            let session = try? await SupabaseManager.shared.client.auth.session
            if session == nil {
                // No existing session - sign in anonymously
                try await SupabaseManager.shared.client.auth.signInAnonymously()
            }
        } catch {
            HiLogger.error("Anonymous auth failed", error: error)
        }
    }
}
