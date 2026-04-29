import SwiftUI
import RevenueCat

// MARK: - PaywallView

struct PaywallView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @ObservedObject var purchasesManager = PurchasesManager.shared

    @State private var selectedPackage: Package? = nil
    @State private var selectedPackInOnlyPacks: Package? = nil
    @State private var showAllPlans: Bool = false
    @State private var showOnlyPacks: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showTerms: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Lottie animation in background (upper half area)
            VStack {
                LottieView(name: "paywall-no-mountains", loop: false, scaleAspectFill: true)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                Spacer()
            }
            .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                Spacer()

                mainContent
                    .padding(.horizontal, HiTheme.spacingMD)
            }
        }
        .sheet(isPresented: $showAllPlans) {
            AllPlansSheet(onComplete: { onboardingManager.completeOnboarding() })
                //.presentationDetents([.fraction(0.85)])
                .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showOnlyPacks, onDismiss: {
            selectedPackInOnlyPacks = nil
        }) {
            OnlyPacksSheet(
                selectedPackage: $selectedPackInOnlyPacks,
                onPurchase: { processPackPurchase() },
                onNotNow: {
                    showOnlyPacks = false
                    onboardingManager.completeOnboarding()
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
        .onAppear { selectDefaultPackageIfNeeded() }
        .onReceive(purchasesManager.$offerings) { _ in selectDefaultPackageIfNeeded() }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.bottom, HiTheme.spacingXL)

            optionCards
                .padding(.bottom, HiTheme.spacingSM)

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
            }

            PaywallHintView(type: subscriptionHintType)
                .padding(.top, HiTheme.spacingXXL)
                .padding(.bottom, HiTheme.spacingMD)

            PaywallCTAButton(
                text: purchaseButtonText,
                isProcessing: isProcessing,
                action: { processPurchase() }
            )
            .padding(.bottom, HiTheme.spacingXL)

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
            Text("Your keyboard is about to get a lot more fun.")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Every 100 credits with default AI models is ~15 generations × 4 images each.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Option Cards

    private var optionCards: some View {
        VStack(spacing: HiTheme.spacingSM) {
            ForEach(visibleSubscriptionPackages, id: \.storeProduct.productIdentifier) { package in
                let productID = package.storeProduct.productIdentifier
                PaywallOptionCard(
                    title: purchasesManager.tierDisplayName(for: productID) ?? package.storeProduct.localizedTitle,
                    subtitle: subtitleForPackage(package),
                    price: priceForPackage(package),
                    isSelected: selectedPackage?.storeProduct.productIdentifier == productID,
                    onSelect: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedPackage = package
                        }
                    },
                    label: labelForPackage(package),
                    accessory: accessoryForPackage(package)
                )
            }
        }
    }

    private func accessoryForPackage(_ package: Package) -> AnyView? {
        guard purchasesManager.isTrialEligible(for: package.storeProduct.productIdentifier) else { return nil }
        return AnyView(TrialReminderRow())
    }

    private func labelForPackage(_ package: Package) -> String? {
        let id = package.storeProduct.productIdentifier
        if purchasesManager.isTrialEligible(for: id) {
            return "3 DAYS FREE"
        }
        return id == "super.weekly" ? "BEST VALUE" : nil
    }

    // Starter is only surfaced through "View all plans" so the primary paywall stays focused.
    private var visibleSubscriptionPackages: [Package] {
        purchasesManager.subscriptionPackages().filter {
            $0.storeProduct.productIdentifier != "starter.weekly"
        }
    }

    private func subtitleForPackage(_ package: Package) -> String {
        let id = package.storeProduct.productIdentifier
        if let credits = purchasesManager.weeklyCredits(for: id) {
            if purchasesManager.isTrialEligible(for: id),
               let trialCredits = purchasesManager.trialCredits(for: id) {
                return "\(trialCredits) free, then \(credits) / week"
            }
            return "\(credits) credits / week"
        }
        if let credits = purchasesManager.packCredits(for: id) {
            return "\(credits) credits, one-time"
        }
        return ""
    }

    private func priceForPackage(_ package: Package) -> String {
        let base = package.storeProduct.localizedPriceString
        if purchasesManager.weeklyCredits(for: package.storeProduct.productIdentifier) != nil {
            return "\(base)/week"
        }
        return base
    }

    private var purchaseButtonText: String {
        guard let package = selectedPackage else {
            return "Choose a plan"
        }
        let id = package.storeProduct.productIdentifier
        if purchasesManager.isTrialEligible(for: id) {
            return "Start free trial"
        }
        if purchasesManager.weeklyCredits(for: id) != nil {
            return "Subscribe for \(package.storeProduct.localizedPriceString)/week"
        }
        return "Buy for \(package.storeProduct.localizedPriceString)"
    }

    private var subscriptionHintType: PaywallHintView.HintType {
        if let id = selectedPackage?.storeProduct.productIdentifier,
           purchasesManager.isTrialEligible(for: id) {
            return .trial
        }
        return .subscription
    }

    // MARK: - Actions

    private func selectDefaultPackageIfNeeded() {
        guard selectedPackage == nil else { return }
        selectedPackage = purchasesManager.package(forProductID: "super.weekly")
            ?? visibleSubscriptionPackages.first
    }

    private func processPurchase() {
        guard let package = selectedPackage else { return }
        isProcessing = true
        Task {
            do {
                _ = try await PurchasesManager.shared.purchase(package)
                isProcessing = false
                onboardingManager.completeOnboarding()
            } catch PurchasesManagerError.cancelled {
                isProcessing = false
            } catch {
                isProcessing = false
                HiLogger.error("Paywall purchase failed", error: error)
            }
        }
    }

    private func processPackPurchase() {
        guard let package = selectedPackInOnlyPacks else { return }
        isProcessing = true
        Task {
            do {
                _ = try await PurchasesManager.shared.purchase(package)
                isProcessing = false
                showOnlyPacks = false
                onboardingManager.completeOnboarding()
            } catch PurchasesManagerError.cancelled {
                isProcessing = false
            } catch {
                isProcessing = false
                HiLogger.error("Paywall pack purchase failed", error: error)
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
                    onboardingManager.completeOnboarding()
                }
            } catch {
                isProcessing = false
                HiLogger.error("Paywall restore failed", error: error)
            }
        }
    }
}

// MARK: - Only Packs Sheet

private struct OnlyPacksSheet: View {
    @ObservedObject var purchasesManager = PurchasesManager.shared
    @Binding var selectedPackage: Package?
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

            VStack(spacing: HiTheme.spacingSM) {
                ForEach(purchasesManager.packPackages(), id: \.storeProduct.productIdentifier) { package in
                    let id = package.storeProduct.productIdentifier
                    PaywallOptionCard(
                        title: purchasesManager.packDisplayName(for: id) ?? package.storeProduct.localizedTitle,
                        subtitle: purchasesManager.packCredits(for: id).map { "\($0) credits, one-time" } ?? "",
                        price: package.storeProduct.localizedPriceString,
                        isSelected: selectedPackage?.storeProduct.productIdentifier == id,
                        onSelect: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedPackage = package
                            }
                        }
                    )
                }
            }
            .padding(.bottom, HiTheme.spacingLG)

            Spacer()

            PaywallHintView(type: .onDemand)
                .padding(.bottom, HiTheme.spacingMD)

            PaywallCTAButton(
                text: selectedPackage.map { "Buy for \($0.storeProduct.localizedPriceString)" } ?? "Choose a pack",
                isProcessing: isProcessing,
                action: onPurchase
            )
            .padding(.bottom, HiTheme.spacingSM)

            Button(action: onNotNow) {
                Text("Not now, thanks")
                    .foregroundStyle(HiTheme.textSecondary)
            }
            .buttonStyle(HiTertiaryButtonStyle())
            .padding(.bottom, HiTheme.spacingMD)

            PaywallFooterLinks(
                onRestore: onRestore,
                onTerms: { showTerms = true }
            )
            .padding(.horizontal, HiTheme.spacingLG)
        }
        .padding(.horizontal, HiTheme.spacingMD)
        .onAppear {
            if selectedPackage == nil {
                selectedPackage = purchasesManager.package(forProductID: "pack.mini")
                    ?? purchasesManager.packPackages().first
            }
        }
    }
}

// MARK: - Preview

#Preview("Main Paywall") {
    ZStack {
        HiAppBackground()

        PaywallView()
    }
}
