import SwiftUI
import Combine

struct SuggestionBarView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    @ObservedObject private var network = NetworkMonitor.shared
    @ObservedObject private var fullAccess = FullAccessMonitor.shared

    @State private var suggestions: [String] = []
    @State private var autocompleteTask: Task<Void, Never>?
    @State private var debounceTimer: Timer?

    private let apiClient = APIClient.shared
    private let lightHapticGenerator = UIImpactFeedbackGenerator(style:.light)

    // Full access takes precedence over connectivity — the keyboard cannot
    // reach the network at all without the permission, so naming the
    // proximate cause is more useful to the user than reporting "offline".
    private var showsFullAccessStatus: Bool {
        !fullAccess.hasFullAccess || fullAccess.showJustEnabled
    }

    private var showsNetworkStatus: Bool {
        !network.isOnline || network.showBackOnline
    }

    var body: some View {
        ZStack {
            if showsFullAccessStatus {
                FullAccessStatusView(isJustEnabled: fullAccess.hasFullAccess)
                    .transition(.opacity)
            } else if showsNetworkStatus {
                NetworkStatusView(isBackOnline: network.isOnline)
                    .transition(.opacity)
            } else {
                suggestionsScroll
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showsFullAccessStatus)
        .animation(.easeInOut(duration: 0.25), value: showsNetworkStatus)
        .background(Color.clear)
        .onAppear {
            handlePromptChange(viewModel.promptUpToCursor())
        }
        .onChange(of: viewModel.prompt) { _, _ in
            handlePromptChange(viewModel.promptUpToCursor())
        }
    }

    private var suggestionsScroll: some View {
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
        
        // Debounce 1000ms before calling autocomplete
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task { @MainActor in
                await fetchAutocomplete(for: newPrompt)
            }
        }
    }
    
    // MARK: - Autocomplete API
    
    private func fetchAutocomplete(for prompt: String) async {
        autocompleteTask = Task {
            do {
                let response = try await apiClient.autocomplete(prompt: prompt)
                
                guard !Task.isCancelled else { return }
                
                print("Autocomplete returned: \(response.completion) (took \(response.duration)s)")
                
                // Show the completion as the only suggestion
                if !response.completion.isEmpty {
                    suggestions = ["..." + response.completion]
                } else {
                    suggestions = []
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                HiLogger.error("Autocomplete failed", error: error, category: .keyboard)
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
        
        lightHapticGenerator.impactOccurred()
        
        let withoutDots = suggestion.hasPrefix("...") ? String(suggestion.dropFirst(3)) : suggestion
        
        viewModel.addToPrompt(withoutDots + " ")
        
        // Clear suggestions with animation
        suggestions = []
    }
}

// MARK: - Full Access Status View

private struct FullAccessStatusView: View {
    let isJustEnabled: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isJustEnabled ? "checkmark.circle" : "lock")
                .contentTransition(.symbolEffect(.replace))
            Text(isJustEnabled ? "Full access enabled" : "Open hi-key to enable Full Access")
                .contentTransition(.opacity)
        }
        .font(.callout)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isJustEnabled)
    }
}

// MARK: - Network Status View

private struct NetworkStatusView: View {
    let isBackOnline: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isBackOnline ? "checkmark.circle" : "wifi.slash")
                .contentTransition(.symbolEffect(.replace))
            Text(isBackOnline ? "Back online" : "No internet")
                .contentTransition(.opacity)
        }
        .font(.callout)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isBackOnline)
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

