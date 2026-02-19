import SwiftUI

/// Reusable top bar for onboarding screens.
/// Supports optional back button (left) and optional text action (right).
struct OnboardingTopBar: View {
    var onBack: (() -> Void)?
    var rightLabel: String?
    var onRight: (() -> Void)?

    var body: some View {
        HStack {
            // Left: Back button (if provided)
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(HiTheme.iconDefault)
                        .frame(width: 40, height: 40)
                        .background(HiTheme.surfacePrimary)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
                }
            } else {
                // Invisible spacer to maintain layout
                Color.clear
                    .frame(width: 40, height: 40)
            }

            Spacer()

            // Right: Text action (if provided)
            if let rightLabel, let onRight {
                Button(action: onRight) {
                    Text(rightLabel)
                }
                .buttonStyle(HiTertiaryButtonStyle())
            } else {
                // Invisible spacer to maintain layout
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
            OnboardingTopBar(onBack: { print("Back") })
                .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}

#Preview("Skip only") {
    ZStack {
        HiAppBackground()

        VStack {
            OnboardingTopBar(rightLabel: "Skip", onRight: { print("Skip") })
                .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}

#Preview("Both") {
    ZStack {
        HiAppBackground()

        VStack {
            OnboardingTopBar(
                onBack: { print("Back") },
                rightLabel: "Skip",
                onRight: { print("Skip") }
            )
            .padding(.horizontal, HiTheme.spacingLG)
            Spacer()
        }
    }
}
