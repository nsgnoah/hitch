import SwiftUI

extension Color {
    /// `lightHigh` and `darkHigh` are used when Increase Contrast is on.
    init(light: UInt32, dark: UInt32, lightHigh: UInt32? = nil, darkHigh: UInt32? = nil) {
        self.init(uiColor: UIColor { traits in
            let high = traits.accessibilityContrast == .high
            let hex = traits.userInterfaceStyle == .dark
                ? (high ? darkHigh ?? dark : dark)
                : (high ? lightHigh ?? light : light)
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }

    static let paper = Color(light: 0xF7F3EA, dark: 0x191A18)
    static let card = Color(light: 0xFFFDF8, dark: 0x242522)
    static let ink = Color(light: 0x1F2421, dark: 0xEDE8DD)
    static let inkSoft = Color(light: 0x6B6A63, dark: 0xA19D93, lightHigh: 0x4A4944, darkHigh: 0xC9C5BB)
    static let rule = Color(light: 0xD9D1C1, dark: 0x3A3B36, lightHigh: 0xA39A89, darkHigh: 0x66675F)
    static let pine = Color(light: 0x2F6B4F, dark: 0x4C9670, lightHigh: 0x245A41)
    static let amber = Color(light: 0xE3AC3F, dark: 0xD8A23C, lightHigh: 0xA87A12, darkHigh: 0xEBBD5E)
    static let ember = Color(light: 0xD7742C, dark: 0xD9803C, lightHigh: 0xA8561C, darkHigh: 0xEB9A5C)
    static let brick = Color(light: 0xB5473A, dark: 0xC45B4E)
    static let stone = Color(light: 0x9E978C, dark: 0x6B665E, lightHigh: 0x6F695F, darkHigh: 0x9C968B)
    static let key = Color(light: 0xE4DDCF, dark: 0x3A3B36)
    /// Text on a `stone` fill. Flips to paper when Increase Contrast pushes stone toward ink.
    static let onStone = Color(light: 0x1F2421, dark: 0xEDE8DD, lightHigh: 0xF7F3EA, darkHigh: 0x191A18)

    // Home splash: fixed in both appearances, like a printed cover.
    static let splash = Color(light: 0x2F6B4F, dark: 0x244F3B)
    static let cream = Color(light: 0xF7F3EA, dark: 0xF2EDE2)
    static let nightInk = Color(light: 0x1F2421, dark: 0x1F2421)
}

extension Font {
    /// A fixed size. Only for type that is sized to fit the layout, like the game board.
    static func serif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension View {
    /// A design size that grows and shrinks with the reader's text size setting.
    func scaledFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default,
                    relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, style: style))
    }

    func serifFont(_ size: CGFloat, weight: Font.Weight = .bold, relativeTo style: Font.TextStyle = .body) -> some View {
        scaledFont(size, weight: weight, design: .serif, relativeTo: style)
    }
}

private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

struct PillButtonStyle: ButtonStyle {
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaledFont(17, weight: .semibold)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(filled ? Color.paper : Color.ink)
            .background(
                Capsule().fill(filled ? Color.ink : Color.clear)
            )
            .overlay(Capsule().stroke(Color.ink, lineWidth: filled ? 0 : 1.5))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SplashButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaledFont(17, weight: .semibold)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(filled ? Color.nightInk : Color.cream)
            .background(Capsule().fill(filled ? Color.cream : Color.clear))
            .overlay(Capsule().stroke(Color.cream, lineWidth: filled ? 0 : 1.5))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
