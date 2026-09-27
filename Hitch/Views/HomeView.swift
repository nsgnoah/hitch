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
                Spacer()

                LinkMark()
                    .frame(width: 92, height: 60)
                    .padding(.bottom, 20)

                Text("Hitch")
                    .font(.serif(52))
                    .foregroundStyle(Color.ink)

                Text("Link the words, top to bottom.")
                    .font(.serif(20, weight: .regular))
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 4)

                Spacer()

                VStack(spacing: 12) {
                    Button(playLabel) { path.append(.play(today.number)) }
                        .buttonStyle(PillButtonStyle())
                    Button("Archive") { path.append(.archive) }
                        .buttonStyle(PillButtonStyle(filled: false))
                    HStack(spacing: 12) {
                        Button("How to Play") { showHelp = true }
                            .buttonStyle(PillButtonStyle(filled: false))
                        Button("Stats") { showStats = true }
                            .buttonStyle(PillButtonStyle(filled: false))
                    }
                }
                .frame(maxWidth: 320)

                VStack(spacing: 2) {
                    Text(today.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.system(size: 15, weight: .semibold))
                    Text("No. \(today.number)")
                        .font(.system(size: 15))
                }
                .foregroundStyle(Color.ink)
                .padding(.top, 28)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.paper)
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
    var color: Color = .pine

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.62
            let h = geo.size.height * 0.62
            let line = geo.size.height * 0.13
            ZStack {
                RoundedRectangle(cornerRadius: h / 2)
                    .stroke(Color.ink, lineWidth: line)
                    .frame(width: w, height: h)
                    .offset(x: -geo.size.width * 0.19, y: -geo.size.height * 0.1)
                RoundedRectangle(cornerRadius: h / 2)
                    .stroke(color, lineWidth: line)
                    .frame(width: w, height: h)
                    .offset(x: geo.size.width * 0.19, y: geo.size.height * 0.1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .rotationEffect(.degrees(-20))
        }
    }
}
