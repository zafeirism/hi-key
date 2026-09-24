import SwiftUI

/// Shown from the paywall and other purchase surfaces. Surfaces both the Terms
/// of Service and the Privacy Policy as required by Apple's auto-renewing
/// subscription guidelines, plus a brief plain-language summary of how billing
/// and credits work.
struct TermsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private static let termsURL = URL(string: "https://hi-key.ai/terms")!
    private static let privacyURL = URL(string: "https://hi-key.ai/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HiTheme.spacingLG) {
                    summarySection
                    linksSection
                }
                .padding(HiTheme.spacingLG)
            }
            .background(HiTheme.backgroundRoot)
            .navigationTitle("Terms & Privacy")
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

    // MARK: - Subviews

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
            Text("How billing works")
                .font(.headline.weight(.semibold))
                .foregroundStyle(HiTheme.textPrimary)

            Text("Subscriptions auto-renew at the price and period shown on the purchase screen, unless you cancel at least 24 hours before the cycle ends. Renewal is charged within 24 hours of the cycle ending. You can manage or cancel any time in your Apple ID Subscription settings.")
                .font(.body)
                .foregroundStyle(HiTheme.textSecondary)

            Text("Credit packs are one-time purchases with no recurring charge. Any unused free trial is forfeited when a paid subscription begins. All purchases are handled by Apple; refunds go through Apple at reportaproblem.apple.com.")
                .font(.body)
                .foregroundStyle(HiTheme.textSecondary)
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
            Text("Read the full documents")
                .font(.headline.weight(.semibold))
                .foregroundStyle(HiTheme.textPrimary)
                .padding(.top, HiTheme.spacingSM)

            HiCard {
                VStack(spacing: 0) {
                    legalLinkRow(
                        title: "Terms of Service",
                        systemImage: "doc.text",
                        url: Self.termsURL
                    )

                    Rectangle()
                        .fill(HiTheme.divider)
                        .frame(height: 1)

                    legalLinkRow(
                        title: "Privacy Policy",
                        systemImage: "lock.shield",
                        url: Self.privacyURL
                    )
                }
            }
        }
    }

    private func legalLinkRow(title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: HiTheme.spacingMD) {
                Image(systemName: systemImage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.accentPrimary)
                    .frame(width: 22)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(HiTheme.textSecondary)
            }
            .padding(.vertical, HiTheme.spacingMD)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    TermsSheet()
}
