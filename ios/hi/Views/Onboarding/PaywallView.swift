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
    @State private var selectedSubscription: SubscriptionTier = .pro
    @State private var selectedPack: CreditPack? = nil
    @State private var showAllPlans: Bool = false
    @State private var showOnlyPacks: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showTerms: Bool = false

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
            AllPlansSheet(onComplete: { onboardingManager.completeOnboarding() })
                .presentationDetents([.fraction(0.8)])
                .background(HiTheme.backgroundRoot)
        }
        .sheet(isPresented: $showOnlyPacks) {
            OnlyPacksSheet(
                selectedPack: $selectedPack,
                onPurchase: { processPurchase() },
                onNotNow: {
                    showOnlyPacks = false
                    withAnimation {
                        paywallState = .finalOffer
                        selectedSubscription = .pro
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
                    Text("We really want you to try hi-key. 25% off on the already best-value plan. Claim it now.")
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
                title: SubscriptionTier.plus.displayName,
                subtitle: SubscriptionTier.plus.creditsText,
                price: SubscriptionTier.plus.price,
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
                title: SubscriptionTier.pro.displayName,
                subtitle: SubscriptionTier.pro.creditsText,
                price: paywallState == .finalOffer ? "$9.99 / mo" : SubscriptionTier.pro.price,
                isSelected: selectedSubscription == .pro && selectedPack == nil,
                onSelect: {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selectedPack = nil
                        selectedSubscription = .pro
                    }
                },
                discountBadge: paywallState == .finalOffer ? "-25%" : nil,
                originalPrice: paywallState == .finalOffer ? "$12.99" : nil,
                label: paywallState == .finalOffer ? nil : "BEST VALUE"
            )
        }
    }

    private var purchaseButtonText: String {
        if let pack = selectedPack {
            return "Buy for \(pack.price)"
        }

        switch paywallState {
        case .main:
            return "Subscribe for \(selectedSubscription == .pro ? "$12.99" : "$6.99")/month"
        case .finalOffer:
            return "Subscribe for \(selectedSubscription == .pro ? "$9.99" : "$6.99")/month"
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
                creditsManager.setSubscription(selectedSubscription)
                creditsManager.addCredits(selectedSubscription.monthlyPrompts)
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

// MARK: - Dismiss Offer Sheet

private struct OnlyPacksSheet: View {
    @Binding var selectedPack: CreditPack?
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
