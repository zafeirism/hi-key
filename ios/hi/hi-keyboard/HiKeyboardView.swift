import SwiftUI
import KeyboardKit

struct HiKeyboardView: View {
    
    /// KeyboardKit services (passed from controller)
    let services: Keyboard.Services
    
    @StateObject private var viewModel = HiKeyboardViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Your custom prompt bar at the top
            promptBar
            
            // KeyboardKit's standard keyboard view
            KeyboardView(
                layout: nil,  // nil = use default layout
                services: services
            )
        }
    }
    
    // MARK: - Prompt Bar
    
    private var promptBar: some View {
        HStack(spacing: 8) {
            // Back button (only shows when we have results)
            if viewModel.hasResults && !viewModel.isEditing {
                Button {
                    viewModel.showResults()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 32)
            }
            
            // Prompt text field
            TextField("Describe an image...", text: $viewModel.prompt)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 15))
            
            // Generate button
            Button {
                Task {
                    await viewModel.generate()
                }
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(viewModel.prompt.isEmpty ? Color.gray : Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.prompt.isEmpty || viewModel.isGenerating)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}
