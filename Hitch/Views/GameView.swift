import SwiftUI

struct GameView: View {
    @State private var game: Game
    @State private var showResults = false
    @State private var showHelp = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    init(puzzle: Puzzle) {
        _game = State(initialValue: Game(puzzle: puzzle))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            GeometryReader { geo in
                ChainBoard(game: game, size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.horizontal, 16)

            if game.isFinished {
                finishedBar
            } else {
                controls
            }
        }
        .background(Color.paper)
        .toolbar(.hidden, for: .navigationBar)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: .down) { press in
            handleKey(press)
        }
        .onAppear {
            focused = true
            if game.isFinished { showResults = true }
        }
        .sensoryFeedback(.error, trigger: game.wrongCount)
        .sensoryFeedback(.success, trigger: game.solveCount)
        .onChange(of: game.isFinished) { _, done in
            if done {
                Task {
                    try? await Task.sleep(for: .seconds(1.1))
                    showResults = true
                }
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(game: game)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showHelp) { HowToPlayView() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            VStack(spacing: 0) {
                Text("Hitch")
                    .font(.serif(22))
                Text("No. \(game.puzzle.number) · \(game.puzzle.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
            }
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.rule).frame(height: 1) }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack {
                Label {
                    Text(game.record.totalExtra == 0 ? "No extra letters" : "\(game.record.totalExtra) extra letter\(game.record.totalExtra == 1 ? "" : "s")")
                        .contentTransition(.numericText())
                } icon: {
                    Image(systemName: "link")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkSoft)

                Spacer()

                Button {
                    withAnimation(.snappy) { game.hint() }
                } label: {
                    Label("Reveal a letter", systemImage: "lightbulb")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(Color.ink, lineWidth: 1.2))
                }
                .foregroundStyle(Color.ink)
            }
            .padding(.horizontal, 16)

            KeyboardView(
                canSubmit: game.canSubmit,
                onLetter: { c in withAnimation(.snappy(duration: 0.12)) { game.type(c) } },
                onDelete: { game.backspace() },
                onEnter: { withAnimation(.snappy) { game.submit() } }
            )
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var finishedBar: some View {
        Button("See Results") { showResults = true }
            .buttonStyle(PillButtonStyle())
            .frame(maxWidth: 320)
            .padding(.vertical, 20)
            .transition(.opacity)
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .return:
            withAnimation(.snappy) { game.submit() }
            return .handled
        case .delete:
            game.backspace()
            return .handled
        case .upArrow, .downArrow:
            let targets = [game.topFrontier, game.bottomFrontier].compactMap { $0 }
            if let t = targets.first(where: { $0 != game.selected }) { game.select(t) }
            return .handled
        default:
            if let c = press.characters.first, c.isLetter, c.isASCII {
                withAnimation(.snappy(duration: 0.12)) { game.type(c) }
                return .handled
            }
            return .ignored
        }
    }
}

// MARK: - Board

struct ChainBoard: View {
    let game: Game
    let size: CGSize

    private var metrics: (tile: CGFloat, gap: CGFloat, link: CGFloat) {
        let longest = CGFloat(game.words.map(\.count).max() ?? 7)
        let rows = CGFloat(game.words.count)
        let gap: CGFloat = 5
        let byWidth = (size.width - 52 - gap * (longest - 1)) / longest
        // Each row is a tile plus 12pt of highlight padding; connectors are ~40% of a tile.
        let byHeight = (size.height - 12 * rows - 8) / (rows + (rows - 1) * 0.4)
        let tile = min(byWidth, byHeight, 52)
        return (tile, gap, tile * 0.4)
    }

    var body: some View {
        let m = metrics
        VStack(spacing: 0) {
            ForEach(game.words.indices, id: \.self) { i in
                if i > 0 {
                    Connector(done: isDone(i - 1) && isDone(i))
                        .frame(height: m.link)
                }
                WordRow(game: game, index: i, tile: m.tile, gap: m.gap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func isDone(_ i: Int) -> Bool {
        let s = game.state(i)
        return s == .anchor || s == .solved || s == .given
    }
}

struct Connector: View {
    let done: Bool

    var body: some View {
        Capsule()
            .fill(done ? Color.pine : Color.rule)
            .frame(width: 4)
            .padding(.vertical, 3)
            .animation(.easeInOut(duration: 0.4), value: done)
    }
}

struct WordRow: View {
    let game: Game
    let index: Int
    let tile: CGFloat
    let gap: CGFloat

    @State private var shake: CGFloat = 0
    @State private var flip = false

    var body: some View {
        let state = game.state(index)
        let word = Array(game.words[index])
        let selected = game.selected == index

        Button {
            withAnimation(.snappy) { game.select(index) }
        } label: {
            tiles(word: word, state: state, selected: selected)
        }
        .buttonStyle(.plain)
        .modifier(Shake(amount: shake))
        .onChange(of: game.wrongCount) { _, _ in
            guard game.lastWrong == index else { return }
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }
        .onChange(of: game.solveCount) { _, _ in
            guard game.lastSolved == index else { return }
            flip.toggle()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(state: state))
        .accessibilityAddTraits(state == .active ? .isButton : [])
    }


    private func tiles(word: [Character], state: SlotState, selected: Bool) -> some View {
        HStack(spacing: gap) {
            ForEach(word.indices, id: \.self) { pos in
                TileView(
                    letter: game.letter(index, pos),
                    style: style(state: state, pos: pos, selected: selected),
                    size: tile
                )
                .rotation3DEffect(.degrees(flip ? 360 : 0), axis: (x: 1, y: 0, z: 0))
                .animation(.easeInOut(duration: 0.5).delay(Double(pos) * 0.07), value: flip)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selected ? Color.amber.opacity(0.18) : Color.clear)
        )
        .overlay(alignment: .leading) {
            if selected {
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.ink)
                    .offset(x: -14)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
    }

    private func style(state: SlotState, pos: Int, selected: Bool) -> TileView.Style {
        switch state {
        case .anchor: return .anchor
        case .solved: return .solved
        case .given: return .given
        case .locked: return .locked
        case .active:
            if pos < game.revealed(index) { return pos == 0 ? .revealed : .hinted }
            if game.isTyped(index, pos) { return .typed }
            return selected ? .emptyActive : .empty
        }
    }

    private func accessibilityText(state: SlotState) -> String {
        let word = game.words[index]
        switch state {
        case .anchor, .solved, .given: return word
        case .locked: return "Hidden word, \(word.count) letters"
        case .active:
            let shown = word.prefix(game.revealed(index))
            return "Word \(index + 1), \(word.count) letters, starts with \(shown.map(String.init).joined(separator: " "))"
        }
    }
}

struct TileView: View {
    enum Style {
        case anchor, solved, given, locked, empty, emptyActive, revealed, hinted, typed
    }

    let letter: Character?
    let style: Style
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16)
                .fill(fill)
            RoundedRectangle(cornerRadius: size * 0.16)
                .strokeBorder(border, lineWidth: borderWidth)
            if let letter {
                Text(String(letter))
                    .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(style == .typed ? 1.0 : 1)
    }

    private var fill: Color {
        switch style {
        case .anchor: .ink
        case .solved: .pine
        case .given: .stone
        case .hinted: .amber
        case .locked: .rule.opacity(0.35)
        default: .card
        }
    }

    private var border: Color {
        switch style {
        case .typed, .revealed: .ink
        case .emptyActive: .inkSoft
        case .empty: .rule
        default: .clear
        }
    }

    private var borderWidth: CGFloat {
        style == .typed || style == .revealed ? 2 : 1.5
    }

    private var textColor: Color {
        switch style {
        case .anchor: .paper
        case .solved, .given: .white
        case .hinted: .ink
        default: .ink
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(amount * .pi * 6), y: 0))
    }
}
