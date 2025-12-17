import Foundation

// MARK: - Category Model

struct PromptCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let suggestions: [String]
}

// MARK: - Shared Categories Data

struct PromptCategories {
    static let all: [PromptCategory] = [
        PromptCategory(
            name: "Styles",
            icon: "paintbrush",
            suggestions: ["Watercolor", "Oil painting", "Pastel", "Charcoal", "Comic book", "Manga", "Graphic novel", "Pixar-like", "Ghibli-like", "Disney Renaissance", "90s anime", "Impressionist", "Surrealist", "Expressionist", "Pop art", "Vaporwave", "Synthwave", "Cyberpunk", "Steampunk", "Photorealistic", "Cinematic", "Documentary", "Analog film", "Retro poster", "Minimalism", "Low poly", "Pixel art", "Sketch", "Realism", "Hyperrealism", "Baroque", "Rococo", "Art Nouveau", "Art Deco", "Cubism", "Fauvism", "Ukiyo-e", "Noir", "Film noir", "Neon noir", "Fantasy illustration", "Matte painting", "Isometric", "Line art", "Chiaroscuro", "Graffiti", "Street art"]
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
    
    /// Returns the Styles category (first one)
    static var styles: PromptCategory? {
        all.first { $0.name == "Styles" }
    }
    
    /// Returns n random suggestions from the Styles category
    static func randomStyles(_ count: Int) -> [String] {
        guard let styles = styles else { return [] }
        return Array(styles.suggestions.shuffled().prefix(count))
    }
}
