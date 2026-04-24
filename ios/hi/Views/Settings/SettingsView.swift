import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var showStylePicker: Bool = false
    @State private var showNameEditor: Bool = false
    @State private var showAllPlans: Bool = false
    @State private var showClaimCode: Bool = false
    @State private var showDoubleCreditsInfo: Bool = false
    @State private var editedName: String = ""
    @State private var userID: String? = nil
    @State private var didCopyUserID: Bool = false

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

                // About section (version + user ID)
                aboutSection

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
            .sheet(isPresented: $showClaimCode) {
                ClaimCodeSheet()
                    .background(HiTheme.backgroundRoot)
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
            .alert("2× credits", isPresented: $showDoubleCreditsInfo) {
                Button("Got it", role: .cancel) { }
            } message: {
                Text("As a thank you for joining the waitlist, every purchase and renewal gives you 2× credits, forever.")
            }
            .task {
                userID = await AuthManager.shared.getUserID()
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

            waitlistCodeRow
        } header: {
            Text("Profile")
        } footer: {
            Text("Part of your name will appear in your referral code.")
        }
    }

    @ViewBuilder
    private var waitlistCodeRow: some View {
        if creditsManager.doubleCredits {
            Button {
                showDoubleCreditsInfo = true
            } label: {
                HStack {
                    Text("Waitlist code")
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Text("2×")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(HiTheme.accentPrimary)
                        .padding(.horizontal, HiTheme.spacingSM)
                        .padding(.vertical, HiTheme.spacingXS)
                        .background(HiTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                        .overlay(
                            RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                                .stroke(HiTheme.divider, lineWidth: 1)
                        )
                }
            }
            .listRowBackground(HiTheme.surfacePrimary)
        } else {
            Button {
                showClaimCode = true
            } label: {
                HStack {
                    Text("Waitlist code")
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Text("Enter")
                        .foregroundStyle(HiTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HiTheme.textSecondary)
                }
            }
            .listRowBackground(HiTheme.surfacePrimary)
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
            // Hidden NavigationLink + custom label to keep push navigation
            // while matching the chevron style of other rows
            ZStack(alignment: .leading) {
                NavigationLink(destination: FAQView()) {
                    EmptyView()
                }
                .opacity(0)

                HStack {
                    Text("FAQ")
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HiTheme.textSecondary)
                }
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

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(HiTheme.textPrimary)
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(HiTheme.textSecondary)
                    .font(.footnote.monospaced())
            }
            .listRowBackground(HiTheme.surfacePrimary)

            Button {
                copyUserID()
            } label: {
                HStack {
                    Text("User ID")
                        .foregroundStyle(HiTheme.textPrimary)
                    Spacer()
                    Text(userIDDisplay)
                        .foregroundStyle(HiTheme.textSecondary)
                        .font(.footnote.monospaced())
                    Image(systemName: didCopyUserID ? "checkmark" : "square.on.square")
                        .font(.footnote)
                        .foregroundStyle(didCopyUserID ? HiTheme.accentPrimary : HiTheme.textSecondary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .disabled(userID == nil)
            .listRowBackground(HiTheme.surfacePrimary)
        } header: {
            Text("About")
        }
    }

    private var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    /// Short display like "a1b2c3d4" for the row value. The full UUID is
    /// copied on tap.
    private var userIDDisplay: String {
        guard let id = userID else { return "" }
        return String(id.suffix(8))
    }

    private func copyUserID() {
        guard let id = userID else { return }
        UIPasteboard.general.string = id
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(HiTheme.animationFast) {
            didCopyUserID = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(HiTheme.animationFast) {
                didCopyUserID = false
            }
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
