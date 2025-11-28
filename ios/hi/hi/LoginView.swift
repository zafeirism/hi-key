import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo/Title
            VStack(spacing: 8) {
                Text("🎨")
                    .font(.system(size: 60))
                Text("hi")
                    .font(.system(size: 40, weight: .bold))
                Text("AI Keyboard")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Login Form
            VStack(spacing: 16) {
                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                
                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // Login Button
                Button {
                    Task {
                        await authManager.signIn(email: email, password: password)
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Footer note
            Text("For testing only\nProduction will use Sign in with Apple")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
        }
    }
}

#Preview {
    LoginView()
}
