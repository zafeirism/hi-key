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
    
    private init(){
        Task{
            do{
                print("Initializing AuthManager")
                let session = try await supabase.auth.session
                if session.isExpired {
                    _ = try await supabase.auth.refreshSession()
                }
                isAuthenticated = true
                print("AuthManager initialized successfully")
            } catch {
                HiLogger.error("No session found", error: error)
                isAuthenticated = false
            }
        }
    }
    
    func getAccessToken() async -> String? {
        do {
            print("Reading session...")
            let session = try await supabase.auth.session
            print("Session returned successfully")
            isAuthenticated = true
            return session.accessToken
        } catch {
            HiLogger.error("Session restore failed", error: error)
            isAuthenticated = false
            return nil
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
        
        isAuthenticated = false
        isLoading = false
    }
}
