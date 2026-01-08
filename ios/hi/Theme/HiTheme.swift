import SwiftUI

// MARK: - Hi Theme

enum HiTheme {
    // MARK: - Colors
    
    static let mint = Color(hex: "CEF0C4")
    static let mintDark = Color(hex: "A8D99C")
    
    // MARK: - Fonts
    
    static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func subtitle(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    
    static func caption(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48
    
    // MARK: - Corner Radius
    
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 24
    static let radiusFull: CGFloat = 100
    
    // MARK: - Animation
    
    static let animationFast: Animation = .easeInOut(duration: 0.2)
    static let animationNormal: Animation = .easeInOut(duration: 0.3)
    static let animationSlow: Animation = .easeInOut(duration: 0.5)
    
    // MARK: - Shadows
    
    static func cardShadow() -> some View {
        Color.black.opacity(0.08)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func hiButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(HiTheme.subtitle())
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? HiTheme.mint : HiTheme.mint.opacity(0.5))
            .cornerRadius(HiTheme.radiusFull)
    }
    
    func hiSecondaryButtonStyle() -> some View {
        self
            .font(HiTheme.body())
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.systemGray6))
            .cornerRadius(HiTheme.radiusFull)
    }
    
    func hiCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(HiTheme.radiusLG)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

