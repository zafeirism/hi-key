import SwiftUI

struct PaywallView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var isProcessing = false
    @State private var showTerms = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: HiTheme.spacingLG) {
                // Header
                headerSection
                
                // Plan cards
                planCardsSection
                
                Spacer()
                
                // Subscribe button
                subscribeButton
                
                // Footer links
                footerLinks
            }
            .padding(.horizontal, HiTheme.spacingLG)
            .padding(.top, HiTheme.spacingXL)
            .padding(.bottom, HiTheme.spacingMD)
        }
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(HiTheme.mint)
            
            Text("Unlock hi-key")
                .font(HiTheme.title(32))
                .foregroundColor(.primary)
            
            Text("Start creating amazing images\nin all your conversations")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Plan Cards
    
    private var planCardsSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            PlanCard(
                plan: .starter,
                isSelected: selectedPlan == .starter,
                onSelect: { selectedPlan = .starter }
            )
            
            PlanCard(
                plan: .pro,
                isSelected: selectedPlan == .pro,
                onSelect: { selectedPlan = .pro }
            )
        }
    }
    
    // MARK: - Subscribe Button
    
    private var subscribeButton: some View {
        Button {
            subscribe()
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Subscribe for \(selectedPlan.priceString)/month")
                }
            }
            .hiButtonStyle(isEnabled: !isProcessing)
        }
        .disabled(isProcessing)
    }
    
    // MARK: - Footer Links
    
    private var footerLinks: some View {
        HStack(spacing: HiTheme.spacingXL) {
            Button("Restore Purchase") {
                restorePurchase()
            }
            .font(HiTheme.caption())
            .foregroundColor(.secondary)
            
            Button("Terms & Privacy") {
                showTerms = true
            }
            .font(HiTheme.caption())
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func subscribe() {
        isProcessing = true
        
        // TODO: Implement RevenueCat purchase flow
        // For now, simulate a successful purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            onboardingManager.hasSubscribed = true
            onboardingManager.completeOnboarding()
        }
    }
    
    private func restorePurchase() {
        isProcessing = true
        
        // TODO: Implement RevenueCat restore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            // Show message if nothing to restore
        }
    }
}

// MARK: - Subscription Plan

enum SubscriptionPlan {
    case starter
    case pro
    
    var title: String {
        switch self {
        case .starter: return "Starter"
        case .pro: return "Pro"
        }
    }
    
    var priceString: String {
        switch self {
        case .starter: return "$2.99"
        case .pro: return "$6.99"
        }
    }
    
    var generations: String {
        switch self {
        case .starter: return "30 generations"
        case .pro: return "90 generations"
        }
    }
    
    var features: [String] {
        switch self {
        case .starter:
            return [
                "30 generations per month",
                "4 images per generation",
                "Standard quality",
            ]
        case .pro:
            return [
                "90 generations per month",
                "4 images per generation",
                "No watermark",
                "Priority support",
            ]
        }
    }
    
    var badge: String? {
        switch self {
        case .starter: return nil
        case .pro: return "BEST VALUE"
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(HiTheme.subtitle(20))
                            .foregroundColor(.primary)
                        
                        Text(plan.generations)
                            .font(HiTheme.caption())
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(HiTheme.mint)
                            .cornerRadius(HiTheme.radiusSM)
                    }
                    
                    Text(plan.priceString)
                        .font(HiTheme.title(24))
                        .foregroundColor(.primary)
                    
                    Text("/mo")
                        .font(HiTheme.caption())
                        .foregroundColor(.secondary)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(HiTheme.mint)
                            
                            Text(feature)
                                .font(HiTheme.caption())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(HiTheme.spacingLG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? HiTheme.mint.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(HiTheme.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusLG)
                    .stroke(isSelected ? HiTheme.mint : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Terms View

private struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: HiTheme.spacingLG) {
                    Text("Terms of Service")
                        .font(HiTheme.title(24))
                    
                    Text("""
                    By subscribing to hi-key, you agree to the following terms:
                    
                    • Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.
                    • Your account will be charged for renewal within 24 hours prior to the end of the current period.
                    • You can manage and cancel subscriptions by going to your Account Settings on the App Store after purchase.
                    • Any unused portion of a free trial period will be forfeited when you purchase a subscription.
                    
                    Privacy Policy:
                    • We collect only the data necessary to provide our service.
                    • Your prompts are processed to generate images and are not stored.
                    • We do not sell your personal data to third parties.
                    """)
                    .font(HiTheme.body())
                    .foregroundColor(.secondary)
                }
                .padding(HiTheme.spacingLG)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PaywallView()
}

