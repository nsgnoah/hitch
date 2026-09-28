import SwiftUI

enum Route: Hashable {
    case play(Int)
    case archive
}

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [Route] = []
    @State private var showHelp = false
    @State private var showStats = false
    /// Today's puzzle number. Refreshed at midnight and whenever the app comes back to the foreground.
    @State private var day = PuzzleBook.todayNumber
    @AppStorage("hitch.seenHelp") private var seenHelp = false

    private var today: Puzzle { PuzzleBook.puzzle(day) }

    var body: some View {
        NavigationStack(path: $path) {
            // Scrolls only when the window is too short for it, like a small iPad window or large text.
            ViewThatFits(in: .vertical) {
                splash
                ScrollView { splash.padding(.vertical, 12) }
            }
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { day = PuzzleBook.todayNumber }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            day = PuzzleBook.todayNumber
        }
    }

    private var splash: some View {
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
            .scaledFont(19)
            .padding(.trailing, -12)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("No. \(today.number) · \(today.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))".uppercased())
                    .scaledFont(12, weight: .semibold, relativeTo: .caption)
                    .tracking(1.2)
                    .opacity(0.9)

                Text("Hitch")
                    .serifFont(72, relativeTo: .largeTitle)
                    .padding(.top, 2)
                    .accessibilityAddTraits(.isHeader)

                Text("Link seven words, top to bottom.")
                    .serifFont(19, weight: .regular, relativeTo: .title3)
                    .opacity(0.85)

                ChainTeaser(puzzle: today, record: store.record(for: today))
                    .padding(.top, 36)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(playLabel) { path.append(.play(today.number)) }
                .buttonStyle(SplashButtonStyle(filled: true))

            Button { path.append(.archive) } label: {
                Text("Archive")
                    .underline(true, color: Color.cream.opacity(0.5))
                    .scaledFont(16, weight: .semibold)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func shown(_ i: Int) -> Bool {
        i == 0 || i == puzzle.words.count - 1 || record.solved[i]
    }

    private var accessibilityText: String {
        let words = puzzle.words
        let hidden = words.count - 2
        let solved = (1..<words.count - 1).filter { record.solved[$0] }.count
        return "Today's chain, from \(words[0]) to \(words[words.count - 1]). \(solved) of \(hidden) words solved."
    }
}
