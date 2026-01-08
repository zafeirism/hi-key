import SwiftUI

struct KeyboardSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var step1Completed = false
    @State private var step2Completed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: HiTheme.spacingXL) {
                    // Header
                    headerSection
                    
                    // Steps
                    VStack(spacing: HiTheme.spacingLG) {
                        SetupStepCard(
                            stepNumber: 1,
                            title: "Add hi-key Keyboard",
                            instructions: [
                                "Open Settings → General → Keyboard",
                                "Tap \"Keyboards\"",
                                "Tap \"Add New Keyboard...\"",
                                "Select \"hi-key\"",
                            ],
                            isCompleted: step1Completed
                        )
                        
                        SetupStepCard(
                            stepNumber: 2,
                            title: "Allow Full Access",
                            instructions: [
                                "In Keyboards, tap \"hi-key\"",
                                "Enable \"Allow Full Access\"",
                                "Tap \"Allow\" in the popup",
                            ],
                            isCompleted: step2Completed
                        )
                    }
                    
                    Spacer()
                    
                    // Open Settings button
                    openSettingsButton
                    
                    // Done button
                    doneButton
                }
                .padding(HiTheme.spacingLG)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(HiTheme.body())
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkSetupStatus()
        }
        .onAppear {
            checkSetupStatus()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 48))
                .foregroundColor(HiTheme.mint)
            
            Text("Set up your keyboard")
                .font(HiTheme.title(24))
                .foregroundColor(.primary)
            
            Text("Follow these steps to start using\nhi-key in all your apps")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Open Settings Button
    
    private var openSettingsButton: some View {
        Button {
            openKeyboardSettings()
        } label: {
            HStack {
                Image(systemName: "gear")
                Text("Open Keyboard Settings")
            }
            .hiButtonStyle()
        }
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("I'll do this later")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func openKeyboardSettings() {
        // Try to open keyboard settings directly
        if let url = URL(string: "App-prefs:General&path=Keyboard/KEYBOARDS") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to general settings
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func checkSetupStatus() {
        let keyboardBundleID = "ai.hi-key.keyboard"
        let activeInputModes = UITextInputMode.activeInputModes
        
        let isKeyboardEnabled = activeInputModes.contains { mode in
            mode.value(forKey: "identifier") as? String == keyboardBundleID
        }
        
        withAnimation(HiTheme.animationNormal) {
            step1Completed = isKeyboardEnabled
            // We assume full access is granted if keyboard is enabled
            // In practice, you might need app group UserDefaults to verify this
            step2Completed = isKeyboardEnabled
        }
    }
}

// MARK: - Setup Step Card

private struct SetupStepCard: View {
    let stepNumber: Int
    let title: String
    let instructions: [String]
    let isCompleted: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: HiTheme.spacingMD) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color(.systemGray5))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(HiTheme.subtitle())
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                Text(title)
                    .font(HiTheme.subtitle())
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                
                if !isCompleted {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(HiTheme.caption())
                                    .foregroundColor(.secondary)
                                
                                Text(instruction)
                                    .font(HiTheme.caption())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(HiTheme.spacingLG)
        .background(Color(.systemGray6))
        .cornerRadius(HiTheme.radiusLG)
    }
}

#Preview {
    KeyboardSetupSheet()
}

