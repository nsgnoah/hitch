import SwiftUI

enum Support {
    static let email = "noah@nsgsolutions.co"
    static let mail = URL(string: "mailto:\(email)")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: "How to Play") { dismiss() }

                Text("Build a chain of seven words.")
                    .serifFont(22, relativeTo: .title2)

                VStack(alignment: .leading, spacing: 10) {
                    bullet("Each word links to the next to make a compound word or familiar phrase.")
                    bullet("You're given the top and bottom words. Work inward from either end — tap a highlighted row to switch.")
                    bullet("Type your guess and press Go. If the keyboard is hidden, tap the chain to bring it back.")
                    bullet("The first letter of each word is free. Every wrong guess, or tap of Reveal, shows one more letter.")
                    bullet("Fewest extra letters wins bragging rights.")
                }

                Eyebrow("Example")
                    .padding(.top, 6)

                GeometryReader { geo in
                    ChainBoard(game: example, size: geo.size)
                }
                .frame(height: 300)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Example chain from SNOW to WHEEL. SNOW, BALL and ROOM are solved; SERVICE is in progress.")

                VStack(alignment: .leading, spacing: 10) {
                    legend(Text("SEA").foregroundStyle(Color.pine), "Solved")
                    legend(Text("E").foregroundStyle(Color.ember).underline(true, color: .ember), "Revealed letter, costs one")
                    legend(Text("BEAN").foregroundStyle(Color.stone), "Fully revealed")
                }
                .padding(.top, 4)

                Text("A chain a day, out at midnight. Missed one? Play it from the Archive.")
                    .scaledFont(15)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 4)

                about
                    .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(Color.ink)
        }
        .background(Color.paper)
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("About")
                .padding(.top, 20)

            Button { showPrivacy = true } label: {
                Text("Privacy Policy")
                    .underline()
                    .scaledFont(15, weight: .semibold)
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Color.ink)

            VStack(alignment: .leading, spacing: 4) {
                Text("Questions or feedback?")
                    .scaledFont(15)
                Link(destination: Support.mail) {
                    Text(Support.email)
                        .underline()
                        .scaledFont(15, weight: .semibold)
                        .frame(minHeight: 44)
                }
                .foregroundStyle(Color.ink)
            }

            Text("Version \(Support.version)")
                .scaledFont(13, relativeTo: .footnote)
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rule() }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("•")
                .accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .scaledFont(16)
    }

    private let example = Game(
        example: ["SNOW", "BALL", "ROOM", "SERVICE", "STATION", "WAGON", "WHEEL"],
        revealed: [4, 4, 4, 2, 0, 1, 5],
        solved: [true, true, true, false, false, false, true],
        selected: 3
    )

    private func legend(_ sample: Text, _ label: String) -> some View {
        HStack(spacing: 14) {
            sample
                .font(.serif(20))
                .frame(width: 64, alignment: .leading)
                .accessibilityHidden(true)
            Text(label).scaledFont(15)
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SheetHeader(title: "Privacy Policy") { dismiss() }

                Text("Effective September 27, 2026")
                    .scaledFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Color.inkSoft)

                section("The short version",
                        "Hitch doesn't collect or share any personal information. It has no accounts, ads, analytics or tracking, includes no third-party code, and never connects to the internet. No one else receives any data from Hitch.")
                section("What stays on your device",
                        "Hitch saves your puzzle progress, your statistics, and whether you've seen How to Play, using iOS app storage on this device. Your device backups (iCloud or your computer) include this data if you use them. It is never sent to us.")
                section("Sharing",
                        "When you tap Share, Hitch hands your result — the puzzle number, colored squares, and extra-letter count — to the iOS share sheet, and it goes only where you choose. We don't receive a copy.")
                section("Children",
                        "Hitch doesn't collect personal information from anyone, including children.")
                section("Deleting your data",
                        "Delete the app to erase everything it has stored on your device.")
                section("Changes",
                        "If this policy changes, the new version will appear here with a new effective date.")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Contact")
                        .scaledFont(17, weight: .bold, relativeTo: .headline)
                        .accessibilityAddTraits(.isHeader)
                    Text("Questions about this policy? Write to")
                        .scaledFont(16)
                    Link(destination: Support.mail) {
                        Text(Support.email)
                            .underline()
                            .scaledFont(16, weight: .semibold)
                            .frame(minHeight: 44)
                    }
                    .foregroundStyle(Color.ink)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(Color.ink)
        }
        .background(Color.paper)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .scaledFont(17, weight: .bold, relativeTo: .headline)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .scaledFont(16)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StatsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 22
    @ScaledMetric(relativeTo: .subheadline) private var labelWidth: CGFloat = 22

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
                        .scaledFont(15, weight: .bold, relativeTo: .subheadline)
                        .accessibilityAddTraits(.isHeader)
                    let dist = store.distribution
                    let top = max(1, dist.max() ?? 1)
                    ForEach(dist.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            Text(i == 5 ? "5+" : "\(i)")
                                .scaledFont(14, weight: .semibold, relativeTo: .subheadline)
                                .monospacedDigit()
                                .frame(width: labelWidth, alignment: .leading)
                            GeometryReader { geo in
                                let w = max(barHeight * 1.3, geo.size.width * CGFloat(dist[i]) / CGFloat(top))
                                Text("\(dist[i])")
                                    .scaledFont(13, weight: .bold, relativeTo: .caption)
                                    .foregroundStyle(dist[i] > 0 ? (i == 0 ? Color.white : Color.onStone) : Color.ink)
                                    .padding(.trailing, 8)
                                    .frame(width: w, height: barHeight, alignment: .trailing)
                                    .background(dist[i] > 0 ? (i == 0 ? Color.pine : Color.stone) : Color.rule)
                            }
                            .frame(height: barHeight)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(i == 5 ? "5 or more extra letters" : i == 1 ? "1 extra letter" : "\(i) extra letters"): \(dist[i]) \(dist[i] == 1 ? "puzzle" : "puzzles")")
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
            Text("\(value)").scaledFont(34, relativeTo: .largeTitle)
            Text(label)
                .scaledFont(12, relativeTo: .caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ArchiveView: View {
    @Binding var path: [Route]
    @Environment(ProgressStore.self) private var store
    /// Wide enough for three-digit puzzle numbers.
    @ScaledMetric(relativeTo: .title) private var numberWidth: CGFloat = 56
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach((1...PuzzleBook.todayNumber).reversed(), id: \.self) { n in
                    let puzzle = PuzzleBook.puzzle(n)
                    let record = store.record(for: puzzle)
                    Button { path.append(.play(n)) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text("\(n)")
                                .serifFont(30, weight: .regular, relativeTo: .title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .frame(width: numberWidth, alignment: .leading)
                                .accessibilityLabel("Number \(n)")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(puzzle.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .scaledFont(16, weight: .semibold)
                                Text("\(puzzle.words.first ?? "") to \(puzzle.words.last ?? "")")
                                    .serifFont(14, weight: .regular, relativeTo: .subheadline)
                                    .italic()
                                    .foregroundStyle(Color.inkSoft)
                                // At the largest text sizes there's no room beside the date.
                                if typeSize.isAccessibilitySize {
                                    status(record)
                                        .padding(.top, 4)
                                }
                            }
                            Spacer()
                            if !typeSize.isAccessibilitySize {
                                status(record)
                            }
                        }
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) { Rule() }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.ink)
        .background(Color.paper)
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Archive")
                    .serifFont(22, relativeTo: .headline)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

extension ArchiveView {
    @ViewBuilder
    private func status(_ record: PuzzleRecord) -> some View {
        if record.isFinished {
            ResultDots(record: record, size: 10)
        } else if record.isStarted {
            Text("In progress")
                .scaledFont(13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.ember)
        }
    }
}

struct SheetHeader: View {
    let title: String
    let close: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .serifFont(28, relativeTo: .title)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark")
                    .scaledFont(16, weight: .semibold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
        }
        .padding(.top, 12)
    }
}
