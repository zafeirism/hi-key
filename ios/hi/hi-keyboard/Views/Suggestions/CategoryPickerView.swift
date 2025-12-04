import SwiftUI

// MARK: - Category Model

struct PromptCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let suggestions: [String]
}

// MARK: - Category Picker View

struct CategoryPickerView: View {
    @ObservedObject var viewModel: HiKeyboardViewModel
    @State private var selectedCategory: PromptCategory?
    
    // TODO: Move to a data source / configuration file
    private let categories: [PromptCategory] = [
        PromptCategory(
            name: "Styles",
            icon: "paintbrush",
            suggestions: ["photorealistic", "oil painting", "watercolor", "anime", "3D render", "sketch", "pixel art", "pop art"]
        ),
        PromptCategory(
            name: "Angles",
            icon: "camera.viewfinder",
            suggestions: ["close-up", "wide angle", "bird's eye view", "low angle", "profile shot", "overhead", "macro"]
        ),
        PromptCategory(
            name: "Lighting",
            icon: "sun.max",
            suggestions: ["golden hour", "neon lights", "dramatic shadows", "soft lighting", "backlit", "cinematic lighting", "studio lighting"]
        ),
        PromptCategory(
            name: "Colors",
            icon: "paintpalette",
            suggestions: ["vibrant", "pastel", "monochrome", "warm tones", "cool tones", "neon", "muted colors", "high contrast"]
        ),
        PromptCategory(
            name: "Weather",
            icon: "cloud.sun",
            suggestions: ["sunny", "rainy", "foggy", "snowy", "stormy", "cloudy", "sunset", "night sky"]
        ),
        PromptCategory(
            name: "People",
            icon: "person",
            suggestions: ["portrait", "group photo", "silhouette", "candid", "action pose", "profile", "headshot"]
        ),
        PromptCategory(
            name: "Animals",
            icon: "hare",
            suggestions: ["cat", "dog", "bird", "lion", "elephant", "butterfly", "fish", "dragon"]
        ),
        PromptCategory(
            name: "Objects",
            icon: "cube",
            suggestions: ["car", "building", "flower", "food", "furniture", "jewelry", "technology", "nature"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if let category = selectedCategory {
                // Show suggestions for selected category
                categoryChipsView(for: category)
            } else {
                // Show category grid
                categoryGrid
            }
        }
        .frame(height: 264) // Same as keyboard height
        .background(Color(.systemGray6))
    }
    
    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(categories) { category in
                    CategoryButton(category: category) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func categoryChipsView(for category: PromptCategory) -> some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(category.name)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.accentColor)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Suggestion chips
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(category.suggestions, id: \.self) { suggestion in
                        SuggestionChip(text: suggestion) {
                            viewModel.addToPrompt(suggestion + " ")
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

// MARK: - Category Button

private struct CategoryButton: View {
    let category: PromptCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                Text(category.name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

