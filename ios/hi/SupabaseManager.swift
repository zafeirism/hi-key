import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://qeomdidcpphbgbjiirte.supabase.co")!
        let supabasePublishableKey = "sb_publishable_Qmjivd_W2xcGaeM38Tgycg_pQkD6mqq"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabasePublishableKey
        )
    }
}
