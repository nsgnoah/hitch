import SwiftUI

struct ResultsView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    private var record: PuzzleRecord { game.record }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .foregroundStyle(Color.ink)
                }

                LinkMark().frame(width: 70, height: 46)

                VStack(spacing: 6) {
                    Text(headline)
                        .font(.serif(34))
                    Text(subhead)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkSoft)
                }
                .multilineTextAlignment(.center)

                Text(record.emojiRow)
                    .font(.system(size: 30))
                    .tracking(4)

                chain

                ShareLink(item: game.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PillButtonStyle())
                .frame(maxWidth: 320)

                if game.puzzle.number == PuzzleBook.todayNumber {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        VStack(spacing: 2) {
                            Text("Next chain in")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.inkSoft)
                            Text(countdown(from: ctx.date))
                                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(Color.ink)
        }
        .background(Color.paper)
    }

    private var chain: some View {
        let words = game.words
        let middle = Array(1..<(words.count - 1))
        return VStack(spacing: 0) {
            ForEach(middle, id: \.self) { i in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(words[i])
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("\(words[i - 1]) \(words[i]) · \(words[i]) \(words[i + 1])".lowercased())
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSoft)
                    }
                    Spacer()
                    marker(for: i)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                if i != middle.last { Divider().overlay(Color.rule) }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.rule))
    }

    private func marker(for i: Int) -> some View {
        let extra = max(0, record.revealed[i] - 1)
        return Text(record.given[i] ? "given" : extra == 0 ? "clean" : "+\(extra)")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(record.given[i] ? Color.brick : extra == 0 ? Color.pine : Color.ember)
    }

    private var headline: String {
        switch record.totalExtra {
        case 0: "Perfect!"
        case 1...2: "Splendid!"
        case 3...5: "Nicely done"
        case 6...9: "Hitched!"
        default: "You made it"
        }
    }

    private var subhead: String {
        let n = record.totalExtra
        return n == 0 ? "Every link, first letter only." : "Solved with \(n) extra letter\(n == 1 ? "" : "s")."
    }

    private func countdown(from now: Date) -> String {
        let s = max(0, Int(PuzzleBook.nextPuzzleDate.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}
