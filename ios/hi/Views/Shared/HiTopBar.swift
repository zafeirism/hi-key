import SwiftUI

/// Reusable top bar for full-screen views.
/// Supports optional back button (left), close button (right), or text action (right).
struct HiTopBar: View {
    var onBack: (() -> Void)?
    var onClose: (() -> Void)?
    var rightLabel: String?
    var onRight: (() -> Void)?

    var body: some View {
        HStack {
            // Left: Back button (if provided)
            if let onBack {
                HiIconButton("chevron.left", size: .topBar) {
                    onBack()
                }
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }

            Spacer()

            // Right: Close icon, text action, or spacer
            if let onClose {
                HiIconButton("xmark", size: .topBar) {
                    onClose()
                }
            } else if let rightLabel, let onRight {
                Button(action: onRight) {
                    Text(rightLabel)
                }
                .buttonStyle(HiTertiaryButtonStyle())
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
    }
}

#Preview("Back only") {
    ZStack {
        HiAppBackground()
        VStack {
            HiTopBar(onBack: { print("Back") })
                .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}

#Preview("Close only") {
    ZStack {
        HiAppBackground()
        VStack {
            HiTopBar(onClose: { print("Close") })
                .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}

#Preview("Skip only") {
    ZStack {
        HiAppBackground()
        VStack {
            HiTopBar(rightLabel: "Skip", onRight: { print("Skip") })
                .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}

#Preview("Back + Skip") {
    ZStack {
        HiAppBackground()
        VStack {
            HiTopBar(
                onBack: { print("Back") },
                rightLabel: "Skip",
                onRight: { print("Skip") }
            )
            .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}
