import SwiftUI

struct HomeView: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var showKeyboardSetup: Bool = false
    @State private var showReferralCode: Bool = false
    @State private var showAllOptions: Bool = false
    @State private var showSettings: Bool = false
    @State private var keyboardStatus: KeyboardStatus = .checking
    @State private var showCopiedFeedback: Bool = false
    @State private var isFirstVisit: Bool = true
    @AppStorage("hasSeenHomeScreen") private var hasSeenHomeScreen: Bool = false

    // For AllOptionsSheet
    @State private var selectedSubscription: SubscriptionTier? = nil
    @State private var selectedPack: CreditPack? = nil

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

                        // Credits card
                        creditsCard
                            .padding(.top, HiTheme.spacingXL)

                        // Invite friends card
                        inviteFriendsCard
                            .padding(.top, HiTheme.spacingLG)
                    }
                    .padding(.horizontal, HiTheme.spacingMD)

                    Spacer(minLength: HiTheme.spacingXL * 2)

                    Text("Open any chat or app, switch \nkeyboards and send a hi.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HiTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: HiTheme.spacingXL)
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
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [HiTheme.backgroundRoot.opacity(0), HiTheme.backgroundRoot],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: HiTheme.spacingMD)
                    .allowsHitTesting(false)
                }

                // Bottom footer (fixed outside scroll)
                Button {
                    showKeyboardSetup = true
                } label: {
                    HStack(spacing: 4) {
                        Text("How to enable hi-key")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(HiTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, HiTheme.spacingMD)
                .padding(.top, HiTheme.spacingSM)
            }
        }
        .sheet(isPresented: $showKeyboardSetup) {
            KeyboardSetupSheet()
        }
        .sheet(isPresented: $showReferralCode) {
            ReferralCodeSheet()
        }
        .sheet(isPresented: $showAllOptions) {
            AllOptionsSheet(
                selectedSubscription: $selectedSubscription,
                selectedPack: $selectedPack
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            isFirstVisit = !hasSeenHomeScreen
            hasSeenHomeScreen = true
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
            // Settings button (left)
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

            // Help button (right)
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
                        .foregroundStyle(HiTheme.textPrimary)
                        .padding(.horizontal, HiTheme.spacingSM)
                        .padding(.vertical, HiTheme.spacingXS)
                        .background(creditsManager.subscriptionTier == .none ? HiTheme.surfaceSecondary : HiTheme.accentSecondary.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                        .overlay(
                            RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                                .stroke(creditsManager.subscriptionTier == .none ? HiTheme.divider : Color.clear, lineWidth: 1)
                        )
                }

                // Subtitle
                Text(creditsSubtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    
                // Top-up button
                Button {
                    showAllOptions = true
                } label: {
                    Text("Top-up credits")
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


    // MARK: - Helpers

    private func checkKeyboardStatus() {
        keyboardStatus = .checking

        let keyboardBundleID = "ai.hi-key.hi.hi-keyboard"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let activeInputModes = UITextInputMode.activeInputModes
            let isKeyboardEnabled = activeInputModes.contains { mode in
                (mode.value(forKey: "identifier") as? String) == keyboardBundleID
            }

            if isKeyboardEnabled {
                keyboardStatus = .ready
            } else {
                keyboardStatus = .notInstalled
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
