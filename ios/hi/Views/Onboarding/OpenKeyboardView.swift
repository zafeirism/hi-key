import SwiftUI

/// Onboarding step that asks the user to switch to the hi-key keyboard from
/// inside the app. We focus a hidden text field to raise the system keyboard,
/// then poll the App Group UserDefaults for a timestamp that the keyboard
/// extension stamps each time it becomes visible. As soon as we see a newer
/// timestamp than the one we captured on appear, we know the user successfully
/// switched to hi-key — we dismiss the keyboard and reveal Continue.
struct OpenKeyboardView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var detected = false
    @State private var baselineTimestamp: TimeInterval = 0
    @State private var pollingTask: Task<Void, Never>?
    @FocusState private var fieldFocused: Bool

    private let appGroupID = "group.ai.hi-key"
    private let lastSeenKey = "hiKeyboardLastSeenAt"
    private let pollInterval: TimeInterval = 0.3
    /// Hold the keyboard up briefly after detection so the success text can
    /// settle before the keyboard slides away — feels less frantic than
    /// animating text, button, and dismissal all at once.
    private let dismissDelay: TimeInterval = 2

    var body: some View {
        ZStack {
            // Hidden focused TextField — its sole purpose is to raise the system
            // keyboard so the user can long-press the globe to switch to hi-key.
            TextField("", text: .constant(""))
                .focused($fieldFocused)
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                HiTopBar(onBack: {
                    onboardingManager.goToPreviousStep()
                })
                .padding(.top, HiTheme.spacingMD)

                Text(detected ? "You're all set." : "Open hi-key.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)

                Text(detected
                     ? "You can now use hi-key in any app."
                     : "Tap and hold the globe at the bottom-left of the keyboard, then choose hi-key.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)

                statusRow
                    .padding(.top, HiTheme.spacingLG)

                Spacer()

                if detected {
                    Button {
                        onboardingManager.goToNextStep()
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(HiPrimaryButtonStyle())
                    .padding(.bottom, HiTheme.spacingXL)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            captureBaselineAndStartPolling()
            // Small delay so the view is fully presented before focus is set;
            // focusing too early during the transition can drop the request.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fieldFocused = true
            }
        }
        .onDisappear {
            pollingTask?.cancel()
            pollingTask = nil
            fieldFocused = false
        }
        .onChange(of: detected) { _, newValue in
            if newValue {
                pollingTask?.cancel()
                pollingTask = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                    fieldFocused = false
                }
            }
        }
        .animation(HiTheme.animationNormal, value: detected)
    }

    // MARK: - Status row

    private var statusRow: some View {
        HStack(spacing: HiTheme.spacingSM) {
            if detected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HiTheme.accentPrimary)
                Text("Your hi-key is ready")
                    .foregroundStyle(HiTheme.textPrimary)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .tint(HiTheme.textSecondary)
                Text("Hold 🌐 to choose hi-key")
                    .foregroundStyle(HiTheme.textSecondary)
            }
        }
        .font(.subheadline.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Detection

    private func captureBaselineAndStartPolling() {
        let defaults = UserDefaults(suiteName: appGroupID)
        baselineTimestamp = defaults?.double(forKey: lastSeenKey) ?? 0
        detected = false

        pollingTask?.cancel()
        pollingTask = Task { @MainActor in
            let nanos = UInt64(pollInterval * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanos)
                if Task.isCancelled { return }
                let current = defaults?.double(forKey: lastSeenKey) ?? 0
                if current > baselineTimestamp {
                    detected = true
                    return
                }
            }
        }
    }
}

#Preview {
    ZStack {
        HiAppBackground()
        OpenKeyboardView()
    }
}
