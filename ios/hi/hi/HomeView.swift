import SwiftUI

struct HomeView: View {
    @ObservedObject var authManager = AuthManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("🎨")
                        .font(.system(size: 60))
                    Text("You're logged in!")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Next steps:")
                        .font(.headline)
                    
                    SettingRow(
                        icon: "⌨️",
                        title: "Enable the keyboard",
                        description: "Go to Settings → Keyboard → Add hi keyboard"
                    )
                    
                    SettingRow(
                        icon: "🔓",
                        title: "Allow Full Access",
                        description: "Required for generating images"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Logout Button
                Button {
                    Task {
                        await authManager.signOut()
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("hi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HomeView()
}
