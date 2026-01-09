import SwiftUI

// MARK: - Hi Theme
// iOS 26 Liquid Glass design language with Dynamic Type support

enum HiTheme {
    // MARK: - Brand Colors
    
    /// Primary mint color from app icon background
    static let mint = Color(hex: "CEF0C4")
    
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
    static let animationSpring: Animation = .spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Scaled Metric for Logo

/// Use this for the "hi" logo text to scale with Dynamic Type
struct ScaledLogo {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 72
    
    var font: Font {
        .system(size: size, weight: .bold, design: .rounded)
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
    /// Primary action button style - full width, prominent
    func hiPrimaryButtonStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
    }
    
    /// Secondary button style - full width, subtle
    func hiSecondaryButtonStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
    }
    
    /// Card style with Liquid Glass material background
    func hiCardStyle() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
    }
    
    /// Standard content padding
    func hiPadding() -> some View {
        self.padding(.horizontal, HiTheme.spacingMD)
    }
}

// MARK: - Button Styles

/// Primary button style for main CTAs
struct HiPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? Color.accentColor : Color.accentColor.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style for less prominent actions
struct HiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Component

/// Reusable card view for home screen sections
struct HiCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(HiTheme.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
    }
}

// MARK: - Logo View

/// Scalable "hi" logo that respects Dynamic Type
struct HiLogoView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize: CGFloat = 72
    
    var body: some View {
        Text("hi")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
    }
}

// MARK: - Preview

#Preview("Theme Components") {
    ScrollView {
        VStack(spacing: HiTheme.spacingLG) {
            HiLogoView()
            
            Text("Large Title")
                .font(.largeTitle)
            
            Text("Body Text")
                .font(.body)
            
            Button("Primary Button") {}
                .buttonStyle(HiPrimaryButtonStyle())
            
            Button("Secondary Button") {}
                .buttonStyle(HiSecondaryButtonStyle())
            
            HiCard {
                VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                    Text("Card Title")
                        .font(.headline)
                    Text("Card description goes here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}