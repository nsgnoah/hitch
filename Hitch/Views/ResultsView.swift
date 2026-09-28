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
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .offset(x: 12)
                }
                .padding(.top, 8)

                Text(headline)
                    .font(.serif(38))
                    .padding(.top, 12)

                ResultDots(record: record, size: 20)
                    .padding(.top, 14)

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
                        Text("Next chain in \(countdown(from: ctx.date))")
                            .font(.system(size: 14).monospacedDigit())
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
            stat(store.perfectCount, "Perfect")
            stat(store.currentStreak, "Streak")
            stat(store.longestStreak, "Best")
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.serif(28, weight: .regular))
            Text(label).font(.system(size: 12)).foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .font(.serif(20))

                    Spacer()
                    Text(note(for: i))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSoft)
                }
                .frame(height: 30)
                if i < words.count - 1 {
                    HStack(spacing: 14) {
                        SpineLine(done: true).frame(width: 14)
                        Text("\(words[i]) \(words[i + 1])".lowercased())
                            .font(.serif(14, weight: .regular).italic())
                            .foregroundStyle(Color.inkSoft)
                    }
                    .frame(height: 24)
                }
            }
        }
    }

    private func color(for i: Int) -> Color {
        guard i > 0, i < words.count - 1 else { return .ink }
        if record.given[i] { return .stone }
        switch record.revealed[i] - 1 {
        case ...0: return .pine
        case 1: return .amber
        default: return .ember
        }
    }

    private func note(for i: Int) -> String {
        guard i > 0, i < words.count - 1 else { return "" }
        if record.given[i] { return "revealed" }
        let extra = record.revealed[i] - 1
        return extra > 0 ? "+\(extra)" : ""
    }

    private var headline: String {
        let n = record.totalExtra
        return n == 0 ? "A perfect chain." : "\(n) extra letter\(n == 1 ? "" : "s")."
    }

    private func countdown(from now: Date) -> String {
        let s = max(0, Int(PuzzleBook.nextPuzzleDate.timeIntervalSince(now)))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

/// One dot per hidden word. Matches the share text.
struct ResultDots: View {
    let record: PuzzleRecord
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(Array(record.revealed.indices.dropFirst().dropLast()), id: \.self) { i in
                Circle()
                    .fill(color(i))
                    .frame(width: size, height: size)
            }
        }
    }

    private func color(_ i: Int) -> Color {
        if record.given[i] { return .stone }
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
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Color.inkSoft)
    }
}

struct Rule: View {
    var body: some View {
        Rectangle().fill(Color.rule).frame(height: 1)
    }
}
