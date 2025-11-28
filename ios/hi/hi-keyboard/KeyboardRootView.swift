import SwiftUI
import KeyboardKit
import Combine

struct KeyboardRootView: View {
    @StateObject private var viewModel = KeyboardViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showingResults {
                // Results view - show images
                resultsView
            } else {
                // Keyboard view - show keys + toolbar
                keyboardView
            }
        }
    }
    
    // MARK: - Keyboard View (with keys)
    
    private var keyboardView: some View {
        VStack(spacing: 0) {
            // Custom toolbar with prompt field
            customToolbar
            
            // Spacer to push toolbar to top and indicate keyboard area
            Color(.systemGray5)
                .overlay(
                    Text("Keyboard keys will appear here")
                        .foregroundColor(.secondary)
                )
        }
    }
    
    // MARK: - Custom Toolbar
    
    private var customToolbar: some View {
        HStack(spacing: 8) {
            // Prompt input field
            TextField("Type a prompt...", text: $viewModel.prompt)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .font(.system(size: 15))
            
            // Generate button
            Button {
                Task {
                    await viewModel.generate()
                }
            } label: {
                if viewModel.isRequestingGeneration {
                    ProgressView()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(viewModel.prompt.isEmpty ? Color.gray : Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.prompt.isEmpty || viewModel.isRequestingGeneration)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    viewModel.reset()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16))
                }
                .padding(.leading, 12)
                
                Spacer()
                
                Text("Tap to copy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
            }
            .frame(height: 44)
            .background(Color(.systemGray6))
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
            }
            
            // Images
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        imageSlot(at: index)
                    }
                }
                .padding(16)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Image Slot
    
    @ViewBuilder
    private func imageSlot(at index: Int) -> some View {
        if index < viewModel.imageURLs.count {
            let imageURL = viewModel.imageURLs[index]
            
            RetryableAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .onTapGesture {
                        viewModel.copyImage(url: imageURL)
                    }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class KeyboardViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var isRequestingGeneration = false
    @Published var errorMessage: String?
    @Published var imageURLs: [String] = []
    @Published var showingResults = false
    
    private let apiClient = APIClient.shared
    private let tokenStorage = AuthTokenStorage.shared
    private var sessionID: String
    
    init() {
        self.sessionID = apiClient.newSessionID()
    }
    
    func generate() async {
        guard !prompt.isEmpty else { return }
        
        guard let accessToken = tokenStorage.getAccessToken() else {
            errorMessage = "Not logged in. Open the hi app first."
            return
        }
        
        isRequestingGeneration = true
        errorMessage = nil
        
        do {
            let requestID = apiClient.newRequestID()
            let response = try await apiClient.generate(
                prompt: prompt,
                sessionID: sessionID,
                requestID: requestID,
                accessToken: accessToken
            )
            
            imageURLs = response.signedUrls
            isRequestingGeneration = false
            showingResults = true
            
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
            isRequestingGeneration = false
        }
    }
    
    func copyImage(url: String) {
        // TODO: Download and copy image to pasteboard
        print("Copy image: \(url)")
    }
    
    func reset() {
        showingResults = false
        // Don't clear prompt - let user edit and regenerate
        imageURLs = []
        errorMessage = nil
    }
}

// MARK: - Retryable AsyncImage

struct RetryableAsyncImage<Content: View>: View {
    let url: String
    let content: (Image) -> Content
    
    @State private var retryKey = 0
    @State private var hasFailed = false
    
    private let maxRetries = 150
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder
                
            case .success(let image):
                content(image)
                
            case .failure:
                if retryKey < maxRetries && !hasFailed {
                    loadingPlaceholder
                        .onAppear {
                            Task {
                                try? await Task.sleep(nanoseconds: 200_000_000)
                                retryKey += 1
                            }
                        }
                } else {
                    failurePlaceholder
                        .onAppear {
                            hasFailed = true
                        }
                }
                
            @unknown default:
                loadingPlaceholder
            }
        }
        .id(retryKey)
    }
    
    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 200, height: 200)
            
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var failurePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 200, height: 200)
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                Text("Failed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
