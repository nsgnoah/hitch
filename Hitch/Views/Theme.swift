import SwiftUI

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
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
    static let inkSoft = Color(light: 0x6B6A63, dark: 0xA19D93)
    static let rule = Color(light: 0xD9D1C1, dark: 0x3A3B36)
    static let pine = Color(light: 0x2F6B4F, dark: 0x4C9670)
    static let amber = Color(light: 0xE3AC3F, dark: 0xD8A23C)
    static let ember = Color(light: 0xD7742C, dark: 0xD9803C)
    static let brick = Color(light: 0xB5473A, dark: 0xC45B4E)
    static let stone = Color(light: 0x9E978C, dark: 0x6B665E)
    static let key = Color(light: 0xE4DDCF, dark: 0x3A3B36)
}

extension Font {
    static func serif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

struct PillButtonStyle: ButtonStyle {
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
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
