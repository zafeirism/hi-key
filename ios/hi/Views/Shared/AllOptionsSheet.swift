import SwiftUI

struct AllPlansSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditsManager = CreditsManager.shared

    let onComplete: (() -> Void)?

    @State private var selectedTab: Tab = .subscriptions
    @State private var selectedSubscription: SubscriptionTier = .pro
    @State private var selectedPack: CreditPack? = nil
    @State private var isProcessing: Bool = false
    @State private var showTerms: Bool = false

    enum Tab {
        case subscriptions
        case onDemand
    }

    var body: some View {
        VStack(spacing: 0) {
            HiSheetHeader(title: "Select a plan", onClose: { dismiss() })

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
                isSecondary: isDowngrade,
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
        .padding(.horizontal, HiTheme.spacingMD)
        .sheet(isPresented: $showTerms) {
            TermsSheet()
        }
        .onAppear {
            configureDefaults()
        }
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: "Subscriptions", icon: "calendar.badge.checkmark", tab: .subscriptions)
            tabButton(title: "One-time", icon: "hand.point.up.left", tab: .onDemand)
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

    // MARK: - Subscription Options

    private var subscriptionOptions: some View {
        ForEach(SubscriptionTier.allCases.filter { $0 != .none }, id: \.self) { tier in
            let isCurrent = creditsManager.subscriptionTier == tier
            PaywallOptionCard(
                title: tier.displayName,
                subtitle: tier.creditsText,
                price: tier.price,
                isSelected: selectedSubscription == tier && selectedPack == nil,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = nil
                        selectedSubscription = tier
                    }
                },
                label: tier == .pro && !isCurrent ? "BEST VALUE" : nil,
                isCurrentPlan: isCurrent
            )
        }
    }

    // MARK: - Pack Options

    private var packOptions: some View {
        ForEach(CreditPack.allCases, id: \.self) { pack in
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

    // MARK: - CTA State

    private var isDowngrade: Bool {
        guard selectedPack == nil else { return false }
        let currentTier = creditsManager.subscriptionTier
        return currentTier != .none && selectedSubscription.monthlyAmount < currentTier.monthlyAmount
    }

    private var purchaseButtonText: String {
        if let pack = selectedPack {
            return "Buy for \(pack.price)"
        }

        let currentTier = creditsManager.subscriptionTier
        let price = selectedSubscription.price.replacingOccurrences(of: " / mo", with: "/month")

        if currentTier == .none {
            return "Subscribe for \(price)"
        } else if selectedSubscription.monthlyAmount > currentTier.monthlyAmount {
            return "Upgrade for \(price)"
        } else if selectedSubscription.monthlyAmount < currentTier.monthlyAmount {
            return "Downgrade for \(price)"
        }
        return "Subscribe for \(price)"
    }

    // MARK: - Configuration

    private func configureDefaults() {
        let currentTier = creditsManager.subscriptionTier

        // If user is on pro, default to one-time tab
        if currentTier == .pro {
            selectedTab = .onDemand
            selectedPack = .mini
            selectedSubscription = .plus
            return
        }

        // Default selection is the next tier up from current
        switch currentTier {
        case .none:
            selectedSubscription = .pro
        case .lite:
            selectedSubscription = .plus
        case .plus, .pro:
            selectedSubscription = .pro
        }
    }

    // MARK: - Actions

    private func processPurchase() {
        isProcessing = true

        // TODO: Implement StoreKit purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let pack = selectedPack {
                creditsManager.addCredits(pack.credits)
            } else {
                creditsManager.setSubscription(selectedSubscription)
                creditsManager.addCredits(selectedSubscription.monthlyPrompts)
            }
            isProcessing = false
            onComplete?()
            dismiss()
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

#Preview("All Plans") {
    AllPlansSheet(onComplete: nil)
        .background(HiTheme.backgroundRoot)
}
