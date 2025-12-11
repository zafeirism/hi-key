import Foundation
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    private let tokenStorage = AuthTokenStorage.shared
    
    private init() {
        checkExistingAuth()
    }
    
    func checkExistingAuth() {
        Task {
            await restoreSession()
        }
    }

    func restoreSession() async {
        guard let accessToken = tokenStorage.getAccessToken(),
              let refreshToken = tokenStorage.getRefreshToken() else {
            isAuthenticated = false
            return
        }
        
        do {
            // Restore session - Supabase will auto-refresh if needed
            let session = try await supabase.auth.setSession(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            
            // Save potentially new tokens
            tokenStorage.saveTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            
            isAuthenticated = true
            print("Tokens restored successfully!")
        } catch {
            print("Session restore failed: \(error)")
            // Clear invalid tokens
            tokenStorage.clearTokens()
            isAuthenticated = false
        }
    }
    
    // Login with email/password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Save tokens
            tokenStorage.saveTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Logout
    func signOut() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        
        // Clear stored tokens
        tokenStorage.clearTokens()
        isAuthenticated = false
        isLoading = false
    }
}
