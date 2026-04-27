import SwiftUI

// MARK: - Keyboard Menu View
// Replaces the keyboard area / results carousel when `mode == .menu`. Shows
// credits, referral code, and an "open app" row, plus deep-link CTAs that
// hand off to the host app via `extensionContext.open(_:)`.
//
// Styling stays visually neutral on purpose — the keyboard lives inside
// third-party apps and must not adopt hi-key brand colors.

struct KeyboardMenuView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel

    @State private var summary: KeyboardAccountSummary = .load()
    @State private var showCopiedFeedback = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                creditsRow
                referralRow
                openAppRow
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(height: 264)
        .onAppear {
            summary = .load()
        }
    }

    // MARK: - Credits Row

    private var creditsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(summary.totalCredits)")
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundColor(.primary)

                    Text("credits")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    if summary.doubleCredits {
                        pill(text: "2×")
                    }
                    pill(text: summary.planLabel)
                }
            }

            if let caption = summary.weeklyCreditsCaption {
                Text(caption)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
            }

            if let extra = summary.extraCreditsCaption {
                Text(extra)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
            }

            Button {
                openURL("hi-key://buy-credits")
            } label: {
                Text("Buy credits")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(rowBackground)
    }

    // MARK: - Referral Row

    private var referralRow: some View {
        Button {
            if let code = summary.referralCode {
                copyReferral(code)
            } else {
                openURL("hi-key://referral")
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.referralCode == nil ? "Set up referral code" : "Invite friends")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Text(summary.referralCode == nil
                         ? "Get 50 credits per friend who joins"
                         : "Tap to copy your code")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let code = summary.referralCode {
                    Text(code)
                        .font(.subheadline.monospaced().bold())
                        .foregroundColor(.primary)

                    Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .contentTransition(.symbolEffect(.replace))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Open App Row

    private var openAppRow: some View {
        Button {
            openURL("hi-key://")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 28)

                Text("Open hi-key")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground).opacity(0.6))
    }

    private func pill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
            )
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        viewModel.openURL(url)
    }

    private func copyReferral(_ code: String) {
        UIPasteboard.general.string = code
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }
}
