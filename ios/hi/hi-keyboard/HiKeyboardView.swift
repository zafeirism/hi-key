import SwiftUI
import KeyboardKit

struct HiKeyboardView: View {
    
    let services: Keyboard.Services
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            promptBar
            
            KeyboardView(
                layout: nil,
                services: services
            )
        }
    }
    
    // MARK: - Prompt Bar
    
    private var promptBar: some View {
        HStack(spacing: 8) {
            // Back button for results
            if viewModel.hasResults && !viewModel.isPromptFocused {
                Button {
                    // TODO: Show results view
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 28)
            }
            
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
        .background(Color.clear)
    }
    
    // MARK: - Prompt Field

    private var promptField: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                // Cursor at start - always reserve space
                BlinkingCursor()
                    .padding(.trailing, 1)
                    .opacity(viewModel.isPromptFocused && viewModel.prompt.isEmpty ? 1 : 0)
                
                if viewModel.prompt.isEmpty {
                    Text("Describe an image...")
                        .foregroundColor(.gray)
                } else {
                    Text(viewModel.prompt)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    
                    if viewModel.isPromptFocused {
                        BlinkingCursor()
                            .padding(.leading, 1)
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            // Clear button - lighter gray
            Button {
                viewModel.clearPrompt()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.leading, 8)
            .opacity(viewModel.prompt.isEmpty ? 0 : 1)
            .disabled(viewModel.prompt.isEmpty)
        }
        .frame(height: 36)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        // Removed the .overlay with stroke
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.focusPrompt()
        }
    }
}

// MARK: - Blinking Cursor

struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2, height: 18)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
