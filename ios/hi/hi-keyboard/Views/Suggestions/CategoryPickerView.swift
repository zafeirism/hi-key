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
    @State private var selectedCategoryIndex: Int = 0
    @State private var isScrollingProgrammatically = false
    
    private let categories: [PromptCategory] = [
        PromptCategory(
            name: "Styles",
            icon: "paintbrush",
            suggestions: ["Watercolor", "Oil painting", "Pastel", "Charcoal", "Comic book", "Manga", "Graphic novel", "Pixar-like", "Ghibli-like", "Disney Renaissance", "90s anime", "Impressionist", "Surrealist", "Expressionist", "Pop art", "Vaporwave", "Synthwave", "Cyberpunk", "Steampunk", "Photorealistic", "Cinematic", "Documentary", "Analog film", "Retro poster", "Minimalism", "Low poly", "Pixel art", "Sketch", "3D render", "Realism", "Hyperrealism", "Baroque", "Rococo", "Art Nouveau", "Art Deco", "Cubism", "Fauvism", "Ukiyo-e", "Noir", "Film noir", "Neon noir", "Fantasy illustration", "Matte painting", "Isometric", "Line art", "Chiaroscuro", "Graffiti", "Street art"]
        ),
        PromptCategory(
            name: "Angles",
            icon: "camera.viewfinder",
            suggestions: ["Full body shot", "Close-up shot", "Extreme close-up shot", "Extreme long shot", "High angle shot", "Low angle shot", "Bird's-eye view shot", "Worm's-eye view shot", "Dutch angle shot", "Side profile shot", "Over-the-shoulder shot", "Off-center shot", "Shot from behind", "Point-of-view shot", "Medium shot", "Medium close-up shot", "Medium long shot", "Three-quarter shot", "Front-facing shot", "Back-facing shot", "Wide shot", "Establishing shot", "Top-down shot", "Tilted shot", "Tracking shot", "Static shot"]
        ),
        PromptCategory(
            name: "Techniques",
            icon: "movieclapper",
            suggestions: ["Motion blur", "Light trails", "Lens flares", "Depth of field", "Bokeh", "Long exposure", "Slow shutter effect", "Vignetting", "Film grain", "Chromatic aberration", "Split diopter effect", "Rack focus", "Soft focus", "Backlighting", "Silhouette lighting", "High dynamic range", "Low-key lighting", "High-key lighting", "Volumetric lighting", "God rays"]
        ),
        PromptCategory(
            name: "Lighting",
            icon: "sun.max",
            suggestions: ["Dawn", "Golden hour", "Twilight", "Midnight", "Hard lighting", "Soft lighting", "Rim lighting", "Backlighting", "Volumetric lighting", "Neon reflections", "Underlighting", "Ambient occlusion", "High contrast mood", "Low contrast mood", "Overcast lighting", "Studio lighting", "Natural lighting", "Candlelight", "Firelight", "Moonlight", "Spotlighting", "Fill lighting", "Key lighting", "Bounce lighting", "Chiaroscuro lighting", "Silhouette lighting", "Bioluminescent lighting", "HDR lighting"]
        ),
        PromptCategory(
            name: "Colors",
            icon: "paintpalette",
            suggestions: ["Highly saturated", "Pastel", "Neon", "Earth tones", "Teal and orange", "Noir desaturated", "Retro faded", "Vibrant", "Monochrome", "Warm tones", "Cool tones", "Muted colors", "Duotone", "Gradient color scheme", "Iridescent colors", "Metallic palette", "Primary color palette", "Analogous colors", "Complementary colors", "Triadic color harmony", "Cinematic color grading", "Soft washed-out tones", "Deep rich tones"]
        ),
        PromptCategory(
            name: "Weather",
            icon: "cloud.sun",
            suggestions: ["Fog", "Haze", "Smoke", "Dust", "Sunny", "Rainy", "Snowy", "Stormy", "Windy", "Cloudy", "Clear sky", "Overcast", "Mist", "Drizzle", "Heavy rain", "Thunderstorm", "Blizzard", "Sleet", "Humid atmosphere"]
        ),
        PromptCategory(
            name: "People",
            icon: "person",
            suggestions: ["Long hair", "Brown hair", "Ponytail", "Short hair", "Bald", "Bearded", "Curly hair", "Wavy hair", "Blonde hair", "Black hair", "Red hair", "Freckles", "Wrinkled", "Youthful", "Fit", "Athletic build", "Slim build", "Stocky build", "Casual clothing", "Elegant clothing", "Streetwear", "Stoic expression", "Joyful expression", "Angry expression", "Neutral expression", "Sad", "Ecstatic", "Smiling", "Frowning", "Glasses", "Blue eyes", "Dark eyes", "Brown eyes", "Mustache", "Goatee", "Braids", "Updo hairstyle", "Tan skin", "Pale skin", "Dark skin"]
        ),
        PromptCategory(
            name: "Environment",
            icon: "mountain.2",
            suggestions: ["Urban", "Rural", "Futuristic city", "Post-apocalyptic wasteland", "Medieval", "Futuristic", "Cyberpunk metropolis", "Steampunk town", "Desert landscape", "Tropical jungle", "Frozen tundra", "Mountain village", "Coastal harbor", "Dense forest", "Underground bunker", "Space station", "Alien planet", "Ancient ruins", "Victorian city", "Modern suburban neighborhood", "Industrial zone", "Fantasy kingdom", "High-tech laboratory"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            suggestionGrid
            Spacer(minLength: 0)
            categoryBar
        }
        .frame(height: 264)
        .background(Color.clear)
    }
    
    // MARK: - Suggestion Grid (4 independent horizontal lanes)
    
    private var suggestionGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 40) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryLanes(
                            category: category,
                            laneHeight: 57,
                            onTap: { suggestion in
                                viewModel.addToPrompt(suggestion + ", ")
                            }
                        )
                        .id(index)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: CategoryVisibilityPreference.self,
                                        value: [index: geo.frame(in: .named("scroll")).minX]
                                    )
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(CategoryVisibilityPreference.self) { positions in
                    // Only update if not programmatically scrolling
                    guard !isScrollingProgrammatically else { return }
                    updateSelectedCategory(from: positions)
                }
                .onChange(of: selectedCategoryIndex) {newIndex in
                    // Set flag to prevent preference from overriding
                    isScrollingProgrammatically = true
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .leading)
                    }
                    
                    // Reset flag after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        isScrollingProgrammatically = false
                    }
                }
        }
    }
    
    // MARK: - Category Bar
    
    private var categoryBar: some View {
        HStack(spacing: 8) {
            // ABC button to return to keyboard
            Button {
                viewModel.showSuggestions = false
            } label: {
                Text("ABC")
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.clear)
            }
            
            // Category icons scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        CategoryIcon(
                            icon: category.icon,
                            isSelected: selectedCategoryIndex == index
                        ) {
                            // Explicitly set to trigger onChange
                            if selectedCategoryIndex != index {
                                selectedCategoryIndex = index
                            }
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Color.clear)
    }
    
    // MARK: - Helpers
    
    private func updateSelectedCategory(from positions: [Int: CGFloat]) {
        let visibleCategories = positions.filter { $0.value < 100 && $0.value > -200 }
        if let closest = visibleCategories.min(by: { abs($0.value) < abs($1.value) }) {
            if selectedCategoryIndex != closest.key {
                selectedCategoryIndex = closest.key
            }
        }
    }
}

// MARK: - Category Lanes (4 independent horizontal rows)

private struct CategoryLanes: View {
    let category: PromptCategory
    let laneHeight: CGFloat
    let onTap: (String) -> Void
    
    // Split suggestions into 4 lanes (every 4th item goes to same lane)
    private var lanes: [[String]] {
        var result: [[String]] = [[], [], [], []]
        for (index, suggestion) in category.suggestions.enumerated() {
            result[index % 4].append(suggestion)
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<4, id: \.self) { laneIndex in
                HStack(spacing: 30) {
                    ForEach(lanes[laneIndex], id: \.self) { suggestion in
                        SuggestionTextButton(text: suggestion) {
                            onTap(suggestion)
                        }
                    }
                }
                .frame(height: laneHeight, alignment: .leading)
            }
        }
    }
}

// MARK: - Suggestion Text Button

private struct SuggestionTextButton: View {
    let text: String
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(.body))
                .foregroundColor(isPressed ? .secondary : .primary)
                .lineLimit(1)
                .fixedSize()
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Category Icon Button

private struct CategoryIcon: View {
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(isSelected ? 0.1 : 0.001))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preference Key for tracking visible category

private struct CategoryVisibilityPreference: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

