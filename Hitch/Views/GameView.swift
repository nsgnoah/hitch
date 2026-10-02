import SwiftUI

struct GameView: View {
    @State private var game: Game
    @State private var showResults = false
    @State private var showHelp = false
    /// Bumped to bring the keyboard back after the player dismisses it.
    @State private var focusToken = 0

    init(puzzle: Puzzle) {
        _game = State(initialValue: Game(puzzle: puzzle))
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ChainBoard(game: game, size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 16)
            .simultaneousGesture(TapGesture().onEnded { focusToken += 1 })

            if game.isFinished {
                finishedBar
            } else {
                controls
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.paper)
        .background(
            KeyCatcher(
                active: !game.isFinished && !showResults && !showHelp,
                focusToken: focusToken,
                onLetter: { c in withAnimation(.snappy(duration: 0.12)) { game.type(c) } },
                onDelete: { game.backspace() },
                onEnter: { withAnimation(.snappy) { game.submit() } },
                onSwitch: { withAnimation(.snappy) { game.switchWord() } }
            )
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
        )
        // The board sizes its own type; keep the chrome around it from crowding it out.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .navigationTitle("Hitch No. \(game.puzzle.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Hitch")
                        .serifFont(22, relativeTo: .headline)
                    Text("No. \(game.puzzle.number) · \(game.puzzle.date.formatted(.dateTime.month(.abbreviated).day()))")
                        .scaledFont(12, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(Color.inkSoft)
                }
                .foregroundStyle(Color.ink)
                .accessibilityElement(children: .combine)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showHelp = true } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("How to play")
            }
        }
        .onAppear {
            if game.isFinished { showResults = true }
        }
        .sensoryFeedback(.error, trigger: game.wrongCount)
        .sensoryFeedback(.success, trigger: game.solveCount)
        .onChange(of: game.wrongCount) { _, _ in
            if game.record.isLost {
                AccessibilityNotification.Announcement("Not quite. Out of extra letters, so the chain broke.").post()
                return
            }
            // A wrong guess that shows the last letter finishes the word; the solve announcement covers it.
            guard let i = game.lastWrong, !game.record.solved[i] else { return }
            AccessibilityNotification.Announcement("Not quite. One more letter shown.").post()
        }
        .onChange(of: game.solveCount) { _, _ in
            guard let i = game.lastSolved else { return }
            let word = game.words[i]
            AccessibilityNotification.Announcement(game.record.given[i] ? "\(word), revealed" : "\(word), solved").post()
        }
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

    private var controls: some View {
        let used = game.record.totalExtra
        let spare = PuzzleRecord.spareLetters
        return HStack {
            HStack(spacing: 8) {
                Eyebrow(game.record.hasSpareLetters ? "Extra letters" : "Last chance")
                // One pip per spare letter, filled as they're used.
                HStack(spacing: 5) {
                    ForEach(0..<spare, id: \.self) { n in
                        Circle()
                            .fill(n < used ? Color.ember : Color.clear)
                            .overlay(Circle().strokeBorder(n < used ? Color.ember : Color.inkSoft, lineWidth: 1.5))
                            .frame(width: 10, height: 10)
                    }
                }
                .animation(.snappy, value: used)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(game.record.hasSpareLetters
                ? "Extra letters: \(used) of \(spare) used"
                : "No extra letters left. One more miss breaks the chain.")

            Spacer()

            Button {
                withAnimation(.snappy) { game.hint() }
            } label: {
                Text("Reveal a letter")
                    .underline(true, color: Color.ember)
                    .scaledFont(15, weight: .semibold)
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Color.ink)
            .opacity(game.record.hasSpareLetters ? 1 : 0.35)
            .disabled(!game.record.hasSpareLetters)
            .keyboardShortcut("r", modifiers: .command)
        }
        .frame(maxWidth: 600)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var finishedBar: some View {
        Button("See Results") { showResults = true }
            .buttonStyle(PillButtonStyle())
            .frame(maxWidth: 320)
            .padding(.vertical, 20)
            .transition(.opacity)
    }
}

// MARK: - Board

/// The chain: one vertical line, a knot per word, words hanging off it.
struct ChainBoard: View {
    let game: Game
    let size: CGSize

    var body: some View {
        let longest = CGFloat(game.words.map(\.count).max() ?? 7)
        let rows = CGFloat(game.words.count)
        // `slot` is the type size. Rows are 1.25 of it, links 0.55, letters 0.88 wide.
        let byHeight = size.height / (rows * 1.25 + (rows - 1) * 0.55)
        let byWidth = (size.width - ChainMetrics.spine - 16) / (longest * 0.88)
        let slot = min(byHeight, byWidth, 46)

        VStack(alignment: .leading, spacing: 0) {
            ForEach(game.words.indices, id: \.self) { i in
                if i > 0 {
                    LinkRow(
                        phrase: "\(game.words[i - 1]) \(game.words[i])",
                        done: isDone(i - 1) && isDone(i),
                        fontSize: max(12, slot * 0.34)
                    )
                    .frame(height: slot * 0.55)
                }
                WordRow(game: game, index: i, slot: slot, topDone: i > 0 && isDone(i - 1) && isDone(i),
                        bottomDone: i < game.words.count - 1 && isDone(i) && isDone(i + 1))
                    .frame(height: slot * 1.25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func isDone(_ i: Int) -> Bool {
        let s = game.state(i)
        return s == .anchor || s == .solved || s == .given
    }
}

enum ChainMetrics {
    /// Width of the column the line runs down.
    static let spine: CGFloat = 36
}

struct SpineLine: View {
    let done: Bool

    var body: some View {
        Rectangle()
            .fill(done ? Color.ink : Color.rule)
            .frame(width: 2)
            .animation(.easeInOut(duration: 0.4), value: done)
    }
}

struct LinkRow: View {
    let phrase: String
    let done: Bool
    let fontSize: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            SpineLine(done: done)
                .frame(width: ChainMetrics.spine)
            if done {
                Text(phrase.lowercased())
                    .font(.serif(fontSize, weight: .regular).italic())
                    .foregroundStyle(Color.inkSoft)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(x: -6)))
            }
            Spacer(minLength: 0)
        }
        .animation(.easeOut(duration: 0.35).delay(0.25), value: done)
    }
}

struct Knot: View {
    let state: SlotState
    let selected: Bool
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColor

    var body: some View {
        switch state {
        case .anchor:
            Circle().fill(Color.ink).frame(width: 12, height: 12)
        case .solved:
            Circle().fill(Color.pine).frame(width: 12, height: 12)
        case .given:
            if withoutColor {
                Circle().strokeBorder(Color.stone, lineWidth: 2.5).frame(width: 12, height: 12)
            } else {
                Circle().fill(Color.stone).frame(width: 12, height: 12)
            }
        case .active:
            Circle()
                .fill(selected ? Color.ember : Color.paper)
                .overlay(Circle().stroke(selected ? Color.ember : Color.ink, lineWidth: 2))
                .frame(width: 14, height: 14)
        case .locked:
            Circle().fill(Color.rule).frame(width: 7, height: 7)
        }
    }
}

struct WordRow: View {
    let game: Game
    let index: Int
    let slot: CGFloat
    let topDone: Bool
    let bottomDone: Bool

    @State private var shake: CGFloat = 0
    @State private var hop = 0
    /// Stands in for the shake when Reduce Motion is on.
    @State private var flash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let state = game.state(index)
        let word = Array(game.words[index])
        let selected = game.selected == index
        let last = game.words.count - 1

        Button {
            withAnimation(.snappy) { game.select(index) }
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    VStack(spacing: 0) {
                        SpineLine(done: topDone).opacity(index == 0 ? 0 : 1)
                        SpineLine(done: bottomDone).opacity(index == last ? 0 : 1)
                    }
                    Knot(state: state, selected: selected)
                }
                .frame(width: ChainMetrics.spine)

                HStack(spacing: slot * 0.1) {
                    ForEach(word.indices, id: \.self) { pos in
                        letterSlot(pos: pos, state: state, selected: selected)
                            .keyframeAnimator(initialValue: 0.0, trigger: hop) { content, y in
                                content.offset(y: y)
                            } keyframes: { _ in
                                KeyframeTrack {
                                    LinearKeyframe(0, duration: 0.01 + Double(pos) * 0.05)
                                    SpringKeyframe(-slot * 0.22, duration: 0.14)
                                    SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                                }
                            }
                    }
                }
                .modifier(Shake(amount: shake))
                .padding(.leading, 6)

                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity)
            .background(selected ? Color.amber.opacity(0.16) : Color.clear)
            .background(Color.ember.opacity(flash ? 0.22 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onChange(of: game.wrongCount) { _, _ in
            guard game.lastWrong == index else { return }
            if reduceMotion {
                withAnimation(.easeIn(duration: 0.1)) { flash = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.easeOut(duration: 0.5)) { flash = false }
                }
            } else {
                withAnimation(.linear(duration: 0.4)) { shake += 1 }
            }
        }
        .onChange(of: game.solveCount) { _, _ in
            guard game.lastSolved == index, !reduceMotion else { return }
            hop += 1
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(state: state))
        .accessibilityAddTraits(state == .active ? .isButton : [])
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func letterSlot(pos: Int, state: SlotState, selected: Bool) -> some View {
        let letter = game.letter(index, pos)
        let open = state == .active || state == .locked
        let isCursor = selected && pos == game.revealed(index) + typedCount
        return ZStack(alignment: .bottom) {
            if let letter {
                Text(String(letter))
                    .font(.serif(slot))
                    .foregroundStyle(color(pos: pos, state: state))
                    .fixedSize()
                    .padding(.bottom, slot * 0.1)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.7)))
            }
            if open {
                Rectangle()
                    .fill(underline(pos: pos, state: state, selected: selected, cursor: isCursor))
                    .frame(height: isCursor ? 3 : 2)
                    .padding(.bottom, slot * 0.08)
            }
        }
        .frame(width: slot * 0.78, height: slot * 1.25, alignment: .bottom)
    }

    private var typedCount: Int {
        (0..<game.words[index].count).filter { game.isTyped(index, $0) }.count
    }

    private func color(pos: Int, state: SlotState) -> Color {
        switch state {
        case .anchor: .ink
        // Letters that were revealed stay yellow once the word is solved.
        case .solved: pos > 0 && pos < game.revealed(index) ? .amber : .pine
        case .given: .stone
        case .locked: .clear
        case .active: pos > 0 && pos < game.revealed(index) ? .ember : .ink
        }
    }

    private func underline(pos: Int, state: SlotState, selected: Bool, cursor: Bool) -> Color {
        if state == .locked { return .rule }
        if cursor { return .ember }
        if pos > 0 && pos < game.revealed(index) { return .ember }
        return selected ? .ink : .inkSoft.opacity(0.5)
    }

    private func accessibilityText(state: SlotState) -> String {
        let word = game.words[index]
        switch state {
        case .anchor: return word
        case .solved: return "\(word), solved"
        case .given: return "\(word), revealed"
        case .locked: return "Hidden word, \(word.count) letters"
        case .active:
            let letters = (0..<word.count).map { game.letter(index, $0).map(String.init) ?? "blank" }
            return "Word \(index + 1), \(word.count) letters: \(letters.joined(separator: ", "))"
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
