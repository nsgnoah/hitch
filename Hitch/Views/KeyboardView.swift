import SwiftUI

/// Letters set on a plain band, no key caps.
struct KeyboardView: View {
    let canSubmit: Bool
    let onLetter: (Character) -> Void
    let onDelete: () -> Void
    let onEnter: () -> Void

    private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    private let keyHeight: CGFloat = 50

    var body: some View {
        GeometryReader { geo in
            let keyWidth = geo.size.width / 10
            VStack(spacing: 2) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: 0) {
                        if r == 2 {
                            key(width: keyWidth * 1.5, action: onEnter) {
                                Text("Enter")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(canSubmit ? Color.ember : Color.inkSoft.opacity(0.6))
                            }
                        }
                        ForEach(Array(rows[r]), id: \.self) { c in
                            key(width: keyWidth, action: { onLetter(c) }) {
                                Text(String(c)).font(.system(size: 22, weight: .regular))
                            }
                        }
                        if r == 2 {
                            key(width: keyWidth * 1.5, action: onDelete) {
                                Image(systemName: "delete.left").font(.system(size: 19, weight: .light))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
        }
        .frame(height: keyHeight * 3 + 4 + 20)
        .foregroundStyle(Color.ink)
        .background(Color.key.opacity(0.55).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.rule).frame(height: 1) }
    }

    private func key<L: View>(width: CGFloat, action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label()
                .frame(width: width, height: keyHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyStyle())
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color.ink.opacity(configuration.isPressed ? 0.1 : 0))
                    .frame(width: 44, height: 44)
            )
    }
}
