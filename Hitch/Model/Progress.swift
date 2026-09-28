import Foundation
import Observation

/// Saved state for one puzzle.
struct PuzzleRecord: Codable, Equatable {
    /// The chain this record was played against, so edits to the puzzle data invalidate it.
    var chain: String?
    /// Letters showing on each word, counted from the front.
    var revealed: [Int]
    var solved: [Bool]
    /// Words that were fully revealed rather than guessed.
    var given: [Bool]
    var finishedAt: Date?

    init(words: [String]) {
        chain = words.joined(separator: " ")
        let last = words.count - 1
        revealed = words.indices.map { $0 == 0 || $0 == last ? words[$0].count : 0 }
        solved = words.indices.map { $0 == 0 || $0 == last }
        given = Array(repeating: false, count: words.count)
    }

    var isFinished: Bool { finishedAt != nil }
    var isStarted: Bool { revealed.dropFirst().dropLast().contains { $0 > 0 } }

    /// Extra letters revealed beyond the free first letter, per middle word.
    var extraLetters: [Int] {
        Array(revealed.indices.dropFirst().dropLast().map { max(0, revealed[$0] - 1) })
    }

    var totalExtra: Int { extraLetters.reduce(0, +) }

    /// One square per middle word, for sharing.
    var emojiRow: String {
        revealed.indices.dropFirst().dropLast().map { i -> String in
            if given[i] { return "⚫" }
            switch max(0, revealed[i] - 1) {
            case 0: return "🟢"
            case 1: return "🟡"
            default: return "🟠"
            }
        }.joined()
    }
}

@Observable
final class ProgressStore {
    static let shared = ProgressStore()

    private(set) var records: [Int: PuzzleRecord] = [:]
    private let defaults = UserDefaults.standard
    private let key = "hitch.records.v1"
    private let persistent: Bool

    /// A non-persistent store is for examples; it neither loads nor saves.
    init(persistent: Bool = true) {
        self.persistent = persistent
        if persistent, let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Int: PuzzleRecord].self, from: data) {
            records = decoded
        }
    }

    func record(for puzzle: Puzzle) -> PuzzleRecord {
        if let r = records[puzzle.number], r.chain == puzzle.words.joined(separator: " ") { return r }
        return PuzzleRecord(words: puzzle.words)
    }

    func save(_ record: PuzzleRecord, for number: Int) {
        records[number] = record
        if persistent, let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: Stats

    var finished: [Int: PuzzleRecord] { records.filter { $0.value.isFinished } }

    var playedCount: Int { finished.count }

    var perfectCount: Int { finished.values.filter { $0.totalExtra == 0 }.count }

    /// Consecutive daily puzzles finished, ending today (or yesterday, if today isn't done yet).
    var currentStreak: Int {
        var n = PuzzleBook.todayNumber
        if finished[n] == nil { n -= 1 }
        var streak = 0
        while n >= 1, finished[n] != nil {
            streak += 1
            n -= 1
        }
        return streak
    }

    var longestStreak: Int {
        var best = 0, run = 0
        for n in 1...max(1, PuzzleBook.todayNumber) {
            run = finished[n] != nil ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }

    /// Buckets for 0, 1, 2, 3, 4, 5+ extra letters.
    var distribution: [Int] {
        var buckets = Array(repeating: 0, count: 6)
        for r in finished.values { buckets[min(5, r.totalExtra)] += 1 }
        return buckets
    }
}
