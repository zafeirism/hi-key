import SwiftUI
import StoreKit

struct ReferralCreditsView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @ObservedObject var creditsManager = CreditsManager.shared
    
    @State private var referralCode: String = ""
    @State private var codeApplied: Bool = false
    @State private var showError: Bool = false
    @State private var hasRequestedReview: Bool = false
    
    private var currentCredits: Int {
        codeApplied ? 10 : 5
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Credits display section
            creditsSection
            
            Spacer()
            
            // Referral entry section
            referralSection
            
            Spacer()
            Spacer()
            
            // Continue button
            Button {
                // Grant credits based on referral status
                creditsManager.grantInitialCredits(withReferral: codeApplied)
                onboardingManager.goToNextStep()
            } label: {
                Text("Continue")
            }
            .buttonStyle(HiPrimaryButtonStyle())
            .padding(.horizontal, HiTheme.spacingMD)
            .padding(.bottom, HiTheme.spacingXL)
        }
        .onAppear {
            requestReview()
        }
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            // Large credits number with animation
            Text("\(currentCredits)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: currentCredits)
            
            Text("free credits")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Each credit = 1 prompt = 4 images")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Referral Section
    
    private var referralSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            // Section header
            VStack(spacing: HiTheme.spacingSM) {
                Text("Got a friend code?")
                    .font(.headline)
                
                Text("Enter it and you both get 5 bonus credits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Code entry field
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
                            // Auto-format: uppercase and add dash after 6 chars
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
        .padding(.horizontal, HiTheme.spacingLG)
        .padding(.vertical, HiTheme.spacingLG)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
        .padding(.horizontal, HiTheme.spacingMD)
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
    
    private func requestReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        
        // Request review after short delay (user just received free credits)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}

#Preview {
    ReferralCreditsView()
}
