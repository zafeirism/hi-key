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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Cursor at start - always reserve space so that placeholder doesn't jump
                        BlinkingCursor()
                            .opacity(viewModel.isPromptFocused && viewModel.prompt.isEmpty ? 1 : 0)
                        
                        if viewModel.prompt.isEmpty {
                            Text("Describe an image...")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(viewModel.prompt.enumerated()), id: \.offset) { index, character in
                                ZStack(alignment: .leading) {
                                    // Show cursor before this character if position matches
                                    if viewModel.isPromptFocused && viewModel.cursorPosition == index {
                                        BlinkingCursor()
                                            .id("cursor")
                                    }
                                    
                                    Text(String(character))
                                        .foregroundColor(.primary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.focusPrompt()
                                    viewModel.setCursorPosition(index)
                                }
                            }
                            // Cursor at end (after last character)
                            if viewModel.isPromptFocused && viewModel.cursorPosition == viewModel.prompt.count {
                                BlinkingCursor()
                                    .id("cursor")
                            }
                        }
                    }
                    .padding(.trailing, 24) // Small buffer so text is far from clear-button
                }
                .onChange(of: viewModel.cursorPosition) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("cursor", anchor: .center)
                    }
                }
                .onChange(of: viewModel.prompt) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("cursor", anchor: .center)
                    }
                }
            }
            
            // Clear button
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
