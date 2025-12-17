import SwiftUI
import Supabase

@main
struct hiApp: App {
    init() {
        HiLogger.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
