import SwiftUI

struct ReferralCreditsView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @State private var referralCode: String = ""
    @State private var codeApplied: Bool = false
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Got a friend code? Enter it and you'll both get 5 free credits.")
                .font(.title.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            
            // Middle space - input field and Apply button
            referralInputSection
                .padding(.vertical, HiTheme.spacingLG)
            
            Spacer()
            
            Group {
                if codeApplied {
                    Button {
                        // Grant credits and continue
                        creditsManager.grantInitialCredits(withReferral: true)
                        onboardingManager.goToNextStep()
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(HiPrimaryButtonStyle())
                } else {
                    Button {
                        // Skip referral
                        creditsManager.grantInitialCredits(withReferral: false)
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
        VStack(spacing: HiTheme.spacingMD) {
            if codeApplied {
                // Success state
                HStack(spacing: HiTheme.spacingSM) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Code applied! +5 credits")
                        .foregroundStyle(.green)
                }
                .font(.body.weight(.medium))
                .padding(.vertical, HiTheme.spacingMD)
            } else {
                // Entry state
                HStack(spacing: HiTheme.spacingSM) {
                    TextField("FRIEND-CODE", text: $referralCode)
                        .textFieldStyle(.plain)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.horizontal, HiTheme.spacingMD)
                        .padding(.vertical, HiTheme.spacingSM)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                        .onChange(of: referralCode) { _, newValue in
                            referralCode = formatReferralCode(newValue)
                            showError = false
                        }
                    
                    Button {
                        applyCode()
                    } label: {
                        Text("Apply")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, HiTheme.spacingMD)
                            .padding(.vertical, HiTheme.spacingSM)
                            .background(isValidFormat ? Color.accentColor : Color.accentColor.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
                    }
                    .disabled(!isValidFormat)
                }
                
                if showError {
                    Text("Invalid code format. Try again.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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
        if onboardingManager.applyReferralCode(referralCode) {
            withAnimation(.spring(response: 0.4)) {
                codeApplied = true
            }
        } else {
            showError = true
        }
    }
}

#Preview {
    ZStack {
        HiTheme.onboardingGradient
            .ignoresSafeArea()
        
        ReferralCreditsView()
    }
}
