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
                .padding(.horizontal, 12)

                Spacer()

                LinkMark(back: .cream, front: .amber)
                    .frame(width: 84, height: 56)
                    .padding(.bottom, 22)

                Text("Hitch")
                    .font(.serif(58))

                Text("Link seven words,\ntop to bottom.")
                    .font(.serif(21, weight: .regular))
                    .multilineTextAlignment(.center)
                    .opacity(0.85)
                    .padding(.top, 6)

                Spacer()

                VStack(spacing: 12) {
                    Button(playLabel) { path.append(.play(today.number)) }
                        .buttonStyle(SplashButtonStyle(filled: true))
                    Button("Archive") { path.append(.archive) }
                        .buttonStyle(SplashButtonStyle(filled: false))
                }
                .frame(maxWidth: 240)

                VStack(spacing: 2) {
                    Text(today.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 15, weight: .semibold))
                    Text("No. \(today.number)")
                        .font(.system(size: 15))
                        .opacity(0.8)
                }
                .padding(.top, 28)

                Spacer()
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
