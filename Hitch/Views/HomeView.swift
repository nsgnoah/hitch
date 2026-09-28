import SwiftUI

enum Route: Hashable {
    case play(Int)
    case archive
}

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @State private var path: [Route] = []
    @State private var showHelp = false
    @State private var showStats = false
    @AppStorage("hitch.seenHelp") private var seenHelp = false

    private var today: Puzzle { PuzzleBook.today }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Spacer()
                    Button { showStats = true } label: {
                        Image(systemName: "chart.bar")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Statistics")
                    Button { showHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("How to play")
                }
                .font(.system(size: 19))
                .padding(.trailing, -12)

                Spacer()

                VStack(alignment: .leading, spacing: 0) {
                    Text("No. \(today.number) · \(today.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))".uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.2)
                        .opacity(0.75)

                    Text("Hitch")
                        .font(.serif(72))
                        .padding(.top, 2)

                    Text("Link seven words, top to bottom.")
                        .font(.serif(19, weight: .regular))
                        .opacity(0.85)

                    ChainTeaser(puzzle: today, record: store.record(for: today))
                        .padding(.top, 36)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button(playLabel) { path.append(.play(today.number)) }
                    .buttonStyle(SplashButtonStyle(filled: true))

                Button("Archive") { path.append(.archive) }
                    .font(.system(size: 16, weight: .semibold))
                    .underline(true, color: Color.cream.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 480)
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.splash)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .play(let n): GameView(puzzle: PuzzleBook.puzzle(n))
                case .archive: ArchiveView(path: $path)
                }
            }
        }
        .sheet(isPresented: $showHelp) { HowToPlayView() }
        .sheet(isPresented: $showStats) { StatsView() }
        .onAppear {
            if !seenHelp {
                seenHelp = true
                showHelp = true
            }
        }
    }

    private var playLabel: String {
        let r = store.record(for: today)
        if r.isFinished { return "See Today's Chain" }
        return r.isStarted ? "Continue" : "Play"
    }
}

/// Two interlocking chain links.
struct LinkMark: View {
    var back: Color = .ink
    var front: Color = .pine

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.62
            let h = geo.size.height * 0.62
            let line = geo.size.height * 0.13
            ZStack {
                RoundedRectangle(cornerRadius: h / 2)
                    .stroke(back, lineWidth: line)
                    .frame(width: w, height: h)
                    .offset(x: -geo.size.width * 0.19, y: -geo.size.height * 0.1)
                RoundedRectangle(cornerRadius: h / 2)
                    .stroke(front, lineWidth: line)
                    .frame(width: w, height: h)
                    .offset(x: geo.size.width * 0.19, y: geo.size.height * 0.1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(.degrees(-20))
        }
    }
}

/// Today's chain in miniature: the two given words and the blanks between.
struct ChainTeaser: View {
    let puzzle: Puzzle
    let record: PuzzleRecord

    var body: some View {
        let words = puzzle.words
        VStack(alignment: .leading, spacing: 0) {
            ForEach(words.indices, id: \.self) { i in
                if i > 0 {
                    Rectangle().fill(Color.cream.opacity(0.5)).frame(width: 2, height: 10).padding(.leading, 5)
                }
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.cream.opacity(shown(i) ? 1 : 0.5))
                        .frame(width: shown(i) ? 12 : 7, height: shown(i) ? 12 : 7)
                        .frame(width: 12)
                    if shown(i) {
                        Text(words[i]).font(.serif(18))
                    } else {
                        HStack(spacing: 4) {
                            ForEach(0..<words[i].count, id: \.self) { _ in
                                Rectangle().fill(Color.cream.opacity(0.45)).frame(width: 11, height: 2)
                            }
                        }
                    }
                }
                .frame(height: 22)
            }
        }
    }

    private func shown(_ i: Int) -> Bool {
        i == 0 || i == puzzle.words.count - 1 || record.solved[i]
    }
}
