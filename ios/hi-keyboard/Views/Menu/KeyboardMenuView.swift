import SwiftUI

// MARK: - Keyboard Menu View
// Replaces the keyboard area / results carousel when `mode == .menu`. Renders
// as a flat, action-sheet-style list — system list look, no row backgrounds,
// hairline dividers between rows. Stays visually neutral on purpose, since
// the keyboard lives inside third-party apps and must not adopt hi-key
// brand colors.

struct KeyboardMenuView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel

    @State private var showCopiedFeedback = false

    private var summary: KeyboardAccountSummary { viewModel.accountSummary }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                creditsRow
                Divider()
                referralRow
                Divider()
                openAppRow
            }
        }
        .frame(height: 274) // Same as keyboard height (in iOS 26)
    }

    // MARK: - Rows

    private var creditsRow: some View {
        MenuRow(
            icon: "creditcard",
            title: "\(summary.totalCredits) credits",
            description: summary.creditsRowDescription,
            trailingLabel: "Buy credits",
            action: { openURL("hi-key://buy-credits") }
        )
    }

    @ViewBuilder
    private var referralRow: some View {
        if let code = summary.referralCode {
            MenuRow(
                icon: "person.2",
                title: "Invite friends",
                description: "Tap to copy your code",
                showsChevron: false,
                trailing: {
                    HStack(spacing: 8) {
                        Text(code)
                            .font(.subheadline.monospaced().weight(.medium))
                            .foregroundColor(.secondary)
                        Image(systemName: showCopiedFeedback ? "checkmark" : "square.on.square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                },
                action: { copyReferral(code) }
            )
        } else {
            MenuRow(
                icon: "person.2",
                title: "Set up referral code",
                description: "Get 50 credits per friend who joins",
                trailingLabel: nil,
                action: { openURL("hi-key://referral") }
            )
        }
    }

    private var openAppRow: some View {
        MenuRow(
            icon: "arrow.up.forward.app",
            title: "Open hi-key",
            description: nil,
            trailingLabel: nil,
            action: { openURL("hi-key://") }
        )
    }

    // MARK: - Helpers

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

// MARK: - Menu Row

private struct MenuRow<Trailing: View>: View {
    let icon: String
    let title: String
    let description: String?
    let showsChevron: Bool
    @ViewBuilder let trailing: () -> Trailing
    let action: () -> Void

    init(
        icon: String,
        title: String,
        description: String?,
        showsChevron: Bool = true,
        @ViewBuilder trailing: @escaping () -> Trailing,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.showsChevron = showsChevron
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let description {
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                trailing()

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Convenience initializer for rows whose only trailing element is a text label
// (or nothing). Keeps the call sites tidy.
extension MenuRow where Trailing == AnyView {
    init(
        icon: String,
        title: String,
        description: String?,
        trailingLabel: String?,
        showsChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            icon: icon,
            title: title,
            description: description,
            showsChevron: showsChevron,
            trailing: {
                AnyView(
                    Group {
                        if let trailingLabel {
                            Text(trailingLabel)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }
                )
            },
            action: action
        )
    }
}
