import SwiftUI

struct KeyboardView: View {
    let canSubmit: Bool
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onEnter: () -> Void

    private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 6
            let keyWidth = (geo.size.width - gap * 9) / 10
            VStack(spacing: 8) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: gap) {
                        if r == 2 {
                            wideKey(width: keyWidth * 1.5 + gap / 2, action: onEnter) {
                                Text("ENTER").font(.system(size: 12, weight: .bold))
                            }
                            .opacity(canSubmit ? 1 : 0.45)
                        }
                        ForEach(Array(rows[r]), id: \.self) { c in
                            Button { onLetter(c) } label: {
                                Text(String(c))
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: keyWidth, height: 54)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.key))
                            }
                            .buttonStyle(KeyStyle())
                        }
                        if r == 2 {
                            wideKey(width: keyWidth * 1.5 + gap / 2, action: onDelete) {
                                Image(systemName: "delete.left").font(.system(size: 18, weight: .medium))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 54 * 3 + 16)
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 6)
    }

    private func wideKey<L: View>(width: CGFloat, action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label()
                .frame(width: width, height: 54)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.key))
        }
        .buttonStyle(KeyStyle())
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.08 : 0)
    }
}
