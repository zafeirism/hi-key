import SwiftUI

struct HomeView: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var purchasesManager = PurchasesManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @Environment(\.scenePhase) private var scenePhase

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
            HiAppBackground()

            VStack(spacing: 0) {
                // Transparent header — gradient shows through seamlessly
                headerRow
                    .padding(.horizontal, HiTheme.spacingMD)
                    .padding(.top, HiTheme.spacingLG)
                    .padding(.bottom, HiTheme.spacingMD)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        creditsCard
                            .padding(.top, HiTheme.spacingXS)
                        
                        keyboardStatusCard
                            .padding(.top, HiTheme.spacingLG)
                        
                        inviteFriendsCard
                            .padding(.top, HiTheme.spacingLG)
                    }
                    .padding(.horizontal, HiTheme.spacingMD)
                    .padding(.bottom, HiTheme.spacingXL)
                }
            }
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
            Task { await creditsManager.refresh() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkKeyboardStatus()
                Task { await creditsManager.refresh() }
            }
        }
    }

    // MARK: - Derived State

    private var welcomeText: String {
        let name = creditsManager.userName
        if isFirstVisit {
            return name.isEmpty ? "Welcome to hi-key" : "Welcome, \(name)"
        } else {
            return name.isEmpty ? "Welcome back" : "Welcome back, \(name)"
        }
    }

    private var totalCredits: Int {
        creditsManager.credits + creditsManager.extraCredits
    }

    private var allKeyboardStatusGood: Bool {
        keyboardEnabled && fullAccessEnabled
    }

    private var hasReferralCode: Bool {
        creditsManager.referralCode != nil
    }

    private var subscriptionProgress: Double {
        let weekly = weeklyCreditAllowance
        guard weekly > 0 else { return 0 }
        return Double(creditsManager.credits) / Double(weekly)
    }

    private var weeklyCreditAllowance: Int {
        guard let id = purchasesManager.activeSubscriptionProductID else { return 0 }
        return purchasesManager.weeklyCredits(for: id) ?? 0
    }

    private var weeklyCreditsCaption: String {
        let weekly = weeklyCreditAllowance
        let suffix: String
        if let date = purchasesManager.subscriptionRenewsAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            suffix = " · resets \(formatter.string(from: date))"
        } else {
            suffix = ""
        }
        return "\(creditsManager.credits) of \(weekly) weekly\(suffix)"
    }

    private var extraCreditsText: String {
        let n = creditsManager.extraCredits
        return "+\(n) extra \(n == 1 ? "credit" : "credits")"
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: HiTheme.spacingSM) {
            Text(welcomeText)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(HiTheme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HiIconButton("gearshape", size: .topBar){
                showSettings = true
            }
        }
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        HiCard {
            VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                // Hero row: large credit count + plan badge
                HStack(alignment: .center) {
                    HStack(alignment: .firstTextBaseline, spacing: HiTheme.spacingSM) {
                        Text("\(totalCredits)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(HiTheme.textPrimary)
                            .contentTransition(.numericText())

                        Text("credits")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(HiTheme.textSecondary)
                    }

                    Spacer()

                    planBadge
                }

                // Subscriber: progress bar + captions
                // Free user: descriptive text
                if purchasesManager.hasActiveSubscription {
                    creditsProgressSection
                } else {
                    Text("Buy one-time credit packs or subscribe for auto-renew")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HiTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    showAllOptions = true
                } label: {
                    Text("Top up credits")
                }
                .buttonStyle(HiSecondaryButtonStyle())
            }
        }
    }

    private var planBadge: some View {
        let isSubscribed = purchasesManager.hasActiveSubscription
        let label = (purchasesManager.tierDisplayName ?? "Free").uppercased()
        return Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSubscribed ? HiTheme.accentSecondary : HiTheme.textSecondary)
            .padding(.horizontal, HiTheme.spacingSM)
            .padding(.vertical, HiTheme.spacingXS)
            .background(HiTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                    .stroke(isSubscribed ? HiTheme.accentSecondary : HiTheme.divider, lineWidth: 1)
            )
    }

    private var creditsProgressSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(HiTheme.divider)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Capsule()
                        .fill(HiTheme.accentPrimary)
                        .frame(
                            width: max(0, geo.size.width * CGFloat(subscriptionProgress)),
                            height: geo.size.height
                        )
                }
            }
            .frame(height: 6)

            Text(weeklyCreditsCaption)
                .font(.footnote.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)

            if creditsManager.extraCredits > 0 {
                Text(extraCreditsText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
            }
        }
    }

    // MARK: - Keyboard Status Card

    private var keyboardStatusCard: some View {
        HiCard {
            VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
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

                HStack {
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

                HStack(alignment: .center, spacing: HiTheme.spacingSM) {
                    Image(systemName: allKeyboardStatusGood ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(allKeyboardStatusGood ? HiTheme.statusSuccess : HiTheme.statusWarning)

                    Text(allKeyboardStatusGood ? keyboardSuccessText : keyboardWarningText)
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
        if totalCredits == 0 {
            return "Your hi-key looks good! Just top up some credits and open a chat to send a hi."
        }
        return "Your hi-key looks good! Open a chat, switch keyboards and send a hi."
    }

    // MARK: - Invite Friends Card

    private var inviteFriendsCard: some View {
        Button {
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

                        Text("Get 5 free credits for every friend who joins")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HiTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if hasReferralCode {
                        Text(creditsManager.referralCode ?? "")
                            .font(.subheadline.monospaced().bold())
                            .foregroundStyle(HiTheme.textPrimary)

                        Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(showCopiedFeedback ? HiTheme.accentPrimary : HiTheme.iconDefault)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(HiTheme.surfaceSecondary.opacity(0.90)))
                            .overlay(Circle().stroke(HiTheme.divider.opacity(0.55), lineWidth: 1))
                            .contentTransition(.symbolEffect(.replace))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HiTheme.iconDefault)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(HiTheme.surfaceSecondary.opacity(0.90)))
                            .overlay(Circle().stroke(HiTheme.divider.opacity(0.55), lineWidth: 1))
                    }
                }
            }
        }
        .buttonStyle(.plain)
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

#Preview("Returning - Subscribed") {
    HomeView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasSeenHomeScreen")
            let manager = CreditsManager.shared
            manager.setUserName("Alexandros")
            _ = manager.generateReferralCode()
        }
}

#Preview("Returning - Free") {
    HomeView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasSeenHomeScreen")
            let manager = CreditsManager.shared
            manager.setUserName("Zaf")
            manager.resetCredits()
        }
}
