import SwiftUI
import Combine
import os

struct SuggestionBarView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    
    @State private var suggestions: [String] = []
    @State private var autocompleteTask: Task<Void, Never>?
    @State private var debounceTimer: Timer?
    
    private let tokenStorage = AuthTokenStorage.shared
    private let apiClient = APIClient.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        handleSuggestionTap(suggestion)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .animation(.easeOut(duration: 0.2), value: suggestions)
        }
        .background(Color.clear)
        .onAppear {
            handlePromptChange(viewModel.promptUpToCursor())
        }
        .onChange(of: viewModel.prompt) { _, _ in
            handlePromptChange(viewModel.promptUpToCursor())
        }
    }
    
    // MARK: - Initial Suggestions
    
    private func loadInitialSuggestions() {
        suggestions = PromptCategories.randomStyles(4)
    }
    
    // MARK: - Handle Prompt Changes
    
    private func handlePromptChange(_ newPrompt: String) {
        // Cancel any pending autocomplete
        debounceTimer?.invalidate()
        autocompleteTask?.cancel()
        
        // If prompt is empty, show random styles
        guard !newPrompt.isEmpty else {
            loadInitialSuggestions()
            return
        }
        
        // Debounce 300ms before calling autocomplete
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task { @MainActor in
                await fetchAutocomplete(for: newPrompt)
            }
        }
    }
    
    // MARK: - Autocomplete API
    
    private func fetchAutocomplete(for prompt: String) async {
        guard let accessToken = tokenStorage.getAccessToken() else {
            HiLogger.api.warning("⚠️ No access token for autocomplete")
            return
        }
        
        autocompleteTask = Task {
            do {
                let response = try await apiClient.autocomplete(
                    prompt: prompt,
                    accessToken: accessToken
                )
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                HiLogger.api.info("✅ Autocomplete returned: \(response.completion) (took \(response.duration)s)")
                
                // Show the completion as the only suggestion
                if !response.completion.isEmpty {
                    suggestions = [response.completion]
                } else {
                    suggestions = []
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                HiLogger.api.error("❌ Autocomplete failed: \(error.localizedDescription)")
                // On error, keep current suggestions or clear
                suggestions = []
            }
        }
        
        await autocompleteTask?.value
    }
    
    // MARK: - Handle Tap
    
    private func handleSuggestionTap(_ suggestion: String) {
        // Focus prompt if not already
        if !viewModel.isPromptFocused {
            viewModel.focusPrompt()
        }
        
        viewModel.addToPrompt(suggestion + " ")
        
        // Clear suggestions with animation
        suggestions = []
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
                .background(Color.white.opacity(0.001)) // clear but tappable
                .cornerRadius(4)
        }
    }
}

