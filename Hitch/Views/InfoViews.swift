import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: "How to Play") { dismiss() }

                Text("Build a chain of seven words.")
                    .font(.serif(22))

                VStack(alignment: .leading, spacing: 10) {
                    bullet("Each word links to the next to make a compound word or familiar phrase.")
                    bullet("You're given the top and bottom words. Work inward from either end — tap a highlighted row to switch.")
                    bullet("The first letter of each word is free. Every wrong guess, or tap of Reveal, shows one more letter.")
                    bullet("Fewest extra letters wins bragging rights at the cabin.")
                }

                Text("Example")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    exampleRow("SNOW", .anchor)
                    exampleRow("BALL", .solved, note: "snowball")
                    exampleRow("ROOM", .solved, note: "ballroom")
                    exampleRow("SE", .active, total: 7, note: "room service?")
                    exampleRow("", .locked, total: 7)
                    exampleRow("", .locked, total: 5)
                    exampleRow("WHEEL", .anchor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    legend(.pine, "Solved")
                    legend(.amber, "Extra letter revealed")
                    legend(.stone, "Fully revealed")
                }
                .padding(.top, 4)

                Text("A new chain every day at midnight. Missed one? Play it from the Archive.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(Color.ink)
        }
        .background(Color.paper)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("•")
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 16))
    }

    private func exampleRow(_ word: String, _ state: SlotState, total: Int? = nil, note: String? = nil) -> some View {
        let letters = Array(word)
        let count = total ?? letters.count
        return HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                let style: TileView.Style = switch state {
                case .anchor: .anchor
                case .solved: .solved
                case .given: .given
                case .locked: .locked
                case .active: i == 0 ? .revealed : i < letters.count ? .hinted : .empty
                }
                TileView(letter: i < letters.count ? letters[i] : nil, style: style, size: 28)
            }
        }
        .overlay(alignment: .leading) {
            if let note {
                Text(note)
                    .font(.system(size: 13, weight: .medium).italic())
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize()
                    .offset(x: CGFloat(count) * 32 + 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 20, height: 20)
            Text(label).font(.system(size: 15))
        }
    }
}

struct StatsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SheetHeader(title: "Statistics") { dismiss() }

                HStack(alignment: .top) {
                    stat(store.playedCount, "Played")
                    stat(store.perfectCount, "Perfect")
                    stat(store.currentStreak, "Current\nStreak")
                    stat(store.longestStreak, "Max\nStreak")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Extra Letters")
                        .font(.system(size: 15, weight: .bold))
                    let dist = store.distribution
                    let top = max(1, dist.max() ?? 1)
                    ForEach(dist.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            Text(i == 5 ? "5+" : "\(i)")
                                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                                .frame(width: 22, alignment: .leading)
                            GeometryReader { geo in
                                let w = max(28, geo.size.width * CGFloat(dist[i]) / CGFloat(top))
                                Text("\(dist[i])")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.trailing, 8)
                                    .frame(width: w, height: 22, alignment: .trailing)
                                    .background(dist[i] > 0 ? (i == 0 ? Color.pine : Color.stone) : Color.rule)
                            }
                            .frame(height: 22)
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

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 34, weight: .regular))
            Text(label)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ArchiveView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text("Archive").font(.serif(22))
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.rule).frame(height: 1) }

            List {
                ForEach((1...PuzzleBook.todayNumber).reversed(), id: \.self) { n in
                    let puzzle = PuzzleBook.puzzle(n)
                    let record = store.record(for: puzzle)
                    Button { path.append(.play(n)) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(puzzle.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                    .font(.system(size: 16, weight: .semibold))
                                Text("No. \(n)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.inkSoft)
                            }
                            Spacer()
                            if record.isFinished {
                                ResultSquares(record: record, size: 12)
                            } else if record.isStarted {
                                Text("In progress")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.ember)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.inkSoft)
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(Color.ink)
                    .listRowBackground(Color.card)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .foregroundStyle(Color.ink)
        .background(Color.paper)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct SheetHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.serif(28))
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.top, 12)
    }
}
