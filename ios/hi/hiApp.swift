import SwiftUI
import Supabase
import RevenueCat

@main
struct hiApp: App {
    @State private var showSplash = true
    
    init() {
        HiLogger.configure()

        Purchases.configure(withAPIKey: "appl_gStvCEIADqZHDbIEUHXckUEFiDo")
        PurchasesManager.shared.bootstrap()

        // Initialize Supabase anonymous auth
        Task {
            await hiApp.initializeAuth()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HiAppBackground()
            
                if !showSplash {
                    ContentView()
                        .transition(.opacity)
                }
                
                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                DeepLinkRouter.shared.handle(url)
            }
        }
    }
    
    // MARK: - Auth Initialization
    
    private static func initializeAuth() async {
        // Use Supabase anonymous sign in
        // This creates a user without requiring email/password
        do {
            var session = try? await SupabaseManager.shared.client.auth.session
            if session == nil {
                try await SupabaseManager.shared.client.auth.signInAnonymously()
                session = try? await SupabaseManager.shared.client.auth.session
            }
            if let userID = session?.user.id.uuidString.lowercased() {
                await PurchasesManager.shared.logIn(userID: userID)
                await CreditsManager.shared.refresh()
            }
        } catch {
            HiLogger.error("Anonymous auth failed", error: error)
        }
    }
}
