import SwiftUI

/// Onboarding step that asks the user to switch to the hi-key keyboard from
/// inside the app. We focus a hidden text field to raise the system keyboard,
/// then observe `UITextInputMode.currentInputModeDidChangeNotification` and
/// match the active input mode's bundle identifier against hi-key's. As soon
/// as we detect the switch, we dismiss the keyboard and reveal Continue.
/// Works regardless of whether the user has granted Full Access.
struct OpenKeyboardView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var detected: Bool = OnboardingManager.shared.keyboardDetectedOnce
    @State private var inputModeObserver: NSObjectProtocol?
    @FocusState private var fieldFocused: Bool

    /// Bundle ID of the keyboard extension, matched against `UITextInputMode`'s
    /// undocumented `identifier` property (read via KVC) to detect when hi-key
    /// becomes the active keyboard. Works without Full Access since detection
    /// happens entirely host-side off the input-mode notification.
    private let hiKeyBundleID = "ai.hi-key.keyboard"
    /// KVC key on `UITextInputMode` exposing the keyboard extension's bundle
    /// ID. Not part of the public API but stable across iOS versions and used
    /// by many shipped apps that need to identify a specific custom keyboard.
    private let inputModeIdentifierKey = "identifier"
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
            // If we've ever detected hi-key as the active mode in a prior
            // session, skip raising the keyboard and stay in the success state.
            if onboardingManager.keyboardDetectedOnce {
                detected = true
                return
            }
            detected = false
            startObservingInputMode()
            // Small delay so the view is fully presented before focus is set;
            // focusing too early during the transition can drop the request.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fieldFocused = true
                // Initial check in case hi-key is already the user's last-used
                // keyboard — the change notification won't fire in that case.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    checkActiveInputMode()
                }
            }
        }
        .onDisappear {
            stopObservingInputMode()
            fieldFocused = false
        }
        .onChange(of: detected) { _, newValue in
            if newValue {
                stopObservingInputMode()
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

    private func startObservingInputMode() {
        stopObservingInputMode()
        inputModeObserver = NotificationCenter.default.addObserver(
            forName: UITextInputMode.currentInputModeDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            checkActiveInputMode()
        }
    }

    private func stopObservingInputMode() {
        if let observer = inputModeObserver {
            NotificationCenter.default.removeObserver(observer)
            inputModeObserver = nil
        }
    }

    private func checkActiveInputMode() {
        guard let mode = UIResponder.hi_currentFirstResponder?.textInputMode else { return }
        if mode.value(forKey: inputModeIdentifierKey) as? String == hiKeyBundleID {
            onboardingManager.keyboardDetectedOnce = true
            detected = true
        }
    }
}

// MARK: - First responder lookup

private extension UIResponder {
    private static weak var _hiFirstResponder: UIResponder?

    /// Walks the responder chain to find the current first responder. Used to
    /// read the active `textInputMode` from the host app — there's no public
    /// API to query it directly without a responder reference.
    static var hi_currentFirstResponder: UIResponder? {
        _hiFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder._hi_captureFirstResponder), to: nil, from: nil, for: nil)
        return _hiFirstResponder
    }

    @objc private func _hi_captureFirstResponder() {
        UIResponder._hiFirstResponder = self
    }
}

#Preview {
    ZStack {
        HiAppBackground()
        OpenKeyboardView()
    }
}
