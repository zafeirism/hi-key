import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://lsssxrudfajjfidqbngl.supabase.co")!
        let supabasePublishableKey = "sb_publishable_mkY5IS0IqUD-VxeoaNFOyg_QCT-Fvek"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabasePublishableKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: AuthKeychainStorage(), emitLocalSessionAsInitialSession: true))
        )
    }
}
