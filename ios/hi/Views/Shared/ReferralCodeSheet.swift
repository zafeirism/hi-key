import SwiftUI

struct ReferralCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared

    @State private var name: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var isNameFocused: Bool

    private let hapticGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        VStack(spacing: 0) {
            HiSheetHeader(title: "Invite friends", onClose: { dismiss() })

            Text("Earn 50 credits for each friend who joins using your code.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.bottom, HiTheme.spacingXL)

            // Name input or generated code
            if let code = creditsManager.referralCode {
                codeDisplay(code: code)
            } else {
                nameEntry
            }

            Spacer()
        }
        .padding(.horizontal, HiTheme.spacingMD)
        .onAppear {
            name = creditsManager.userName
            if creditsManager.referralCode == nil && name.isEmpty {
                isNameFocused = true
            }
            // Sheet shown → user will either generate a code or copy one. Warm engine.
            hapticGenerator.prepare()
        }
    }

    // MARK: - Name Entry

    private var nameEntry: some View {
        VStack(alignment: .leading) {

            TextField("Enter your name", text: $name)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(HiTheme.textPrimary)
                .padding(HiTheme.spacingMD)
                .background(HiTheme.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isNameFocused)
                .padding(.bottom, HiTheme.spacingSM)
                .disabled(isGenerating)
                .onChange(of: name) { _, newValue in
                    let filtered = filterLetters(newValue)
                    if filtered != newValue {
                        name = filtered
                    }
                    errorMessage = nil
                }

            Text("Letters only. The first 6 letters become the prefix of your referral code.")
                .font(.footnote)
                .foregroundStyle(HiTheme.textSecondary)
                .padding(.horizontal)
                .padding(.bottom, HiTheme.spacingLG)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(HiTheme.statusError)
                    .padding(.horizontal)
                    .padding(.bottom, HiTheme.spacingSM)
            }

            Button {
                generateCode()
            } label: {
                HStack(spacing: HiTheme.spacingSM) {
                    if isGenerating {
                        ProgressView()
                            .tint(HiTheme.backgroundRoot)
                            .scaleEffect(0.8)
                    }
                    Text(isGenerating ? "Generating…" : "Generate Code")
                }
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .disabled(trimmedName.isEmpty || isGenerating)
        }
    }

    // MARK: - Code Display

    private func codeDisplay(code: String) -> some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
            HStack {
                Text(code)
                    .font(.title2.monospaced().bold())
                    .foregroundStyle(HiTheme.textPrimary)

                Spacer()

                Button {
                    copyCode(code)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundStyle(HiTheme.accentPrimary)
                }

                ShareLink(item: shareText(code: code)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(HiTheme.accentPrimary)
                }
            }
            .padding(HiTheme.spacingMD)
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))

            Text("Copy this code and share it with friends.")
                .font(.footnote)
                .foregroundStyle(HiTheme.textSecondary)
                .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func filterLetters(_ input: String) -> String {
        String(input.filter { $0.isLetter || $0.isWhitespace })
    }

    private func generateCode() {
        let cleaned = trimmedName
        guard !cleaned.isEmpty else { return }

        creditsManager.setUserName(cleaned)

        isGenerating = true
        errorMessage = nil

        // Prepare while the network round-trip is in flight — by the time
        // it completes, the Taptic Engine is fully warm.
        hapticGenerator.prepare()

        Task {
            do {
                _ = try await creditsManager.createReferralCode(name: cleaned)
                hapticGenerator.notificationOccurred(.success)
                withAnimation(HiTheme.animationNormal) {
                    isGenerating = false
                }
            } catch {
                hapticGenerator.notificationOccurred(.error)
                isGenerating = false
                errorMessage = error.localizedDescription
                HiLogger.error("Failed to create referral code", error: error)
            }
        }
    }

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        hapticGenerator.notificationOccurred(.success)
    }

    private func shareText(code: String) -> String {
        "Try hi-key! Generate AI images right from your keyboard. Use my code \(code) and we both get 50 free credits! Download: https://apps.apple.com/app/hi-key"
    }
}

#Preview {
    ReferralCodeSheet()
        .background(HiTheme.backgroundRoot)
        .onAppear {
            CreditsManager.shared.resetCredits()
        }
}
