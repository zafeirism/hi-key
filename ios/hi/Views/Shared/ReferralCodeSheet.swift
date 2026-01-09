import SwiftUI

struct ReferralCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @State private var name: String = ""
    @State private var generatedCode: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: HiTheme.spacingLG) {
                Spacer()
                
                // Icon
                Image(systemName: "gift.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                
                // Title
                Text("Create your referral code")
                    .font(.title2.bold())
                
                Text("Earn 5 credits for each friend who joins using your code")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Name input or generated code
                if let code = generatedCode ?? creditsManager.referralCode {
                    // Show generated code
                    codeDisplay(code: code)
                } else {
                    // Name entry
                    nameEntry
                }
                
                Spacer()
                Spacer()
            }
            .padding(HiTheme.spacingMD)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            name = creditsManager.userName
        }
    }
    
    // MARK: - Name Entry
    
    private var nameEntry: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Text("Enter your name")
                .font(.headline)
            
            TextField("Your name", text: $name)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(HiTheme.spacingMD)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                .textInputAutocapitalization(.words)
            
            Text("Your name will appear in your referral code and be shown to friends who use it")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                generateCode()
            } label: {
                Text("Generate Code")
            }
            .buttonStyle(HiPrimaryButtonStyle(isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty))
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Code Display
    
    private func codeDisplay(code: String) -> some View {
        VStack(spacing: HiTheme.spacingMD) {
            Text("Your referral code")
                .font(.headline)
            
            HStack {
                Text(code)
                    .font(.title2.monospaced().bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    copyCode(code)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                
                ShareLink(item: shareText(code: code)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(HiTheme.spacingMD)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            
            Text("Share this code with friends. You both get 5 credits!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func generateCode() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        creditsManager.setUserName(trimmedName)
        
        if let code = creditsManager.generateReferralCode() {
            withAnimation {
                generatedCode = code
            }
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
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
}
