import SwiftUI

struct AllOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @Binding var selectedSubscription: SubscriptionTier?
    @Binding var selectedPack: CreditPack?
    
    @State private var isProcessing: Bool = false
    @State private var showTerms: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HiTheme.spacingLG) {
                    // Subscriptions section
                    subscriptionsSection

                    // One-time packs section
                    packsSection

                    // Purchase button
                    if selectedSubscription != nil || selectedPack != nil {
                        purchaseButton
                    }

                    // Footer links
                    footerLinks
                }
                .padding(HiTheme.spacingMD)
            }
            .background(HiTheme.backgroundRoot)
            .navigationTitle("All Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsSheet()
        }
    }
    
    // MARK: - Subscriptions Section

    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
            Text("Subscriptions")
                .font(.headline)
                .foregroundStyle(HiTheme.textSecondary)

            VStack(spacing: HiTheme.spacingSM) {
                ForEach(SubscriptionTier.allCases.filter { $0 != .none }, id: \.self) { tier in
                    SubscriptionOptionCard(
                        tier: tier,
                        isSelected: selectedSubscription == tier,
                        isCurrent: creditsManager.subscriptionTier == tier,
                        onSelect: {
                            selectedPack = nil
                            selectedSubscription = tier
                        }
                    )
                }
            }
        }
    }

    // MARK: - Packs Section

    private var packsSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
            Text("Credit Packs")
                .font(.headline)
                .foregroundStyle(HiTheme.textSecondary)

            VStack(spacing: HiTheme.spacingSM) {
                ForEach(CreditPack.allCases, id: \.self) { pack in
                    PackOptionCard(
                        pack: pack,
                        isSelected: selectedPack == pack,
                        onSelect: {
                            selectedSubscription = nil
                            selectedPack = pack
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button {
            processPurchase()
        } label: {
            if isProcessing {
                ProgressView()
                    .tint(.white)
            } else {
                Text(purchaseButtonText)
            }
        }
        .buttonStyle(HiPrimaryButtonStyle(isEnabled: !isProcessing))
        .disabled(isProcessing)
    }
    
    private var purchaseButtonText: String {
        if let tier = selectedSubscription {
            return "Subscribe for \(tier.price)"
        } else if let pack = selectedPack {
            return "Buy for \(pack.price)"
        }
        return "Purchase"
    }
    
    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack(spacing: HiTheme.spacingXL) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(.footnote)
            .foregroundStyle(HiTheme.textSecondary)

            Button("Terms & Privacy") {
                showTerms = true
            }
            .font(.footnote)
            .foregroundStyle(HiTheme.textSecondary)
        }
        .padding(.top, HiTheme.spacingMD)
    }
    
    // MARK: - Actions
    
    private func processPurchase() {
        isProcessing = true
        
        // TODO: Implement StoreKit purchase
        // For now, simulate purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let tier = selectedSubscription {
                creditsManager.setSubscription(tier)
                creditsManager.addCredits(tier.monthlyPrompts)
            } else if let pack = selectedPack {
                creditsManager.addCredits(pack.credits)
            }
            isProcessing = false
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

// MARK: - Subscription Option Card

private struct SubscriptionOptionCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isCurrent: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: HiTheme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.displayName)
                            .font(.headline)
                            .foregroundStyle(HiTheme.textPrimary)

                        if tier == .pro {
                            Text("BEST")
                                .font(.caption2.bold())
                                .foregroundStyle(HiTheme.backgroundRoot)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HiTheme.accentPrimary)
                                .clipShape(Capsule())
                        }

                        if isCurrent {
                            Text("CURRENT")
                                .font(.caption2.bold())
                                .foregroundStyle(HiTheme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HiTheme.surfaceSecondary)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(tier.monthlyPrompts) prompts/month")
                        .font(.subheadline)
                        .foregroundStyle(HiTheme.textSecondary)

                    if tier == .pro {
                        Text("No watermark • Early features")
                            .font(.caption)
                            .foregroundStyle(HiTheme.textTertiary)
                    }
                }

                Spacer()

                Text(tier.price)
                    .font(.headline)
                    .foregroundStyle(HiTheme.textPrimary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HiTheme.accentPrimary : HiTheme.textSecondary)
                    .font(.title2)
            }
            .padding(HiTheme.spacingMD)
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusMD)
                    .stroke(isSelected ? HiTheme.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
        .opacity(isCurrent ? 0.6 : 1)
    }
}

// MARK: - Pack Option Card

private struct PackOptionCard: View {
    let pack: CreditPack
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: HiTheme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.displayName)
                        .font(.headline)
                        .foregroundStyle(HiTheme.textPrimary)

                    Text("\(pack.credits) credits • One-time")
                        .font(.subheadline)
                        .foregroundStyle(HiTheme.textSecondary)
                }

                Spacer()

                Text(pack.price)
                    .font(.headline)
                    .foregroundStyle(HiTheme.textPrimary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? HiTheme.accentPrimary : HiTheme.textSecondary)
                    .font(.title2)
            }
            .padding(HiTheme.spacingMD)
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusMD)
                    .stroke(isSelected ? HiTheme.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Terms Sheet

struct TermsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HiTheme.spacingLG) {
                    Text("Terms of Service")
                        .font(.title2.bold())
                        .foregroundStyle(HiTheme.textPrimary)

                    Text(termsText)
                        .font(.body)
                        .foregroundStyle(HiTheme.textSecondary)
                }
                .padding(HiTheme.spacingLG)
            }
            .background(HiTheme.backgroundRoot)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                }
            }
        }
    }

    private var termsText: String {
        """
        By subscribing to hi-key, you agree to the following terms:
        
        • Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.
        
        • Your account will be charged for renewal within 24 hours prior to the end of the current period.
        
        • You can manage and cancel subscriptions by going to your Account Settings on the App Store after purchase.
        
        • Any unused portion of a free trial period will be forfeited when you purchase a subscription.
        
        Privacy Policy:
        
        • We collect only the data necessary to provide our service.
        
        • Your prompts are processed to generate images and are not stored.
        
        • We do not sell your personal data to third parties.
        """
    }
}

#Preview("All Options") {
    AllOptionsSheet(selectedSubscription: .constant(nil), selectedPack: .constant(nil))
}
