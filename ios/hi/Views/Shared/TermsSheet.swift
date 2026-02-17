import SwiftUI

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
