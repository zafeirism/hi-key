import SwiftUI

struct ReferralCreditsView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared

    @State private var referralCode: String = OnboardingManager.shared.referrerCode ?? ""
    @State private var codeApplied: Bool = OnboardingManager.shared.referralApplied
    @State private var errorMessage: String? = nil
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HiTopBar(onBack: {
                onboardingManager.goToPreviousStep()
            })
            .padding(.top, HiTheme.spacingMD)

            Text("Got a friend code?")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(HiTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingMD)

            Text("Enter it now and you'll both get 50 free credits.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, HiTheme.spacingMD)

            referralInputSection
                .padding(.top, HiTheme.spacingXXL)

            Spacer()

            Group {
                if codeApplied {
                    Button {
                        onboardingManager.goToNextStep()
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(HiPrimaryButtonStyle())
                } else {
                    Button {
                        onboardingManager.goToNextStep()
                    } label: {
                        Text("I don't have a code")
                    }
                    .buttonStyle(HiSecondaryButtonStyle())
                }
            }
            .padding(.bottom, HiTheme.spacingXXL)
        }
        .padding(.horizontal, HiTheme.spacingLG)
    }

    // MARK: - Referral Input Section

    private var referralInputSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
            HStack(spacing: 0) {
                TextField("FRIEND-CODE", text: $referralCode)
                    .textFieldStyle(.plain)
                    .font(.title3.monospaced())
                    .foregroundStyle(HiTheme.textPrimary)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .disabled(codeApplied)
                    .padding(.vertical, HiTheme.spacingSM)

                if codeApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(HiTheme.accentPrimary)
                        .padding(.trailing, HiTheme.spacingMD)
                        .transition(.scale.combined(with: .opacity))
                } else if isProcessing {
                    ProgressView()
                        .padding(.trailing, HiTheme.spacingMD)
                        .tint(HiTheme.textSecondary)
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button {
                        applyCode()
                    } label: {
                        Text("Apply")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isValidFormat ? HiTheme.backgroundRoot : HiTheme.textTertiary)
                            .padding(.horizontal, HiTheme.spacingMD)
                            .padding(.vertical, HiTheme.spacingSM)
                            .background(isValidFormat ? HiTheme.accentPrimary : HiTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                    }
                    .padding(.trailing, HiTheme.spacingSM)
                    .padding(.vertical, HiTheme.spacingSM)
                    .disabled(!isValidFormat)
                }
            }
            .padding(.leading, HiTheme.spacingMD)
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusMD)
                    .stroke(errorMessage != nil ? HiTheme.statusError : HiTheme.divider, lineWidth: 1)
            )
            .onChange(of: referralCode) { _, newValue in
                referralCode = formatReferralCode(newValue)
                errorMessage = nil
            }

            Text("Shared by a friend who already uses hi-key.")
                .font(.footnote)
                .foregroundStyle(HiTheme.textSecondary)
                .padding(.leading, HiTheme.spacingMD)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(HiTheme.statusError)
                    .padding(.leading, HiTheme.spacingXS)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    private var isValidFormat: Bool {
        onboardingManager.isValidReferralCodeFormat(referralCode)
    }

    private func formatReferralCode(_ input: String) -> String {
        // Remove non-alphanumeric except dash
        var filtered = input.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }

        // Auto-insert dash after 6 chars if not present
        if filtered.count > 6 && !filtered.contains("-") {
            filtered.insert("-", at: filtered.index(filtered.startIndex, offsetBy: 6))
        }

        // Limit length (6 + 1 dash + 6 = 13)
        return String(filtered.prefix(13))
    }

    private func applyCode() {
        guard isValidFormat else { return }

        isProcessing = true
        errorMessage = nil

        Task {
            let generator = UINotificationFeedbackGenerator()
            do {
                try await onboardingManager.applyReferralCode(referralCode)
                generator.notificationOccurred(.success)
                withAnimation(.spring(response: 0.4)) {
                    isProcessing = false
                    codeApplied = true
                }
            } catch {
                generator.notificationOccurred(.error)
                isProcessing = false
                errorMessage = error.localizedDescription
                HiLogger.error("Failed to redeem referral code", error: error)
            }
        }
    }
}

#Preview {
    ZStack {
        HiAppBackground()

        ReferralCreditsView()
    }
}
