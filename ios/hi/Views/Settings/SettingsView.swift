import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var showStylePicker: Bool = false
    @State private var showNameEditor: Bool = false
    @State private var editedName: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Profile section
                profileSection

                // Image generation section
                imageGenerationSection

                // Subscription section
                subscriptionSection

                // Support section
                supportSection

                // Legal section
                legalSection

                #if DEBUG
                // Debug section (development only)
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(HiTheme.backgroundRoot)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                }
            }
            .sheet(isPresented: $showStylePicker) {
                StylePickerView()
            }
            .alert("Edit Name", isPresented: $showNameEditor) {
                TextField("Your name", text: $editedName)
                    .textInputAutocapitalization(.words)

                Button("Cancel", role: .cancel) { }

                Button("Save") {
                    saveName()
                }
            } message: {
                Text("Your name will be shown to friends who use your referral code")
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            Button {
                editedName = creditsManager.userName
                showNameEditor = true
            } label: {
                HStack {
                    Text("Name")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(creditsManager.userName.isEmpty ? "Not set" : creditsManager.userName)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Profile")
        } footer: {
            Text("Shown to friends who use your referral code")
        }
    }
    
    // MARK: - Image Generation Section
    
    private var imageGenerationSection: some View {
        Section {
            Toggle("Random styles", isOn: $settingsManager.randomStylesEnabled)
            
            if settingsManager.randomStylesEnabled {
                Button {
                    showStylePicker = true
                } label: {
                    HStack {
                        Text("Manage styles")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(settingsManager.enabledStyles.count) enabled")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Image Generation")
        } footer: {
            Text("When enabled, each of your 4 images will have a different random style if you don't specify one")
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            Toggle("Remove hi watermark", isOn: .constant(settingsManager.canRemoveWatermark))
                .disabled(!settingsManager.canRemoveWatermark)
            
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                Link(destination: url) {
                    HStack {
                        Text("Manage subscription")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Subscription")
        } footer: {
            if !settingsManager.canRemoveWatermark {
                Text("Watermark removal is available with Pro subscription")
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            if let url = URL(string: "https://hi-key.ai/faq") {
                Link(destination: url) {
                    HStack {
                        Text("Help & FAQ")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            if let url = URL(string: "mailto:support@hi-key.ai") {
                Link(destination: url) {
                    HStack {
                        Text("Contact us")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Button {
                requestReview()
            } label: {
                HStack {
                    Text("Rate hi-key")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "star")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        Section {
            if let url = URL(string: "https://hi-key.ai/terms") {
                Link(destination: url) {
                    HStack {
                        Text("Terms of Service")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            if let url = URL(string: "https://hi-key.ai/privacy") {
                Link(destination: url) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Text("Legal")
        }
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        Section {
            Button("Reset onboarding") {
                onboardingManager.resetOnboarding()
                creditsManager.resetCredits()
                settingsManager.resetSettings()
                dismiss()
            }
            .foregroundStyle(.red)
            
            Button("Sign out") {
                Task {
                    await AuthManager.shared.signOut()
                }
            }
            .foregroundStyle(.red)
        } header: {
            Text("Debug")
        } footer: {
            Text("These options are only visible in debug builds")
        }
    }
    #endif
    
    // MARK: - Actions
    
    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't allow clearing name if referral code exists
        if trimmed.isEmpty && creditsManager.referralCode != nil {
            return
        }
        
        creditsManager.setUserName(trimmed)
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

#Preview {
    SettingsView()
}
