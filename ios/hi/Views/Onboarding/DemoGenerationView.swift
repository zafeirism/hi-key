import SwiftUI

struct DemoGenerationView: View {
    @StateObject private var viewModel = DemoViewModel()
    @ObservedObject var onboardingManager = OnboardingManager.shared
    @FocusState private var isPromptFocused: Bool
    
    // Sample prompts for suggestions
    private let suggestions = [
        "A cat astronaut exploring Mars",
        "Cozy cabin in snowy mountains",
        "Underwater city with neon lights",
        "Vintage robot in a flower garden",
        "Steampunk airship at sunset",
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, HiTheme.spacingLG)
                    .padding(.top, HiTheme.spacingMD)
                
                // Main content area
                if viewModel.showingResults || viewModel.isGenerating {
                    resultsSection
                } else {
                    emptyStateSection
                }
                
                Spacer(minLength: 0)
                
                // Suggestions
                if !viewModel.showingResults && !viewModel.isGenerating {
                    suggestionsSection
                }
                
                // Input area
                inputSection
                    .padding(.horizontal, HiTheme.spacingLG)
                    .padding(.bottom, HiTheme.spacingMD)
                
                // Continue button (shown after first generation)
                if onboardingManager.hasGeneratedAtLeastOnce {
                    continueButton
                        .padding(.horizontal, HiTheme.spacingLG)
                        .padding(.bottom, HiTheme.spacingSM)
                }
            }
        }
        .onTapGesture {
            isPromptFocused = false
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: HiTheme.spacingSM) {
            Text("Create your first image")
                .font(HiTheme.title(28))
                .foregroundColor(.primary)
            
            Text("Describe anything you can imagine")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, HiTheme.spacingMD)
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        DemoResultsView(viewModel: viewModel)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Empty State
    
    private var emptyStateSection: some View {
        VStack(spacing: HiTheme.spacingLG) {
            Spacer()
            
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundColor(HiTheme.mint)
            
            Text("Your images will appear here")
                .font(HiTheme.body())
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
    
    // MARK: - Suggestions
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
            Text("Try one of these")
                .font(HiTheme.caption())
                .foregroundColor(.secondary)
                .padding(.horizontal, HiTheme.spacingLG)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HiTheme.spacingSM) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionPill(text: suggestion) {
                            viewModel.setPrompt(suggestion)
                        }
                    }
                }
                .padding(.horizontal, HiTheme.spacingLG)
            }
        }
        .padding(.bottom, HiTheme.spacingMD)
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        HStack(spacing: HiTheme.spacingSM) {
            // Text field
            TextField("Describe an image...", text: $viewModel.prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .font(HiTheme.body())
                .padding(.horizontal, HiTheme.spacingMD)
                .padding(.vertical, HiTheme.spacingSM)
                .background(Color(.systemGray6))
                .cornerRadius(HiTheme.radiusXL)
                .focused($isPromptFocused)
                .lineLimit(1...3)
                .submitLabel(.send)
                .onSubmit {
                    if !viewModel.prompt.isEmpty && onboardingManager.canGenerateDemo {
                        Task { await viewModel.generate() }
                    }
                }
            
            // Generate button
            Button {
                isPromptFocused = false
                Task { await viewModel.generate() }
            } label: {
                Image(systemName: viewModel.isGenerating ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(canGenerate ? HiTheme.mint : Color(.systemGray4))
                    .symbolEffect(.bounce, isActive: viewModel.isGenerating)
            }
            .disabled(!canGenerate)
        }
    }
    
    private var canGenerate: Bool {
        !viewModel.prompt.isEmpty && !viewModel.isGenerating && onboardingManager.canGenerateDemo
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            onboardingManager.goToNextStep()
        } label: {
            HStack {
                Text("Continue")
                Image(systemName: "arrow.right")
            }
            .font(HiTheme.subtitle())
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(HiTheme.radiusFull)
        }
    }
}

// MARK: - Suggestion Pill

private struct SuggestionPill: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(HiTheme.caption())
                .foregroundColor(.primary)
                .padding(.horizontal, HiTheme.spacingMD)
                .padding(.vertical, HiTheme.spacingSM)
                .background(Color(.systemGray6))
                .cornerRadius(HiTheme.radiusFull)
        }
    }
}

// MARK: - Demo Results View

/// Adapted version of ResultsView for the main app demo.
/// Uses DemoViewModel instead of HiKeyboardViewModel.
struct DemoResultsView: View {
    @ObservedObject var viewModel: DemoViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task { await viewModel.generate() }
                }
            } else {
                ZStack {
                    DemoImageCarouselView(viewModel: viewModel)
                    
                    VStack {
                        Text("Tap to copy, then paste anywhere")
                            .font(.system(.callout))
                            .foregroundStyle(.secondary)
                            .padding(.top, HiTheme.spacingMD)
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 280)
    }
}

// MARK: - Demo Image Carousel View

/// Adapted version of ImageCarouselView for the main app demo.
struct DemoImageCarouselView: View {
    @ObservedObject var viewModel: DemoViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: HiTheme.spacingSM) {
                        ForEach(viewModel.sortedImages) { image in
                            ImageCardView(
                                image: image,
                                onCopy: { viewModel.copyImage(image) },
                                onLoaded: { data in viewModel.markImageLoaded(image.id, data: data) },
                                onTap: { viewModel.copyImage(image) }
                            )
                            .id(image.id)
                        }
                        
                        if viewModel.isGenerating {
                            ForEach(0..<4, id: \.self) { index in
                                DemoLoadingPlaceholderView()
                                    .id("placeholder-\(index)")
                            }
                        }
                    }
                    .padding(.horizontal, HiTheme.spacingMD)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.sortedImages.map { $0.id })
                }
                .onChange(of: viewModel.isGenerating) { _, isGenerating in
                    if isGenerating {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("placeholder-0", anchor: UnitPoint(x: 0.2, y: 0))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Placeholder (reused from keyboard)

struct DemoLoadingPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: HiTheme.radiusMD)
            .fill(Color(.systemGray5))
            .frame(width: 200, height: 200)
            .overlay(
                ProgressView()
                    .scaleEffect(1.2)
            )
            .shimmer()
    }
}

#Preview {
    DemoGenerationView()
}

