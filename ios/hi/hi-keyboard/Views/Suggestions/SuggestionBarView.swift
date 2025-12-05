import SwiftUI

struct SuggestionBarView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    // TODO: Replace with dynamic suggestions based on prompt
    private var suggestions: [String] {
        // Placeholder suggestions - implement AI/local suggestions logic
        ["vibrant colors", "cinematic lighting", "4K detailed", "photorealistic"]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        viewModel.addToPrompt(suggestion + ", ")
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.001)) //clear but tapable
                .cornerRadius(4)
        }
    }
}

