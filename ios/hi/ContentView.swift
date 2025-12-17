import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        if authManager.isAuthenticated {
            // User is logged in - show home screen
            HomeView()
        } else {
            // User is not logged in - show login
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}