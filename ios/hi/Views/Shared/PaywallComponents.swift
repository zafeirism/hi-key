import SwiftUI

// MARK: - Paywall Hint View

struct PaywallHintView: View {
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

// MARK: - Paywall CTA Button

struct PaywallCTAButton: View {
    let text: String
    let isProcessing: Bool
    var isSecondary: Bool = false
    let action: () -> Void

    private var buttonLabel: some View {
        Group {
            if isProcessing {
                ProgressView()
                    .tint(isSecondary ? HiTheme.accentPrimary : HiTheme.backgroundRoot)
            } else {
                Text(text)
            }
        }
    }

    var body: some View {
        if isSecondary {
            Button(action: action) { buttonLabel }
                .buttonStyle(HiSecondaryButtonStyle(isEnabled: !isProcessing))
                .disabled(isProcessing)
        } else {
            Button(action: action) { buttonLabel }
                .buttonStyle(HiPrimaryButtonStyle(isEnabled: !isProcessing))
                .disabled(isProcessing)
        }
    }
}

// MARK: - Paywall Footer Links

struct PaywallFooterLinks: View {
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

struct PaywallOptionCard: View {
    let title: String
    let subtitle: String
    let price: String
    let isSelected: Bool
    let onSelect: () -> Void

    var discountBadge: String? = nil
    var originalPrice: String? = nil
    var label: String? = nil
    var isCurrentPlan: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                    HStack(spacing: HiTheme.spacingSM) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(HiTheme.textPrimary)

                        if isCurrentPlan {
                            Text("CURRENT")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HiTheme.textSecondary)
                                .padding(.horizontal, HiTheme.spacingSM)
                                .padding(.vertical, HiTheme.spacingXS)
                                .background(HiTheme.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                        } else if let discountBadge {
                            Text(discountBadge)
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
                        } else if let label {
                            Text(label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HiTheme.statusGreen)
                                .padding(.horizontal, HiTheme.spacingSM)
                                .padding(.vertical, HiTheme.spacingXS)
                                .background(HiTheme.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusSM))
                                .overlay(
                                    RoundedRectangle(cornerRadius: HiTheme.radiusSM)
                                        .stroke(HiTheme.statusGreen, lineWidth: 1)
                                )
                        }
                    }
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HiTheme.textSecondary)
                }

                Spacer()

                if let originalPrice {
                    Text(originalPrice)
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
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusXL)
                    .stroke(isSelected ? HiTheme.accentPrimary : HiTheme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCurrentPlan)
        //.opacity(isCurrentPlan ? 0.5 : 1)
    }
}

#Preview("All Plans") {
    AllPlansSheet(onComplete: nil)
}
