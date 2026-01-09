import SwiftUI

struct PaywallView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @State private var selectedOption: PaywallOption = .liteSubscription
    @State private var isProcessing: Bool = false
    @State private var showAllOptions: Bool = false
    @State private var showTerms: Bool = false
    
    // For AllOptionsSheet
    @State private var allOptionsSubscription: SubscriptionTier? = nil
    @State private var allOptionsPack: CreditPack? = nil
    
    enum PaywallOption {
        case liteSubscription
        case miniPack
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                
                // Header
                headerSection
                
                Spacer()
                
                // Option cards
                optionCards
                
                // View all options link
                Button {
                    showAllOptions = true
                } label: {
                    Text("View all options")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, HiTheme.spacingMD)
                
                Spacer()
                Spacer()
                
                // Purchase button
                purchaseButton
                
                // Footer links
                footerLinks
            }
            .padding(.horizontal, HiTheme.spacingMD)
            .padding(.bottom, HiTheme.spacingLG)
            
            // Dismiss button (soft paywall)
            Button {
                onboardingManager.completeOnboarding()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .padding(HiTheme.spacingMD)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAllOptions) {
            AllOptionsSheet(
                selectedSubscription: $allOptionsSubscription,
                selectedPack: $allOptionsPack
            )
        }
        .sheet(isPresented: $showTerms) {
            TermsSheet()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            
            Text("Get more from hi-key")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Text("Start creating amazing images\nin all your conversations")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Option Cards
    
    private var optionCards: some View {
        VStack(spacing: HiTheme.spacingMD) {
            // Lite subscription
            PaywallOptionCard(
                title: "Lite",
                subtitle: "25 prompts per month",
                price: "$4.99/mo",
                isSelected: selectedOption == .liteSubscription,
                onSelect: { selectedOption = .liteSubscription }
            )
            
            // Mini pack
            PaywallOptionCard(
                title: "Mini Pack",
                subtitle: "10 credits • One-time",
                price: "$2.99",
                isSelected: selectedOption == .miniPack,
                onSelect: { selectedOption = .miniPack }
            )
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
        switch selectedOption {
        case .liteSubscription:
            return "Subscribe for $4.99/month"
        case .miniPack:
            return "Buy for $2.99"
        }
    }
    
    // MARK: - Footer
    
    private var footerLinks: some View {
        HStack(spacing: HiTheme.spacingXL) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            
            Button("Terms") {
                showTerms = true
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.top, HiTheme.spacingMD)
    }
    
    // MARK: - Actions
    
    private func processPurchase() {
        isProcessing = true
        
        // TODO: Implement StoreKit purchase
        // For now, simulate purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            switch selectedOption {
            case .liteSubscription:
                creditsManager.setSubscription(.lite)
                creditsManager.addCredits(SubscriptionTier.lite.monthlyPrompts)
            case .miniPack:
                creditsManager.addCredits(CreditPack.mini.credits)
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

// MARK: - Paywall Option Card

private struct PaywallOptionCard: View {
    let title: String
    let subtitle: String
    let price: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: HiTheme.spacingMD) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.headline)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title2)
            }
            .padding(HiTheme.spacingMD)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusLG)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
}

