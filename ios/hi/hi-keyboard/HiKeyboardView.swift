import SwiftUI
import KeyboardKit

struct HiKeyboardView: View {
    
    let services: Keyboard.Services
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom prompt bar at the top
            promptBar
            
            // KeyboardKit's standard keyboard
            KeyboardView(
                layout: nil,
                services: services
            )
        }
    }
    
    // MARK: - Prompt Bar
    
    private var promptBar: some View {
        HStack(spacing: 8) {
            // Back button (shows when we have results and are editing)
            if viewModel.hasResults && viewModel.isPromptFocused {
                Button {
                    viewModel.unfocusPrompt()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 32)
            }
            
            // Custom prompt display (tappable to focus)
            promptField
            
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
    
    // MARK: - Custom Prompt Field
    
    private var promptField: some View {
        HStack {
            // Show prompt text or placeholder
            if viewModel.prompt.isEmpty {
                Text("Describe an image...")
                    .foregroundColor(.gray)
            } else {
                Text(viewModel.prompt)
                    .foregroundColor(.primary)
            }
            
            // Blinking cursor when focused
            if viewModel.isPromptFocused {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(viewModel.isPromptFocused ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.focusPrompt()
        }
    }
}
