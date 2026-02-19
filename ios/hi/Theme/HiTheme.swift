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
    
    /// Background atmospheric bloom
    static let atmosphereNeutralBlook = Color(hex: "1B1F27")
    
    /// Background cool bloom (same as statusInfo)
    static let atmosphereCoolBloom = Color(hex: "6EA8FF")
    
    /// Background haze blue
    static let atmosphereHazeBlue = Color(hex: "3A4D6A")

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
    static let statusGreen = Color(hex: "7AE3D1")
    static let statusSuccess = Color(hex: "4ADE80")
    
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
            .background(HiTheme.accentPrimary.opacity(0.001))
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
    var addHorizontalPadding: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(HiTheme.accentPrimary)
            .padding(.horizontal, addHorizontalPadding ? HiTheme.spacingLG : 0)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct HiIconButton: View {

    enum Size {
        case topBar
        case topBarTranslucent
        case card
        case sheet
    }

    let systemName: String
    let size: Size
    let action: () -> Void

    init(
        _ systemName: String,
        size: Size,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }

    private var visualSize: CGFloat {
        switch size {
        case .topBar: return 40
        case .topBarTranslucent: return 40
        case .card:   return 36
        case .sheet:  return 32
        }
    }

    private var iconFont: Font {
        switch size {
        case .topBar:
            return .system(size: 18, weight: .semibold)
        case .topBarTranslucent:
            return .system(size: 18, weight: .semibold)
        case .card:
            return .system(size: 15, weight: .semibold)
        case .sheet:
            return .system(size: 15, weight: .semibold)
        }
    }

    private var fillColor: Color {
        switch size {
        case .topBar:
            return HiTheme.surfacePrimary.opacity(0.75)
        case .topBarTranslucent:
            return HiTheme.surfacePrimary.opacity(0.35)
        case .card:
            return HiTheme.surfaceSecondary.opacity(0.90)
        case .sheet:
            return HiTheme.surfacePrimary.opacity(0.82)
        }
    }

    private var strokeColor: Color {
        HiTheme.divider.opacity(0.55)
    }

    private var tightShadow: (color: Color, radius: CGFloat, y: CGFloat) {
        switch size {
        case .topBar:
            return (Color.black.opacity(0.35), 8, 4)
        case .topBarTranslucent:
            return (Color.black.opacity(0.25), 6, 3)
        case .card:
            return (Color.black.opacity(0.30), 7, 3)
        case .sheet:
            return (Color.black.opacity(0.34), 8, 4)
        }
    }

    private var broadShadow: (color: Color, radius: CGFloat, y: CGFloat) {
        switch size {
        case .topBar:
            return (HiTheme.surfacePrimary.opacity(0.18), 18, 10)
        case .topBarTranslucent:
            return (HiTheme.surfacePrimary.opacity(0.18), 18, 10)
        case .card:
            return (HiTheme.surfacePrimary.opacity(0.14), 16, 8)
        case .sheet:
            return (HiTheme.surfacePrimary.opacity(0.16), 18, 10)
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(iconFont)
                .foregroundStyle(HiTheme.iconDefault)
                .frame(width: visualSize, height: visualSize)
                .background(
                    Circle()
                        .fill(fillColor)
                )
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: tightShadow.color,
                        radius: tightShadow.radius,
                        x: 0,
                        y: tightShadow.y)
                .shadow(color: broadShadow.color,
                        radius: broadShadow.radius,
                        x: 0,
                        y: broadShadow.y)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .buttonStyle(HiPressStyle())
    }
}

struct HiPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.80 : 1.0)
            .brightness(configuration.isPressed ? 0.02 : 0.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
                    .background(
                        RoundedRectangle(cornerRadius: HiTheme.radiusXL, style: .continuous)
                            .fill(HiTheme.surfacePrimary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HiTheme.radiusXL, style: .continuous)
                            .stroke(HiTheme.divider.opacity(0.7), lineWidth: 1)
                    )
                    // tight separation
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                    // broad ambient lift
                    .shadow(color: HiTheme.surfacePrimary.opacity(0.22), radius: 36, x: 0, y: 12)
    }
}

// MARK: - App Background

/// Full-screen background used across main app screens: base color + atmospheric radial gradients
struct HiAppBackground: View {
    var body: some View {
        ZStack {
            HiTheme.backgroundRoot
                .ignoresSafeArea()

            RadialGradient(
                colors: [HiTheme.atmosphereNeutralBlook.opacity(0.9), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .opacity(0.35)

            RadialGradient(
                colors: [HiTheme.atmosphereCoolBloom.opacity(0.35), Color.clear],
                center: UnitPoint(x: 0.8, y: -0.1),
                startRadius: 0,
                endRadius: 480
            )
            .ignoresSafeArea()
            .blendMode(.screen)
            .opacity(0.07)
        }
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
        HiAppBackground()

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
