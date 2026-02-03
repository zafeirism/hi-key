import SwiftUI

// MARK: - Hi Theme
// Dark-first, accent-sparse design system with Dynamic Type support

enum HiTheme {
    // MARK: - Brand Colors (Legacy - for keyboard extension compatibility)

    /// Primary mint color from app icon background
    static let mint = Color(hex: "CEF0C4")

    // MARK: - Base/Surface Colors (Dark Mode)

    /// App background - darkest
    static let backgroundRoot = Color(hex: "0F1115")

    /// Cards, sheets, modals
    static let surfacePrimary = Color(hex: "171A20")

    /// Grouped items, nested cards
    static let surfaceSecondary = Color(hex: "1E222B")

    /// Separators, outlines
    static let divider = Color(hex: "2A2F3A")

    // MARK: - Text & Icon Colors

    /// Titles, main copy
    static let textPrimary = Color(hex: "E6E8EC")

    /// Descriptions, hints
    static let textSecondary = Color(hex: "9AA1AD")

    /// Disabled states
    static let textTertiary = Color(hex: "6E7482")

    /// Icon default color
    static let iconDefault = Color(hex: "C7CBD4")

    // MARK: - Accent Colors

    /// CTA, success - lime/yellow-green
    static let accentPrimary = Color(hex: "E4FF97")

    /// AI/creative moments - purple
    static let accentSecondary = Color(hex: "B48CFF")

    // MARK: - Status Colors

    static let statusError = Color(hex: "FF6B6B")
    static let statusWarning = Color(hex: "FFB86B")
    static let statusInfo = Color(hex: "6EA8FF")
    
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
    //static let animationFadeIn: Animation = .
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
    /// Primary action button style - full width, solid accent background
    func hiPrimaryButtonStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(HiTheme.backgroundRoot)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(HiTheme.accentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
    }

    /// Secondary button style - full width, outlined with accent border
    func hiSecondaryButtonStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundStyle(HiTheme.accentPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: HiTheme.radiusMD)
                    .stroke(HiTheme.accentPrimary, lineWidth: 1.5)
            )
    }

    /// Card style with dark surface background
    func hiCardStyle() -> some View {
        self
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
    }

    /// Standard content padding
    func hiPadding() -> some View {
        self.padding(.horizontal, HiTheme.spacingMD)
    }
}

// MARK: - Button Styles

/// Primary button style for main CTAs - solid accent background with dark text
struct HiPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(HiTheme.backgroundRoot)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isEnabled ? HiTheme.accentPrimary : HiTheme.accentPrimary.opacity(0.5))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style - outlined with accent border
struct HiSecondaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(isEnabled ? HiTheme.accentPrimary : HiTheme.accentPrimary.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isEnabled ? HiTheme.accentPrimary : HiTheme.accentPrimary.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Tertiary button style for text-only actions (Skip, Not now, etc.)
struct HiTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(HiTheme.accentPrimary)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
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
            .background(HiTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: HiTheme.radiusLG))
            .overlay(RoundedRectangle(cornerRadius: HiTheme.radiusLG).stroke(HiTheme.divider, lineWidth: 1))
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

#Preview("Theme Components - Dark") {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: HiTheme.spacingLG) {
                HiLogoView()
                    .foregroundStyle(HiTheme.textPrimary)

                Text("Large Title")
                    .font(.largeTitle)
                    .foregroundStyle(HiTheme.textPrimary)

                Text("Body Text")
                    .font(.body)
                    .foregroundStyle(HiTheme.textSecondary)

                Button("Primary Button") {}
                    .buttonStyle(HiPrimaryButtonStyle())

                Button("Secondary Button") {}
                    .buttonStyle(HiSecondaryButtonStyle())

                Button("Tertiary Button") {}
                    .buttonStyle(HiTertiaryButtonStyle())

                HiCard {
                    VStack(alignment: .leading, spacing: HiTheme.spacingSM) {
                        Text("Card Title")
                            .font(.headline)
                            .foregroundStyle(HiTheme.textPrimary)
                        Text("Card description goes here")
                            .font(.subheadline)
                            .foregroundStyle(HiTheme.textSecondary)
                    }
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Theme Components - Onboarding") {
    ZStack {
        HiTheme.backgroundRoot
            .ignoresSafeArea()

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
            }
            .padding()
        }
    }
}
