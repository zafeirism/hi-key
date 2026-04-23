import SwiftUI
import RevenueCat

struct AllPlansSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchasesManager = PurchasesManager.shared

    let onComplete: (() -> Void)?

    @State private var selectedTab: Tab = .subscriptions
    @State private var selectedSubscriptionPackage: Package? = nil
    @State private var selectedPackPackage: Package? = nil
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

            PaywallHintView(type: selectedTab == .subscriptions ? .subscription : .onDemand)
                .padding(.bottom, HiTheme.spacingMD)

            PaywallCTAButton(
                text: purchaseButtonText,
                isProcessing: isProcessing,
                isSecondary: isDowngrade,
                action: { processPurchase() }
            )
            .padding(.bottom, HiTheme.spacingXL)

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
        .onAppear { configureDefaults() }
        .onReceive(purchasesManager.$offerings) { _ in configureDefaults() }
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
                if tab == .onDemand && selectedPackPackage == nil {
                    selectedPackPackage = purchasesManager.package(forProductID: "pack.mini")
                        ?? purchasesManager.packPackages().first
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
        ForEach(purchasesManager.subscriptionPackages(), id: \.storeProduct.productIdentifier) { package in
            let id = package.storeProduct.productIdentifier
            let isCurrent = purchasesManager.activeSubscriptionProductID == id
            let isBestValue = id == "super.weekly" && !isCurrent
            PaywallOptionCard(
                title: purchasesManager.tierDisplayName(for: id) ?? package.storeProduct.localizedTitle,
                subtitle: (purchasesManager.weeklyCredits(for: id).map { "\($0) credits / week" }) ?? "",
                price: "\(package.storeProduct.localizedPriceString)/week",
                isSelected: selectedSubscriptionPackage?.storeProduct.productIdentifier == id,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedSubscriptionPackage = package
                    }
                },
                label: isBestValue ? "BEST VALUE" : nil,
                isCurrentPlan: isCurrent
            )
        }
    }

    // MARK: - Pack Options

    private var packOptions: some View {
        ForEach(purchasesManager.packPackages(), id: \.storeProduct.productIdentifier) { package in
            let id = package.storeProduct.productIdentifier
            PaywallOptionCard(
                title: purchasesManager.packDisplayName(for: id) ?? package.storeProduct.localizedTitle,
                subtitle: purchasesManager.packCredits(for: id).map { "\($0) credits, one-time" } ?? "",
                price: package.storeProduct.localizedPriceString,
                isSelected: selectedPackPackage?.storeProduct.productIdentifier == id,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPackPackage = package
                    }
                }
            )
        }
    }

    // MARK: - CTA State

    private var isDowngrade: Bool {
        guard selectedTab == .subscriptions,
              let selectedID = selectedSubscriptionPackage?.storeProduct.productIdentifier,
              let currentID = purchasesManager.activeSubscriptionProductID,
              let selectedLevel = purchasesManager.level(for: selectedID),
              let currentLevel = purchasesManager.level(for: currentID) else {
            return false
        }
        // Lower level = higher tier, so downgrade = selected level number greater than current.
        return selectedLevel > currentLevel
    }

    private var purchaseButtonText: String {
        if selectedTab == .onDemand {
            return selectedPackPackage.map { "Buy for \($0.storeProduct.localizedPriceString)" } ?? "Choose a pack"
        }

        guard let selectedID = selectedSubscriptionPackage?.storeProduct.productIdentifier,
              let price = selectedSubscriptionPackage?.storeProduct.localizedPriceString else {
            return "Choose a plan"
        }
        let formattedPrice = "\(price)/week"

        guard let currentID = purchasesManager.activeSubscriptionProductID,
              let selectedLevel = purchasesManager.level(for: selectedID),
              let currentLevel = purchasesManager.level(for: currentID) else {
            return "Subscribe for \(formattedPrice)"
        }

        if selectedID == currentID {
            return "Subscribe for \(formattedPrice)"
        }
        if selectedLevel < currentLevel {
            return "Upgrade for \(formattedPrice)"
        }
        return "Downgrade for \(formattedPrice)"
    }

    // MARK: - Configuration

    private func configureDefaults() {
        if selectedTab == .onDemand && selectedPackPackage == nil {
            selectedPackPackage = purchasesManager.package(forProductID: "pack.mini")
                ?? purchasesManager.packPackages().first
        }

        guard selectedSubscriptionPackage == nil else { return }

        let currentID = purchasesManager.activeSubscriptionProductID

        // If already on Super, bias toward one-time top-ups.
        if currentID == "super.weekly" {
            selectedTab = .onDemand
            if selectedPackPackage == nil {
                selectedPackPackage = purchasesManager.package(forProductID: "pack.mini")
                    ?? purchasesManager.packPackages().first
            }
            selectedSubscriptionPackage = purchasesManager.package(forProductID: "plus.weekly")
            return
        }

        // Default selection is the next tier up from current (or Super if free).
        let defaultProductID: String
        switch currentID {
        case "starter.weekly": defaultProductID = "plus.weekly"
        case "plus.weekly":    defaultProductID = "super.weekly"
        default:               defaultProductID = "super.weekly"
        }
        selectedSubscriptionPackage = purchasesManager.package(forProductID: defaultProductID)
            ?? purchasesManager.subscriptionPackages().first
    }

    // MARK: - Actions

    private func processPurchase() {
        let package: Package?
        switch selectedTab {
        case .subscriptions: package = selectedSubscriptionPackage
        case .onDemand:      package = selectedPackPackage
        }
        guard let package else { return }

        isProcessing = true
        Task {
            do {
                _ = try await PurchasesManager.shared.purchase(package)
                isProcessing = false
                onComplete?()
                dismiss()
            } catch PurchasesManagerError.cancelled {
                isProcessing = false
            } catch {
                isProcessing = false
                HiLogger.error("AllPlans purchase failed", error: error)
            }
        }
    }

    private func restorePurchases() {
        isProcessing = true
        Task {
            do {
                let info = try await PurchasesManager.shared.restore()
                isProcessing = false
                if !info.entitlements.active.isEmpty || !info.activeSubscriptions.isEmpty {
                    onComplete?()
                    dismiss()
                }
            } catch {
                isProcessing = false
                HiLogger.error("AllPlans restore failed", error: error)
            }
        }
    }
}

#Preview("All Plans") {
    AllPlansSheet(onComplete: nil)
        .background(HiTheme.backgroundRoot)
}
