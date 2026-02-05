import Foundation
import Supabase

@MainActor
class AuthManager {
    static let shared = AuthManager()

    private let supabase = SupabaseManager.shared.client

    private init(){
        Task{
            do{
                print("Initializing AuthManager")
                let session = try await supabase.auth.session
                if session.isExpired {
                    _ = try await supabase.auth.refreshSession()
                }
                print("AuthManager initialized successfully")
            } catch {
                HiLogger.error("No session found", error: error)
            }
        }
    }

    func getAccessToken() async -> String? {
        do {
            print("Reading session...")
            let session = try await supabase.auth.session
            print("Session returned successfully")
            return session.accessToken
        } catch {
            HiLogger.error("Session restore failed", error: error)
            return nil
        }
    }

    // Logout
    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
