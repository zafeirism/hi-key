import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var showStylePicker: Bool = false
    @State private var showNameEditor: Bool = false
    @State private var showAllPlans: Bool = false
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

                // Support & Legal section
                supportSection

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
            .sheet(isPresented: $showAllPlans) {
                AllPlansSheet(onComplete: nil)
            }
            .alert("Enter your name", isPresented: $showNameEditor) {
                TextField("Your name", text: $editedName)
                    .textInputAutocapitalization(.words)

                Button("Cancel", role: .cancel) { }

                Button("Save") {
                    saveName()
                }
            } message: {
                Text("Part of your name will appear in your referral code and be shown to friends who use it.")
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
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Text(creditsManager.userName.isEmpty ? "Not set" : creditsManager.userName)
                        .foregroundStyle(HiTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HiTheme.textSecondary)
                }
            }
            .listRowBackground(HiTheme.surfacePrimary)
        } header: {
            Text("Profile")
        } footer: {
            Text("Part of your name will appear in your referral code.")
        }
    }

    // MARK: - Image Generation Section

    private var imageGenerationSection: some View {
        Section {
            Toggle("Random styles", isOn: $settingsManager.randomStylesEnabled)
                .listRowBackground(HiTheme.surfacePrimary)

            if settingsManager.randomStylesEnabled {
                Button {
                    showStylePicker = true
                } label: {
                    HStack {
                        Text("Manage styles")
                            .foregroundStyle(HiTheme.textPrimary)
                        Spacer()
                        Text("\(settingsManager.enabledStyles.count) enabled")
                            .foregroundStyle(HiTheme.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                }
                .listRowBackground(HiTheme.surfacePrimary)
            }
        } header: {
            Text("Image Generation")
        } footer: {
            Text("When enabled, each of the 4 images will have a random style, unless your prompt specifies one.")
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            Toggle("Remove hi-key watermark", isOn: $settingsManager.removeWatermarkEnabled)
                .disabled(!settingsManager.canRemoveWatermark)
                .listRowBackground(HiTheme.surfacePrimary)

            Button {
                showAllPlans = true
            } label: {
                HStack {
                    Text("Manage subscription")
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HiTheme.textSecondary)
                }
            }
            .listRowBackground(HiTheme.surfacePrimary)
        } header: {
            Text("Watermark")
        } footer: {
            if !settingsManager.canRemoveWatermark {
                Text("Watermark removal is available with Super subscription.")
            }
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section {
            NavigationLink {
                FAQView()
            } label: {
                Text("FAQ")
                    .foregroundStyle(HiTheme.textPrimary)
            }
            .listRowBackground(HiTheme.surfacePrimary)

            if let url = URL(string: "mailto:support@hi-key.ai") {
                Link(destination: url) {
                    HStack {
                        Text("Contact us")
                            .foregroundStyle(HiTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                }
                .listRowBackground(HiTheme.surfacePrimary)
            }

            if let url = URL(string: "https://hi-key.ai/terms") {
                Link(destination: url) {
                    HStack {
                        Text("Terms of Service")
                            .foregroundStyle(HiTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                }
                .listRowBackground(HiTheme.surfacePrimary)
            }

            if let url = URL(string: "https://hi-key.ai/privacy") {
                Link(destination: url) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(HiTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                }
                .listRowBackground(HiTheme.surfacePrimary)
            }
        } header: {
            Text("Help")
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
                UserDefaults.standard.removeObject(forKey: "hasSeenHomeScreen")
                dismiss()
            }
            .foregroundStyle(HiTheme.statusError)
            .listRowBackground(HiTheme.surfacePrimary)

            Button("Sign out") {
                Task {
                    await AuthManager.shared.signOut()
                }
            }
            .foregroundStyle(HiTheme.statusError)
            .listRowBackground(HiTheme.surfacePrimary)
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
}

#Preview {
    SettingsView()
}
