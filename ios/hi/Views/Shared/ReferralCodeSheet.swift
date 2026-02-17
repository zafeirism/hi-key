import SwiftUI

struct ReferralCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @State private var name: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Invite friends")
                    .font(.title2.weight(.semibold))

                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HiTheme.iconDefault)
                            .frame(width: 32, height: 32)
                            .background(HiTheme.surfaceSecondary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(HiTheme.divider, lineWidth: 1))
                    }
                }
            }
            .padding(.top, HiTheme.spacingMD)
            .padding(.bottom, HiTheme.spacingXL)

            Text("Earn 5 credits for each friend who joins using your code.")
                .font(.body.weight(.medium))
                .foregroundStyle(HiTheme.textSecondary)
                .multilineTextAlignment(.leading)
                //.padding(.horizontal)
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
                .padding(.bottom, HiTheme.spacingSM)

            Text("Part of your name will appear in your referral code and be shown to friends who use it. Enter at least 3 chars.")
                .font(.footnote)
                .foregroundStyle(HiTheme.textSecondary)
                .padding(.horizontal)
                .padding(.bottom, HiTheme.spacingLG)
                
            Button {
                generateCode()
            } label: {
                Text("Generate Code")
            }
            .buttonStyle(HiPrimaryButtonStyle(isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty))
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
                //.multilineTextAlignment(.center)
        }
        //.padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func generateCode() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        creditsManager.setUserName(trimmedName)

        withAnimation(HiTheme.animationNormal) {
            _ = creditsManager.generateReferralCode()
        }
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func shareText(code: String) -> String {
        "Try hi-key! Generate AI images right from your keyboard. Use my code \(code) and we both get 5 free credits! Download: https://apps.apple.com/app/hi-key"
    }
}

#Preview {
    ReferralCodeSheet()
        .background(HiTheme.backgroundRoot)
        .onAppear {
            CreditsManager.shared.resetCredits()
        }
}
