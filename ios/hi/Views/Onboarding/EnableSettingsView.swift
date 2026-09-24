import SwiftUI

struct EnableSettingsView: View {
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyModal = false
    @State private var keyboardEnabled: Bool = false

    var body: some View {
        ZStack {
            LottieView(name: "enable-settings", loop: true)
                .ignoresSafeArea()
                .offset(y: -80)
            
            VStack(spacing: 0) {
                HiTopBar(onBack: {
                    onboardingManager.goToPreviousStep()
                })
                .padding(.top, HiTheme.spacingMD)
                
                Text("Enable hi-key in Settings.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)
                
                Text("Allow Full Access so hi-key can generate images from your prompts.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HiTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, HiTheme.spacingMD)
                
                Spacer()
                
                VStack {
                    HiCard{
                        VStack(spacing: HiTheme.spacingMD){
                            Button {
                                showPrivacyModal = true
                            } label: {
                                HStack(spacing: 0){
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(HiTheme.accentPrimary)
                                        .padding(.trailing, HiTheme.spacingSM)
                                    Text("Learn how we protect your privacy")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(HiTheme.accentPrimary)
                                        .padding(.trailing, HiTheme.spacingXS)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(HiTheme.accentPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            thirdPartyKeyboardFootnote
                        }
                    }
                    .padding(.bottom, HiTheme.spacingLG)
                    
                    if keyboardEnabled {
                        Button {
                            onboardingManager.goToNextStep()
                        } label: {
                            Text("Continue")
                        }
                        .buttonStyle(HiPrimaryButtonStyle())
                        .padding(.bottom, HiTheme.spacingSM)

                        Button {
                            openKeyboardSettings()
                        } label: {
                            Text("Open Settings")
                        }
                        .buttonStyle(HiTertiaryButtonStyle())
                        .padding(.bottom, HiTheme.spacingMD)
                    } else {
                        Button {
                            openKeyboardSettings()
                        } label: {
                            Text("Open Settings")
                        }
                        .buttonStyle(HiPrimaryButtonStyle())
                        .padding(.bottom, HiTheme.spacingXL)
                    }
                }
            }
            .padding(.horizontal, HiTheme.spacingLG)
        }
        .sheet(isPresented: $showPrivacyModal) {
            PrivacyInfoModal()
                .presentationDetents([.fraction(0.7)])
        }
        .onAppear {
            checkKeyboardStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkKeyboardStatus()
            }
        }
    }

    // MARK: - Subviews

    private var thirdPartyKeyboardFootnote: some View {
        Text("When using one of these keyboards, the keyboard can access all the data you type. [About Third-Party Keyboards & Privacy...](https://support.apple.com/guide/iphone/add-or-change-keyboards-iph73b71eb/ios)")
            .font(.footnote)
            .foregroundStyle(HiTheme.textTertiary)
            .tint(HiTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func checkKeyboardStatus() {
        let keyboardBundleID = "ai.hi-key.keyboard"
        let appleKeyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        keyboardEnabled = appleKeyboards.contains(keyboardBundleID)
    }
}

// MARK: - Privacy Info Modal

private struct PrivacyInfoModal: View {
    @Environment(\.dismiss) private var dismiss

    private static let privacyURL = URL(string: "https://hi-key.ai/privacy")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            .padding(.top, HiTheme.spacingMD)
            .padding(.trailing, HiTheme.spacingMD)

            VStack(spacing: HiTheme.spacingLG) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(HiTheme.accentPrimary)
                    .padding(.top, HiTheme.spacingXL)

                Text("We value your privacy")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(HiTheme.textPrimary)

                Text("hi-key requires Full Access to connect to our servers and generate images from your prompts. We only send the text you type in the hi-key prompt bar, never passwords, messages, or other content. Prompts and generated images are deleted from our servers within 10 minutes. We do not collect, share, or sell any personal data, and hi-key does not access your contacts, location, or browsing history.")
                    .font(.body)
                    .foregroundStyle(HiTheme.textSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Link(destination: Self.privacyURL) {
                    HStack(spacing: HiTheme.spacingXS) {
                        Text("Read full Privacy Policy")
                            .font(.footnote.weight(.medium))
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(HiTheme.accentPrimary)
                }
                .padding(.bottom, HiTheme.spacingLG)
            }
            .padding(.horizontal, HiTheme.spacingMD)
        }
        .background(HiTheme.surfacePrimary)
    }
}

#Preview {
    ZStack {
        HiAppBackground()

        EnableSettingsView()
    }
}
