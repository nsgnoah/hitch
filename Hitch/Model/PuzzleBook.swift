import Foundation

struct Puzzle: Identifiable, Hashable {
    let number: Int
    let date: Date
    let words: [String]

    var id: Int { number }
}

/// The bundled set of chains, handed out one per calendar day.
enum PuzzleBook {
    /// Puzzle #1. Backdated so there's an archive to play from day one.
    static let launch: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1))!

    static let chains: [[String]] = {
        struct Entry: Decodable { let words: [String] }
        guard let url = Bundle.main.url(forResource: "chains", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data),
              !entries.isEmpty
        else { return [["SNOW", "BALL", "ROOM", "SERVICE", "STATION", "WAGON", "WHEEL"]] }
        return entries.map { $0.words.map { $0.uppercased() } }
    }()

    static func number(for date: Date) -> Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: launch), to: cal.startOfDay(for: date)).day ?? 0
        return max(1, days + 1)
    }

    static var todayNumber: Int { number(for: .now) }

    static func date(for number: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: number - 1, to: launch)!
    }

    static func puzzle(_ number: Int) -> Puzzle {
        let words = chains[(number - 1) % chains.count]
        return Puzzle(number: number, date: date(for: number), words: words)
    }

    static var today: Puzzle { puzzle(todayNumber) }

    static var nextPuzzleDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
    }
}
