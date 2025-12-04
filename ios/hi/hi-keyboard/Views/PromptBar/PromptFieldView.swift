import SwiftUI

struct PromptFieldView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    promptContent
                    // Add some safe space from the clear button
                        .padding(.trailing, 80)
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
            
            clearButton
        }
        .frame(height: 36)
        .padding(.horizontal, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.focusPrompt() }
        .disabled(viewModel.isGenerating)
    }
    
    @ViewBuilder
    private var promptContent: some View {
        HStack(spacing: 0) {
            // Cursor at start - always reserve space so that placeholder doesn't jump
            BlinkingCursor()
                .opacity(viewModel.isPromptFocused && viewModel.prompt.isEmpty ? 1 : 0)
            
            if viewModel.prompt.isEmpty {
                Text("Describe an image")
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(viewModel.prompt.enumerated()), id: \.offset) { index, character in
                    CharacterView(
                        character: character,
                        index: index,
                        viewModel: viewModel
                    )
                }
                
                // Cursor at end (after last character)
                if viewModel.isPromptFocused && viewModel.cursorPosition == viewModel.prompt.count {
                    BlinkingCursor()
                        .id("cursor")
                }
            }
        }
    }
    
    private var clearButton: some View {
        Button { viewModel.clearPrompt() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.leading, 8)
        .opacity(viewModel.prompt.isEmpty || !viewModel.isPromptFocused ? 0 : 1)
        .disabled(viewModel.prompt.isEmpty || !viewModel.isPromptFocused)
    }
}

// MARK: - Character View

private struct CharacterView: View {
    let character: Character
    let index: Int
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    var body: some View {
        ZStack(alignment: .leading) {
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
}

