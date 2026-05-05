import SwiftUI
import Supabase
import RevenueCat
import PostHog

// MARK: - PostHog Environment

enum PostHogEnv: String {
    case projectToken = "POSTHOG_PROJECT_TOKEN"
    case host = "POSTHOG_HOST"

    private static let defaults: [String: String] = [
        "POSTHOG_PROJECT_TOKEN": "phc_u2kkpGzhnNHDJcPf6Bnr9fChCVcwc2uT8vvoQBkdScoa",
        "POSTHOG_HOST": "https://eu.i.posthog.com",
    ]

    var value: String {
        ProcessInfo.processInfo.environment[rawValue] ?? Self.defaults[rawValue]!
    }
}

@main
struct hiApp: App {
    @State private var showSplash = true

    init() {
        HiLogger.configure()

        // PostHog: Initialize analytics
        let config = PostHogConfig(apiKey: PostHogEnv.projectToken.value, host: PostHogEnv.host.value)
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)

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
                // PostHog: Identify user with stable Supabase ID
                PostHogSDK.shared.identify(userID)
            }
        } catch {
            HiLogger.error("Anonymous auth failed", error: error)
        }
    }
}
