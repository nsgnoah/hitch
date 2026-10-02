import SwiftUI

struct ResultsView: View {
    let game: Game
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var record: PuzzleRecord { game.record }
    private var words: [String] { game.words }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Eyebrow("Hitch No. \(game.puzzle.number) · \(game.puzzle.date.formatted(.dateTime.month(.wide).day()))")
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .scaledFont(15, weight: .semibold)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                    .offset(x: 12)
                }
                .padding(.top, 8)

                Text(headline)
                    .serifFont(38, relativeTo: .largeTitle)
                    .padding(.top, 12)
                    .accessibilityAddTraits(.isHeader)

                ResultDots(record: record, size: 20)
                    .padding(.top, 14)
                    // The headline already says it.
                    .accessibilityHidden(true)

                statsRow
                    .padding(.vertical, 16)
                    .overlay(alignment: .top) { Rule() }
                    .overlay(alignment: .bottom) { Rule() }
                    .padding(.top, 28)

                Eyebrow("The chain")
                    .padding(.top, 28)
                    .padding(.bottom, 14)

                ladder

                ShareLink(item: game.shareText) {
                    Text("Share")
                }
                .buttonStyle(PillButtonStyle())
                .padding(.top, 32)

                if game.puzzle.number == PuzzleBook.todayNumber {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        // Checked every tick, so a sheet left open past midnight catches up.
                        Text(game.puzzle.number == PuzzleBook.number(for: ctx.date)
                             ? "Next chain in \(countdown(from: ctx.date))"
                             : "A new chain is out.")
                            .scaledFont(14)
                            .monospacedDigit()
                            .foregroundStyle(Color.inkSoft)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(Color.ink)
        }
        .background(Color.paper)
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            stat(store.playedCount, "Played")
            stat(store.winPercent, "Win %")
            stat(store.currentStreak, "Streak")
            stat(store.longestStreak, "Best")
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").serifFont(28, weight: .regular, relativeTo: .title)
            Text(label).scaledFont(12, relativeTo: .caption).foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The finished chain, word by word, with each link spelled out between.
    private var ladder: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(words.indices, id: \.self) { i in
                HStack(spacing: 14) {
                    ZStack {
                        VStack(spacing: 0) {
                            SpineLine(done: true).opacity(i == 0 ? 0 : 1)
                            SpineLine(done: true).opacity(i == words.count - 1 ? 0 : 1)
                        }
                        Circle().fill(color(for: i)).frame(width: 12, height: 12)
                    }
                    .frame(width: 14)
                    Text(words[i])
                        .serifFont(20, relativeTo: .title3)

                    Spacer()
                    Text(note(for: i))
                        .scaledFont(13, relativeTo: .footnote)
                        .foregroundStyle(Color.inkSoft)
                }
                .frame(minHeight: 30)
                .accessibilityElement(children: .combine)
                if i < words.count - 1 {
                    HStack(spacing: 14) {
                        SpineLine(done: true).frame(width: 14)
                        Text("\(words[i]) \(words[i + 1])".lowercased())
                            .serifFont(14, weight: .regular, relativeTo: .subheadline)
                            .italic()
                            .foregroundStyle(Color.inkSoft)
                    }
                    .frame(minHeight: 24)
                }
            }
        }
    }

    private func color(for i: Int) -> Color {
        guard i > 0, i < words.count - 1 else { return .ink }
        if record.given[i] || !record.solved[i] { return .stone }
        switch record.revealed[i] - 1 {
        case ...0: return .pine
        case 1: return .amber
        default: return .ember
        }
    }

    private func note(for i: Int) -> String {
        guard i > 0, i < words.count - 1 else { return "" }
        if !record.solved[i] { return "missed" }
        if record.given[i] { return "revealed" }
        let extra = record.revealed[i] - 1
        return extra > 0 ? "+\(extra)" : ""
    }

    private var headline: String {
        if record.isLost { return "The chain broke." }
        let n = record.totalExtra
        return n == 0 ? "A perfect chain." : "\(n) extra letter\(n == 1 ? "" : "s")."
    }

    private func countdown(from now: Date) -> String {
        let s = max(0, Int(PuzzleBook.nextPuzzleDate.timeIntervalSince(now)))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

/// One dot per hidden word.
struct ResultDots: View {
    let record: PuzzleRecord
    var size: CGFloat = 12
    @Environment(\.accessibilityDifferentiateWithoutColor) private var withoutColor

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(Array(record.revealed.indices.dropFirst().dropLast()), id: \.self) { i in
                dot(i)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// With Differentiate Without Color on, the shape carries the result too:
    /// solid for perfect, a thick ring for one extra, a thin ring for more, a struck ring for revealed.
    @ViewBuilder
    private func dot(_ i: Int) -> some View {
        let c = color(i)
        if !withoutColor {
            Circle().fill(c)
        } else if record.given[i] || !record.solved[i] {
            Circle().strokeBorder(c, lineWidth: size * 0.14)
                .overlay(Rectangle().fill(c).frame(width: size * 0.14).rotationEffect(.degrees(45)))
        } else {
            switch record.revealed[i] - 1 {
            case ...0: Circle().fill(c)
            case 1: Circle().strokeBorder(c, lineWidth: size * 0.32)
            default: Circle().strokeBorder(c, lineWidth: size * 0.14)
            }
        }
    }

    private var accessibilityText: String {
        if record.isLost {
            let middle = record.solved.indices.dropFirst().dropLast()
            let guessed = middle.filter { record.solved[$0] && !record.given[$0] }.count
            return "Chain broke, \(guessed) of \(middle.count) words solved"
        }
        let n = record.totalExtra
        let given = record.given.filter { $0 }.count
        var text = n == 0 ? "Finished, a perfect chain" : "Finished, \(n) extra letter\(n == 1 ? "" : "s")"
        if given > 0 { text += ", \(given) word\(given == 1 ? "" : "s") revealed" }
        return text
    }

    private func color(_ i: Int) -> Color {
        if record.given[i] || !record.solved[i] { return .stone }
        switch record.revealed[i] - 1 {
        case ...0: return .pine
        case 1: return .amber
        default: return .ember
        }
    }
}

struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .scaledFont(12, weight: .semibold, relativeTo: .caption)
            .tracking(1.2)
            .foregroundStyle(Color.inkSoft)
    }
}

struct Rule: View {
    var body: some View {
        Rectangle().fill(Color.rule).frame(height: 1)
    }
}
