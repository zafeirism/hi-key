import SwiftUI

struct NewHomeView: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var showKeyboardSetup = false
    @State private var showPaywall = false
    @State private var keyboardStatus: KeyboardStatus = .checking
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: HiTheme.spacingLG) {
                        // Welcome header
                        welcomeHeader
                        
                        // Status cards
                        VStack(spacing: HiTheme.spacingMD) {
                            keyboardStatusCard
                            subscriptionStatusCard
                        }
                        
                        Spacer(minLength: HiTheme.spacingXL)
                        
                        // Sign out (for now)
                        signOutButton
                    }
                    .padding(HiTheme.spacingLG)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("hi-key")
                        .font(HiTheme.title(20))
                }
            }
        }
        .sheet(isPresented: $showKeyboardSetup) {
            KeyboardSetupSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            checkKeyboardStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkKeyboardStatus()
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(spacing: HiTheme.spacingSM) {
            Text("Ready to create")
                .font(HiTheme.title(28))
                .foregroundColor(.primary)
            
            Text("Use hi-key in any app with your keyboard")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HiTheme.spacingLG)
    }
    
    // MARK: - Keyboard Status Card
    
    private var keyboardStatusCard: some View {
        Button {
            if keyboardStatus != .ready {
                showKeyboardSetup = true
            }
        } label: {
            HStack(spacing: HiTheme.spacingMD) {
                // Status icon
                keyboardStatusIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard")
                        .font(HiTheme.subtitle())
                        .foregroundColor(.primary)
                    
                    Text(keyboardStatus.description)
                        .font(HiTheme.caption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if keyboardStatus != .ready {
                    Text("Setup")
                        .font(HiTheme.caption())
                        .foregroundColor(HiTheme.mint)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(HiTheme.spacingLG)
            .background(Color(.systemGray6))
            .cornerRadius(HiTheme.radiusLG)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var keyboardStatusIcon: some View {
        switch keyboardStatus {
        case .checking:
            ProgressView()
                .frame(width: 32, height: 32)
        case .notInstalled, .noFullAccess:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
        }
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        Button {
            if !onboardingManager.hasSubscribed {
                showPaywall = true
            }
        } label: {
            HStack(spacing: HiTheme.spacingMD) {
                Image(systemName: onboardingManager.hasSubscribed ? "checkmark.circle.fill" : "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(onboardingManager.hasSubscribed ? .green : HiTheme.mint)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription")
                        .font(HiTheme.subtitle())
                        .foregroundColor(.primary)
                    
                    Text(onboardingManager.hasSubscribed ? "Active" : "No active subscription")
                        .font(HiTheme.caption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !onboardingManager.hasSubscribed {
                    Text("Upgrade")
                        .font(HiTheme.caption())
                        .foregroundColor(HiTheme.mint)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(HiTheme.spacingLG)
            .background(Color(.systemGray6))
            .cornerRadius(HiTheme.radiusLG)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button {
            Task {
                await authManager.signOut()
            }
        } label: {
            if authManager.isLoading {
                ProgressView()
            } else {
                Text("Sign Out")
                    .font(HiTheme.body())
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Keyboard Status Check
    
    private func checkKeyboardStatus() {
        keyboardStatus = .checking
        
        // Check if keyboard is enabled
        // This checks if our keyboard bundle ID is in the active input modes
        let keyboardBundleID = "ai.hi-key.keyboard"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let activeInputModes = UITextInputMode.activeInputModes
            let isKeyboardEnabled = activeInputModes.contains { mode in
                mode.value(forKey: "identifier") as? String == keyboardBundleID
            }
            
            if isKeyboardEnabled {
                // Keyboard is enabled, check full access
                // Note: There's no direct API to check full access, so we assume it's ready
                // In practice, you might need to use app group to communicate this
                keyboardStatus = .ready
            } else {
                keyboardStatus = .notInstalled
            }
            
            // Auto-show setup sheet if keyboard not installed
            if keyboardStatus == .notInstalled {
                showKeyboardSetup = true
            }
        }
    }
}

// MARK: - Keyboard Status

enum KeyboardStatus {
    case checking
    case notInstalled
    case noFullAccess
    case ready
    
    var description: String {
        switch self {
        case .checking:
            return "Checking..."
        case .notInstalled:
            return "Not installed yet"
        case .noFullAccess:
            return "Full access required"
        case .ready:
            return "Ready to use"
        }
    }
}

#Preview {
    NewHomeView()
}

