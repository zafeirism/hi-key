import SwiftUI

struct ClaimCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared

    @State private var code: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess: Bool = false
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HiSheetHeader(title: "Waitlist code", onClose: { dismiss() })

            if showSuccess {
                successView
            } else {
                inputView
            }

            Spacer()
        }
        .padding(.horizontal, HiTheme.spacingMD)
        .onAppear {
            isCodeFocused = true
        }
    }

    // MARK: - Input

    private var inputView: some View {
        VStack(alignment: .leading) {
            Text("Waitlist members get 2x credits on every purchase, forever. Enter your code from the launch email to unlock it.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.bottom, HiTheme.spacingXL)

            TextField("HI-XXXXXXXX", text: $code)
                .textFieldStyle(.plain)
                .font(.title3.monospaced())
                .foregroundStyle(HiTheme.textPrimary)
                .padding(HiTheme.spacingMD)
                .background(HiTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isCodeFocused)
                .padding(.bottom, HiTheme.spacingLG)
                .disabled(isSubmitting)
                .onChange(of: code) { _, newValue in
                    let normalized = normalize(newValue)
                    if normalized != newValue {
                        code = normalized
                    }
                    errorMessage = nil
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(HiTheme.statusError)
                    .padding(.horizontal)
                    .padding(.bottom, HiTheme.spacingSM)
            }

            Button {
                submit()
            } label: {
                HStack(spacing: HiTheme.spacingSM) {
                    if isSubmitting {
                        ProgressView()
                            .tint(HiTheme.backgroundRoot)
                            .scaleEffect(0.8)
                    }
                    Text(isSubmitting ? "Applying…" : "Apply code")
                }
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .disabled(trimmedCode.isEmpty || isSubmitting)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: HiTheme.spacingLG) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(HiTheme.accentPrimary)

            Text("You're in.")
                .font(.title2.weight(.bold))
                .foregroundStyle(HiTheme.textPrimary)

            Text("2x credits on all future purchases, forever.")
                .font(.body)
                .foregroundStyle(HiTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, HiTheme.spacingXL)
        .transition(.opacity)
    }

    // MARK: - Logic

    private var trimmedCode: String {
        code.trimmingCharacters(in: .whitespaces)
    }

    /// Uppercase, strip whitespace. Backend validates the full format.
    private func normalize(_ input: String) -> String {
        input
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private func submit() {
        let value = trimmedCode
        guard !value.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil
        isCodeFocused = false

        Task {
            do {
                try await creditsManager.claimWaitlistCode(value)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation(HiTheme.animationNormal) {
                    showSuccess = true
                }
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                dismiss()
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                isSubmitting = false
                errorMessage = error.localizedDescription
                HiLogger.error("Failed to claim waitlist code", error: error)
            }
        }
    }
}

#Preview {
    ClaimCodeSheet()
        .background(HiTheme.backgroundRoot)
}
