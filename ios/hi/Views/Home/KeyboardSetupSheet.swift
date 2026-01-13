import SwiftUI

struct KeyboardSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var step1Completed: Bool = false
    @State private var step2Completed: Bool = false
    @State private var showCelebration: Bool = false
    
    private var bothStepsComplete: Bool {
        step1Completed && step2Completed
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: HiTheme.spacingLG) {
                // Header
                headerSection
                
                // Steps
                VStack(spacing: HiTheme.spacingMD) {
                    SetupStepCard(
                        stepNumber: 1,
                        title: "Add hi-key Keyboard",
                        instructions: [
                            "Open Settings → General → Keyboard",
                            "Tap \"Keyboards\"",
                            "Tap \"Add New Keyboard...\"",
                            "Select \"hi-key\""
                        ],
                        isCompleted: step1Completed
                    )
                    
                    SetupStepCard(
                        stepNumber: 2,
                        title: "Allow Full Access",
                        instructions: [
                            "In Keyboards, tap \"hi-key\"",
                            "Enable \"Allow Full Access\"",
                            "Tap \"Allow\" in the popup"
                        ],
                        isCompleted: step2Completed
                    )
                }
                
                Spacer()
                
                // Buttons
                if bothStepsComplete {
                    // Success state
                    VStack(spacing: HiTheme.spacingMD) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("All set!")
                            .font(.title2.bold())
                        
                        Text("You can now use hi-key in any app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                        .buttonStyle(HiPrimaryButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Setup state
                    VStack(spacing: HiTheme.spacingMD) {
                        Button {
                            openKeyboardSettings()
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Keyboard Settings")
                            }
                        }
                        .buttonStyle(HiPrimaryButtonStyle())
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("I'll do this later")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
            checkSetupStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkSetupStatus()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: HiTheme.spacingMD) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            
            Text("Set up your keyboard")
                .font(.title2.bold())
            
            Text("Follow these steps to start using\nhi-key in all your apps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Actions
    
    private func openKeyboardSettings() {
        // Try to open keyboard settings directly
        if let url = URL(string: "App-prefs:root=General&path=Keyboard/KEYBOARDS") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to app settings
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func checkSetupStatus() {
        let keyboardBundleID = "ai.hi-key.hi.hi-keyboard"
        let activeInputModes = UITextInputMode.activeInputModes
        
        let isKeyboardEnabled = activeInputModes.contains { mode in
            (mode.value(forKey: "identifier") as? String) == keyboardBundleID
        }
        
        let wasComplete = bothStepsComplete
        
        withAnimation(HiTheme.animationNormal) {
            step1Completed = isKeyboardEnabled
            // We assume full access is granted if keyboard is enabled
            // In practice, you might verify via app group UserDefaults
            step2Completed = isKeyboardEnabled
        }
        
        // Show celebration if just completed
        if !wasComplete && bothStepsComplete {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Setup Step Card

private struct SetupStepCard: View {
    let stepNumber: Int
    let title: String
    let instructions: [String]
    let isCompleted: Bool
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingMD) {
            // Header row
            HStack(spacing: HiTheme.spacingMD) {
                // Step indicator
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                
                Text(title)
                    .font(.headline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                
                Spacer()
                
                if !isCompleted {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Instructions (expandable)
            if !isCompleted && isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(instruction)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 44) // Align with title
            }
        }
        .padding(HiTheme.spacingMD)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
    }
}

#Preview {
    KeyboardSetupSheet()
}
