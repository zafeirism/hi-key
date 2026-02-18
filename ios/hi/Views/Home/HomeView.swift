import SwiftUI

struct HomeView: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var showKeyboardSetup: Bool = false
    @State private var showReferralCode: Bool = false
    @State private var showAllOptions: Bool = false
    @State private var showSettings: Bool = false
    @State private var keyboardEnabled: Bool = false
    @State private var fullAccessEnabled: Bool = false
    @State private var showCopiedFeedback: Bool = false
    @State private var isFirstVisit: Bool = true
    @AppStorage("hasSeenHomeScreen") private var hasSeenHomeScreen: Bool = false

    var body: some View {
        ZStack {
            HiTheme.backgroundRoot
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header row with settings and help
                headerRow
                    .padding(.horizontal, HiTheme.spacingMD)
                    .padding(.top, HiTheme.spacingLG)
                    .padding(.bottom, HiTheme.spacingSM)
                
                // Main scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Welcome title
                        Text(welcomeText)
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .foregroundStyle(HiTheme.textPrimary)
                            .padding(.top, HiTheme.spacingSM)
                            .padding(.horizontal, HiTheme.spacingSM)
                        
                        creditsCard
                            .padding(.top, HiTheme.spacingXL)
                        
                        keyboardStatusCard
                            .padding(.top, HiTheme.spacingLG)

                        inviteFriendsCard
                            .padding(.top, HiTheme.spacingLG)
                    }
                    .padding(.horizontal, HiTheme.spacingMD)
                }
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [HiTheme.backgroundRoot, HiTheme.backgroundRoot.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: HiTheme.spacingMD)
                    .allowsHitTesting(false)
                }
            }
        }
        .sheet(isPresented: $showKeyboardSetup) {
            KeyboardSetupSheet()
                .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showReferralCode) {
            ReferralCodeSheet()
                .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showAllOptions) {
            AllPlansSheet(onComplete: nil)
                .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .background(HiTheme.backgroundRoot)
        }
        .onAppear {
            isFirstVisit = !hasSeenHomeScreen
            hasSeenHomeScreen = true
            checkKeyboardStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkKeyboardStatus()
            }
        }
    }

    // MARK: - Welcome Text

    private var welcomeText: String {
        let name = creditsManager.userName
        if isFirstVisit {
            return name.isEmpty ? "Welcome to hi-key" : "Welcome, \(name)"
        } else {
            return name.isEmpty ? "Welcome back" : "Welcome back, \(name)"
        }
    }

    // MARK: - Credits Subtitle

    private var creditsSubtitle: String {
        if creditsManager.subscriptionTier != .none {
            var text = "\(creditsManager.credits) of \(creditsManager.subscriptionTier.monthlyPrompts) remaining · resets Feb 23"
            if creditsManager.extraCredits > 0 {
                let creditWord = creditsManager.extraCredits == 1 ? "credit" : "credits"
                text += "\n\(creditsManager.extraCredits) extra \(creditWord)"
            }
            return text
        } else {
            return "Buy one-time credit packs or \nsubscribe for auto-renew"
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(HiTheme.iconDefault)
                    .frame(width: 40, height: 40)
                    .background(HiTheme.surfacePrimary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
            }

            Spacer()

            Button {
                showKeyboardSetup = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(HiTheme.iconDefault)
                    .frame(width: 40, height: 40)
                    .background(HiTheme.surfacePrimary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
            }
        }
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        HiCard {
            VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                // Top row: icon + credits + badge
                HStack(spacing: HiTheme.spacingSM) {
                    Image(systemName: "creditcard")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(HiTheme.iconDefault)

                    Text("You've got ")
                        .font(.body.weight(.medium))
                        .foregroundStyle(HiTheme.textPrimary)
                    +
                    Text("\(creditsManager.credits) credits")
                        .font(.body.weight(.heavy))
                        .foregroundStyle(HiTheme.textPrimary)

                    Spacer()

                    // Plan badge
                    Text(creditsManager.subscriptionTier.displayName.uppercased())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(creditsManager.subscriptionTier == .none ? HiTheme.textSecondary : HiTheme.accentSecondary)
                        .padding(.horizontal, HiTheme.spacingSM)
                        .padding(.vertical, HiTheme.spacingXS)
                        .background(HiTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                        .overlay(
                            RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                                .stroke(creditsManager.subscriptionTier == .none ? HiTheme.divider : HiTheme.accentSecondary, lineWidth: 1)
                        )
                }
                Divider()
                    .background(HiTheme.divider)

                // Subtitle
                Text(creditsSubtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    
                // Top-up button
                Button {
                    showAllOptions = true
                } label: {
                    Text("Top up credits")
                }
                .buttonStyle(HiSecondaryButtonStyle())
                .padding(.top, HiTheme.spacingLG)
            }
        }
    }

    // MARK: - Invite Friends Card

    private var inviteFriendsCard: some View {
        let hasCode = creditsManager.referralCode != nil

        return Button {
            if let code = creditsManager.referralCode {
                UIPasteboard.general.string = code
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopiedFeedback = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCopiedFeedback = false
                    }
                }
            } else {
                showReferralCode = true
            }
        } label: {
            HiCard {
                HStack {
                    VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                        HStack(spacing: HiTheme.spacingSM) {
                            Image(systemName: "person.2")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(HiTheme.iconDefault)

                            Text("Invite friends")
                                .font(.body.weight(.medium))
                                .foregroundStyle(HiTheme.textPrimary)
                        }
                        
                        Text("Get 5 free credits for \nevery friend who joins")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                    Spacer()

                    if hasCode {
                        // Show referral code + copy icon
                        Text(creditsManager.referralCode ?? "")
                            .font(.subheadline.monospaced().bold())
                            .foregroundStyle(HiTheme.textPrimary)

                        Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(showCopiedFeedback ? HiTheme.accentPrimary : HiTheme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(HiTheme.divider)
                            .clipShape(Circle())
                            .contentTransition(.symbolEffect(.replace))
                    } else {
                        // Chevron in circular background
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(HiTheme.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(HiTheme.divider)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }


    // MARK: - Keyboard Status Card

    private var keyboardStatusCard: some View {
        HiCard {
            VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                // Header
                HStack(spacing: HiTheme.spacingSM) {
                    Image(systemName: "keyboard")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(HiTheme.iconDefault)

                    Text("Keyboard status")
                        .font(.body.weight(.medium))
                        .foregroundStyle(HiTheme.textPrimary)
                }

                Divider()
                    .background(HiTheme.divider)

                // Indicator rows
                HStack{
                    VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                        statusRow(label: "hi-key enabled", isEnabled: keyboardEnabled)
                        statusRow(label: "Full access", isEnabled: fullAccessEnabled)
                    }
                    
                    Spacer()
                    
                    if !keyboardEnabled || !fullAccessEnabled {
                        Button {
                            openKeyboardSettings()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Open Settings")
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        .buttonStyle(HiTertiaryButtonStyle(addHorizontalPadding: false))
                    }
                }

                // Status message
                let allGood = keyboardEnabled && fullAccessEnabled
                HStack(alignment: .center, spacing: HiTheme.spacingSM) {
                    Image(systemName: allGood ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(allGood ? HiTheme.statusSuccess : HiTheme.statusWarning)

                    Text(allGood ? keyboardSuccessText : keyboardWarningText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(HiTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(HiTheme.spacingSM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HiTheme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            }
        }
    }

    private func statusRow(label: String, isEnabled: Bool) -> some View {
        HStack(spacing: HiTheme.spacingSM) {
            Circle()
                .fill(isEnabled ? HiTheme.statusSuccess : HiTheme.statusError)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HiTheme.textPrimary)
        }
    }

    private var keyboardWarningText: String {
        if !keyboardEnabled {
            return "Enable hi-key with Full access in iPhone Settings to allow it to generate images."
        } else {
            return "Full access is required to generate images from your keyboard."
        }
    }

    private var keyboardSuccessText: String {
        let totalCredits = creditsManager.credits + creditsManager.extraCredits
        if totalCredits == 0 {
            return "Looks good! Just top up some credits and open a chat to send a hi."
        }
        return "Looks good! Open a chat, switch keyboards and send a hi."
    }

    // MARK: - Helpers

    private func checkKeyboardStatus() {
        let keyboardBundleID = "ai.hi-key.keyboard"
        let appleKeyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        keyboardEnabled = appleKeyboards.contains(keyboardBundleID)
        fullAccessEnabled = UIInputViewController().hasFullAccess
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}


#Preview("First Visit - No Name") {
    HomeView()
        .onAppear {
            UserDefaults.standard.removeObject(forKey: "hasSeenHomeScreen")
            let manager = CreditsManager.shared
            manager.resetCredits()
        }
}

#Preview("Returning - With Name") {
    HomeView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasSeenHomeScreen")
            let manager = CreditsManager.shared
            manager.setUserName("Zaf")
            _ = manager.generateReferralCode()
        }
}
