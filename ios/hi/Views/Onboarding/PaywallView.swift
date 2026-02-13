import SwiftUI

// MARK: - PaywallView

struct PaywallView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @ObservedObject var creditsManager = CreditsManager.shared

    // MARK: - State

    enum PaywallState {
        case main
        case finalOffer
    }

    @State private var paywallState: PaywallState = .main
    @State private var selectedSubscription: PaywallSubscription = .superTier
    @State private var selectedPack: PaywallPack? = nil
    @State private var showAllPlans: Bool = false
    @State private var showOnlyPacks: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showTerms: Bool = false

    // MARK: - Product Definitions (hardcoded for now)

    enum PaywallSubscription: String, CaseIterable {
        case starter
        case plus
        case superTier

        var displayName: String {
            switch self {
            case .starter: return "Starter"
            case .plus: return "Plus"
            case .superTier: return "Super"
            }
        }

        var creditsText: String {
            switch self {
            case .starter: return "25 credits / month"
            case .plus: return "50 credits / month"
            case .superTier: return "110 credits / month"
            }
        }

        var price: String {
            switch self {
            case .starter: return "$4.99 / mo"
            case .plus: return "$6.99 / mo"
            case .superTier: return "$12.99 / mo"
            }
        }

        var monthlyAmount: Decimal {
            switch self {
            case .starter: return 4.99
            case .plus: return 6.99
            case .superTier: return 12.99
            }
        }

        var discountedPrice: String {
            return "$9.99 / mo"
        }

        var originalPrice: String {
            return "$12.99"
        }

        var creditsManagerTier: SubscriptionTier {
            switch self {
            case .starter: return .lite
            case .plus: return .plus
            case .superTier: return .pro
            }
        }

        var monthlyCredits: Int {
            switch self {
            case .starter: return 25
            case .plus: return 50
            case .superTier: return 110
            }
        }
    }

    enum PaywallPack: String, CaseIterable {
        case mini
        case big

        var displayName: String {
            switch self {
            case .mini: return "Mini pack"
            case .big: return "Big pack"
            }
        }

        var creditsText: String {
            switch self {
            case .mini: return "10 credits, one-time"
            case .big: return "25 credits, one-time"
            }
        }

        var price: String {
            switch self {
            case .mini: return "$2.99"
            case .big: return "$5.99"
            }
        }

        var creditsManagerPack: CreditPack {
            switch self {
            case .mini: return .mini
            case .big: return .big
            }
        }

        var credits: Int {
            switch self {
            case .mini: return 10
            case .big: return 25
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Lottie animation in background (upper half area)
            VStack {
                if paywallState == .finalOffer {
                    LottieView(name: "paywall-offer", loop: false, scaleAspectFill: true)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                }
                else {
                    LottieView(name: "paywall", loop: false, scaleAspectFill: true)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                }
                Spacer()
            }
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    closeButton
                }
                .padding(.top, HiTheme.spacingMD)
                .padding(.horizontal, HiTheme.spacingMD)
                
                Spacer()
                
                // Content area
                mainContent
                    .padding(.horizontal, HiTheme.spacingMD)
            }
            .id(paywallState)
            .transition(.asymmetric(
                insertion: .opacity
                    .animation(.easeInOut(duration: 0.3).delay(0.65)),
                removal: .opacity
                    .animation(.easeInOut(duration: 0.1))
            ))
        }
        .sheet(isPresented: $showAllPlans) {
            AllPlansSheet(
                selectedSubscription: $selectedSubscription,
                selectedPack: $selectedPack,
                onPurchase: { processPurchase() },
                onRestore: { restorePurchases() },
                isProcessing: $isProcessing,
                showTerms: $showTerms
            )
            .presentationDetents([.fraction(0.8)])
            .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showOnlyPacks) {
            OnlyPacksSheet(
                selectedPack: $selectedPack,
                onPurchase: { processPurchase() },
                onNotNow: {
                    showOnlyPacks = false
                    withAnimation{//}(.easeInOut(duration: 2.3)) {
                        paywallState = .finalOffer
                        selectedSubscription = .superTier
                        selectedPack = nil
                    }
                },
                onRestore: { restorePurchases() },
                isProcessing: $isProcessing,
                showTerms: $showTerms
            )
            .presentationDetents([.fraction(0.7)])
            .background(HiTheme.backgroundRoot)
            .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showTerms) {
            TermsSheet()
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            handleDismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(HiTheme.iconDefault)
                .frame(width: 40, height: 40)
                .background(HiTheme.surfacePrimary.opacity(0.5))
                .clipShape(Circle())
                .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding(.bottom, HiTheme.spacingXL)

            // Option cards
            optionCards
                .padding(.bottom, HiTheme.spacingMD)

            // View all plans link
            // paywallState == .finalOffer ?
            if paywallState == .main {
                HStack {
                    Spacer()
                    
                    Button {
                        showAllPlans = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("View all plans")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(HiTertiaryButtonStyle())
                    .padding(.trailing, HiTheme.spacingSM)
                }
            }

            // Hint
            PaywallHintView(type: paywallState == .main ? .subscription : .offer)
                .padding(.top, HiTheme.spacingXXL)
                .padding(.bottom, HiTheme.spacingMD)

            // Purchase button
            PaywallCTAButton(
                text: purchaseButtonText,
                isProcessing: isProcessing,
                action: { processPurchase() }
            )
            .padding(.bottom, HiTheme.spacingXL)

            // Footer links
            PaywallFooterLinks(
                onRestore: { restorePurchases() },
                onTerms: { showTerms = true }
            )
            .padding(.horizontal, HiTheme.spacingMD)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
            Group {
                switch paywallState {
                case .main:
                    Text("Keep your creativity\nflowing.")
                case .finalOffer:
                    Text("25% discount on Super.")
                }
            }
            .font(.system(.title, design: .rounded, weight: .semibold))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                switch paywallState {
                case .main:
                    Text("Never run out of credits. One credit generates 4 images from your prompt.")
                case .finalOffer:
                    Text("We really want you to try hi-key. Claim your limited-time offer now. Let's do this.")
                }
            }
            .font(.body.weight(.medium))
            .foregroundStyle(HiTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Option Cards

    private var optionCards: some View {
        VStack(spacing: HiTheme.spacingSM) {
            // Plus subscription
            PaywallOptionCard(
                title: PaywallSubscription.plus.displayName,
                subtitle: PaywallSubscription.plus.creditsText,
                price: PaywallSubscription.plus.price,
                isSelected: selectedSubscription == .plus && selectedPack == nil,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = nil
                        selectedSubscription = .plus
                    }
                }
            )

            // Super subscription
            PaywallOptionCard(
                title: PaywallSubscription.superTier.displayName,
                subtitle: PaywallSubscription.superTier.creditsText,
                price: paywallState == .finalOffer ? PaywallSubscription.superTier.discountedPrice : PaywallSubscription.superTier.price,
                isSelected: selectedSubscription == .superTier && selectedPack == nil,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = nil
                        selectedSubscription = .superTier
                    }
                },
                discountBadge: paywallState == .finalOffer ? "-25%" : nil,
                originalPrice: paywallState == .finalOffer ? "$12.99" : nil//PaywallSubscription.superTier.originalPrice : nil
            )
        }
    }

    private var purchaseButtonText: String {
        if let pack = selectedPack {
            return "Buy for \(pack.price)"
        }

        switch paywallState {
        case .main:
            return "Subscribe for \(selectedSubscription == .superTier ? "$12.99" : "$6.99")/month"
        case .finalOffer:
            return "Subscribe for \(selectedSubscription == .superTier ? "$9.99" : "$6.99")/month"
        }
    }

    // MARK: - Actions

    private func handleDismiss() {
        switch paywallState {
        case .main:
            showOnlyPacks = true
        case .finalOffer:
            onboardingManager.completeOnboarding()
        }
    }

    private func processPurchase() {
        isProcessing = true

        // TODO: Implement StoreKit purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let pack = selectedPack {
                creditsManager.addCredits(pack.credits)
            } else {
                creditsManager.setSubscription(selectedSubscription.creditsManagerTier)
                creditsManager.addCredits(selectedSubscription.monthlyCredits)
            }
            isProcessing = false
            onboardingManager.completeOnboarding()
        }
    }

    private func restorePurchases() {
        isProcessing = true

        // TODO: Implement StoreKit restore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
        }
    }
}

// MARK: - Reusable Components

private struct PaywallHintView: View {
    enum HintType {
        case subscription
        case onDemand
        case offer
    }

    let type: HintType

    var body: some View {
        HStack(spacing: HiTheme.spacingSM) {
            Image(systemName: iconName)
                .foregroundStyle(type == .offer ? HiTheme.accentSecondary : HiTheme.statusGreen)
                .font(.body.weight(.semibold))
            Text(text)
                .font(.headline.weight(.semibold))
                .foregroundStyle(HiTheme.textPrimary)
        }
    }

    private var iconName: String {
        switch type {
        case .subscription: return "checkmark.shield.fill"
        case .onDemand: return "creditcard"
        case .offer: return "star.hexagon"
        }
    }

    private var text: String {
        switch type {
        case .subscription: return "No commitment, cancel anytime."
        case .onDemand: return "One-time purchase. Valid for 12 months."
        case .offer: return "Offer is valid for today, cancel anytime."
        }
    }
}

/// CTA button for purchase actions
private struct PaywallCTAButton: View {
    let text: String
    let isProcessing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isProcessing {
                ProgressView()
                    .tint(HiTheme.backgroundRoot)
            } else {
                Text(text)
            }
        }
        .buttonStyle(HiPrimaryButtonStyle(isEnabled: !isProcessing))
        .disabled(isProcessing)
    }
}

/// Footer links for restore and terms
private struct PaywallFooterLinks: View {
    let onRestore: () -> Void
    let onTerms: () -> Void

    var body: some View {
        HStack {
            Button("Restore Purchases", action: onRestore)
                .font(.callout)
                .foregroundStyle(HiTheme.textSecondary)

            Spacer()

            Button("Terms & Privacy", action: onTerms)
                .font(.callout)
                .foregroundStyle(HiTheme.textSecondary)
        }
    }
}

// MARK: - Paywall Option Card

private struct PaywallOptionCard: View {
    let title: String
    let subtitle: String
    let price: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var discountBadge: String? = nil
    var originalPrice: String? = nil
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                    HStack(spacing: HiTheme.spacingSM){
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(HiTheme.textPrimary)
                        
                        if (discountBadge != nil){
                            Text(discountBadge!)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(HiTheme.accentSecondary)
                                .padding(.horizontal, HiTheme.spacingSM)
                                .padding(.vertical, HiTheme.spacingXS)
                                .background(HiTheme.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                                .overlay(
                                    RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                                        .stroke(HiTheme.accentSecondary, lineWidth: 1)
                                )
                        }
                    }
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HiTheme.textSecondary)
                }

                Spacer()

                if (originalPrice != nil) {
                    Text(originalPrice!)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HiTheme.textTertiary)
                        .strikethrough()
                        .padding(.trailing, HiTheme.spacingXS)
                }
                
                Text(price)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(HiTheme.textPrimary)
                    .padding(.trailing, HiTheme.spacingSM)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HiTheme.accentPrimary : HiTheme.textSecondary)
                    .font(.title2)
            }
            .padding(.horizontal, HiTheme.spacingMD)
            .padding(.vertical, HiTheme.spacingMD + 2)
            //.frame(height: PaywallConstants.optionCardHeight)
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusXL)
                    .stroke(isSelected ? HiTheme.accentPrimary : HiTheme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Plans Sheet

private struct AllPlansSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSubscription: PaywallView.PaywallSubscription
    @Binding var selectedPack: PaywallView.PaywallPack?
    let onPurchase: () -> Void
    let onRestore: () -> Void
    @Binding var isProcessing: Bool
    @Binding var showTerms: Bool

    @State private var selectedTab: Tab = .subscriptions

    enum Tab {
        case subscriptions
        case onDemand
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Choose your plan")
                    .font(.headline)

                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HiTheme.iconDefault)
                            .frame(width: 32, height: 32)
                            .background(HiTheme.surfaceSecondary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
                    }
                }
            }
            .padding(.top, HiTheme.spacingMD)
            .padding(.bottom, HiTheme.spacingXL)

            tabSwitcher
            .padding(.bottom, HiTheme.spacingLG)

            VStack(spacing: HiTheme.spacingSM) {
                if selectedTab == .subscriptions {
                    subscriptionOptions
                } else {
                    packOptions
                }
            }
            .padding(.bottom, HiTheme.spacingLG)

            Spacer()
            
            // Hint
            PaywallHintView(type: selectedTab == .subscriptions ? .subscription : .onDemand)
                .padding(.bottom, HiTheme.spacingMD)

            // Purchase button
            PaywallCTAButton(
                text: purchaseButtonText,
                isProcessing: isProcessing,
                action: onPurchase
            )
            .padding(.bottom, HiTheme.spacingXL)

            // Footer links
            PaywallFooterLinks(
                onRestore: onRestore,
                onTerms: { showTerms = true }
            )
            .padding(.horizontal, HiTheme.spacingMD)
        }
        .padding(.horizontal, HiTheme.spacingMD)
    }
    
    private var tabSwitcher: some View {
            HStack(spacing: 0) {
                tabButton(title: "Subscriptions", icon: "calendar.badge.checkmark", tab: .subscriptions)
                tabButton(title: "On demand", icon: "hand.point.up.left", tab: .onDemand)
            }
            .padding(HiTheme.spacingXS)
            .background(HiTheme.surfacePrimary)
            .clipShape(Capsule())
        }

        private func tabButton(title: String, icon: String, tab: Tab) -> some View {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedTab = tab
                    if tab == .onDemand && selectedPack == nil {
                        selectedPack = .mini
                    } else if tab == .subscriptions {
                        selectedPack = nil
                    }
                }
            } label: {
                VStack(spacing: HiTheme.spacingXS) {
                    Image(systemName: icon)
                        .font(.title3.weight(.medium))
                    Text(title)
                        .font(.headline.weight(.medium))
                }
                .foregroundStyle(selectedTab == tab ? HiTheme.accentPrimary : HiTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HiTheme.spacingXS)
                .background(selectedTab == tab ? HiTheme.surfaceSecondary : HiTheme.surfacePrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }

    private var subscriptionOptions: some View {
        ForEach(Array(PaywallView.PaywallSubscription.allCases.enumerated()), id: \.element) { _, subscription in
            PaywallOptionCard(
                title: subscription.displayName,
                subtitle: subscription.creditsText,
                price: subscription.price,
                isSelected: selectedSubscription == subscription && selectedPack == nil,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = nil
                        selectedSubscription = subscription
                    }
                }
            )
        }
    }

    private var packOptions: some View {
        ForEach(Array(PaywallView.PaywallPack.allCases.enumerated()), id: \.element) { _, pack in
            PaywallOptionCard(
                title: pack.displayName,
                subtitle: pack.creditsText,
                price: pack.price,
                isSelected: selectedPack == pack,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = pack
                    }
                }
            )
        }
    }

    private var purchaseButtonText: String {
        if let pack = selectedPack {
            return "Buy for \(pack.price)"
        }
        return "Subscribe for \(selectedSubscription.price.replacingOccurrences(of: " / mo", with: "/month"))"
    }
}

// MARK: - Dismiss Offer Sheet

private struct OnlyPacksSheet: View {
    @Binding var selectedPack: PaywallView.PaywallPack?
    let onPurchase: () -> Void
    let onNotNow: () -> Void
    let onRestore: () -> Void
    @Binding var isProcessing: Bool
    @Binding var showTerms: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("Don't like subscriptions?")
                .font(.title2.weight(.semibold))
                .padding(.top, HiTheme.spacingLG)
                .padding(.bottom, HiTheme.spacingSM)
            
            Text("Purchase credits on demand. No recurring costs.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HiTheme.textSecondary)
                .padding(.bottom, HiTheme.spacingXXL)
            
            // Pack options
            VStack(spacing: HiTheme.spacingSM) {
                ForEach(PaywallView.PaywallPack.allCases, id: \.self) { pack in
                    PaywallOptionCard(
                        title: pack.displayName,
                        subtitle: pack.creditsText,
                        price: pack.price,
                        isSelected: selectedPack == pack,
                        onSelect: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedPack = pack
                            }
                        }
                    )
                }
            }
            .padding(.bottom, HiTheme.spacingLG)

            Spacer()
            
            // Hint
            PaywallHintView(type: .onDemand)
                .padding(.bottom, HiTheme.spacingMD)

            // Purchase button
            PaywallCTAButton(
                text: "Buy for \(selectedPack?.price ?? "$2.99")",
                isProcessing: isProcessing,
                action: onPurchase
            )
            .padding(.bottom, HiTheme.spacingLG)

            // Not now button
            Button(action: onNotNow) {
                Text("Not now, thanks")
                    .foregroundStyle(HiTheme.textSecondary)
            }
            .buttonStyle(HiTertiaryButtonStyle())
            .padding(.bottom, HiTheme.spacingXL)

            // Footer links
            PaywallFooterLinks(
                onRestore: onRestore,
                onTerms: { showTerms = true }
            )
            .padding(.horizontal, HiTheme.spacingLG)
        }
        .padding(.horizontal, HiTheme.spacingMD)
        .onAppear {
            if selectedPack == nil {
                selectedPack = .mini
            }
        }
    }
}

// MARK: - Preview

#Preview("Main Paywall") {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()

        PaywallView()
    }
}
