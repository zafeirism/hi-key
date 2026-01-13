import SwiftUI

struct HomeView: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    @ObservedObject var onboardingManager = OnboardingManager.shared
    
    @State private var showKeyboardSetup: Bool = false
    @State private var showReferralCode: Bool = false
    @State private var showAllOptions: Bool = false
    @State private var showSettings: Bool = false
    @State private var keyboardStatus: KeyboardStatus = .checking
    
    // For AllOptionsSheet
    @State private var selectedSubscription: SubscriptionTier? = nil
    @State private var selectedPack: CreditPack? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HiTheme.spacingMD) {
                    // Credits header
                    creditsHeader
                    
                    // Share & Earn card
                    shareAndEarnCard
                    
                    // Keyboard status card
                    keyboardStatusCard
                    
                    // Subscription status card
                    subscriptionStatusCard
                    
                    // Settings card
                    settingsCard
                }
                .padding(HiTheme.spacingMD)
            }
            .navigationTitle("hi-key")
            .navigationBarTitleDisplayMode(.inline)
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
            checkKeyboardStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkKeyboardStatus()
        }
    }
    
    // MARK: - Credits Header
    
    private var creditsHeader: some View {
        HiCard {
            VStack(spacing: HiTheme.spacingSM) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(creditsManager.credits)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("credits")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Text("1 credit = 1 prompt = 4 images")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Share & Earn Card
    
    private var shareAndEarnCard: some View {
        HiCard {
            if let code = creditsManager.referralCode {
                // Has code - show it
                VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Your referral code")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text(code)
                            .font(.body.monospaced().bold())
                        
                        Spacer()
                        
                        Button {
                            copyCode(code)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        ShareLink(item: shareText(code: code)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    
                    Text("You earn 5 credits when friends use your code")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                // No code - prompt to create
                VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.accentColor)
                        Text("Invite friends, earn credits")
                            .font(.headline)
                    }
                    
                    Text("Get 5 free credits for each friend who joins")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showReferralCode = true
                    } label: {
                        Text("Get Started")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    // MARK: - Keyboard Status Card
    
    private var keyboardStatusCard: some View {
        Button {
            if keyboardStatus != .ready {
                showKeyboardSetup = true
            }
        } label: {
            HiCard {
                HStack(spacing: HiTheme.spacingMD) {
                    // Status icon
                    Group {
                        switch keyboardStatus {
                        case .checking:
                            ProgressView()
                        case .notInstalled, .noFullAccess:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                        case .ready:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.title2)
                    .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keyboard")
                            .font(.headline)
                        Text(keyboardStatus.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if keyboardStatus != .ready {
                        Text("Setup")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        Button {
            showAllOptions = true
        } label: {
            HiCard {
                HStack(spacing: HiTheme.spacingMD) {
                    Image(systemName: subscriptionIcon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionTitle)
                            .font(.headline)
                        Text(subscriptionSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var subscriptionIcon: String {
        creditsManager.subscriptionTier == .none ? "star" : "star.fill"
    }
    
    private var subscriptionTitle: String {
        creditsManager.subscriptionTier == .none ? "Free tier" : creditsManager.subscriptionTier.displayName
    }
    
    private var subscriptionSubtitle: String {
        creditsManager.subscriptionTier == .none ? "Tap to view plans" : "Tap to manage"
    }
    
    // MARK: - Settings Card
    
    private var settingsCard: some View {
        Button {
            showSettings = true
        } label: {
            HiCard {
                HStack(spacing: HiTheme.spacingMD) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                    
                    Text("Settings")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                // Auto-show setup if not installed
                showKeyboardSetup = true
            }
        }
    }
    
    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func shareText(code: String) -> String {
        "Try hi-key! Generate AI images right from your keyboard. Use my code \(code) and we both get 5 free credits!"
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
    HomeView()
}
