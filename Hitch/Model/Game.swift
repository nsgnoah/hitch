import Foundation
import Observation

enum SlotState: Equatable {
    case anchor, locked, active, solved, given
}

@Observable
final class Game {
    let puzzle: Puzzle
    private(set) var record: PuzzleRecord
    private let store: ProgressStore

    /// Which active word the keyboard is typing into.
    var selected: Int?
    /// Letters typed into the selected word's unrevealed positions.
    private(set) var typed: [Character] = []

    // Animation triggers
    private(set) var wrongCount = 0
    private(set) var solveCount = 0
    private(set) var lastSolved: Int?
    private(set) var lastWrong: Int?

    init(puzzle: Puzzle, store: ProgressStore = .shared) {
        self.puzzle = puzzle
        self.store = store
        self.record = store.record(for: puzzle)
        refreshFrontier(preferTop: true)
    }

    /// A game frozen at a given state, for illustrations.
    init(example words: [String], revealed: [Int], solved: [Bool], selected: Int?) {
        puzzle = Puzzle(number: 0, date: .now, words: words)
        store = ProgressStore(persistent: false)
        record = PuzzleRecord(words: words)
        record.revealed = revealed
        record.solved = solved
        self.selected = selected
    }

    var words: [String] { puzzle.words }
    var isFinished: Bool { record.isFinished }

    var topFrontier: Int? { record.solved.firstIndex(of: false) }
    var bottomFrontier: Int? { record.solved.lastIndex(of: false) }

    func state(_ i: Int) -> SlotState {
        if i == 0 || i == words.count - 1 { return .anchor }
        if record.given[i] { return .given }
        if record.solved[i] { return .solved }
        if i == topFrontier || i == bottomFrontier { return .active }
        return .locked
    }

    func revealed(_ i: Int) -> Int { record.revealed[i] }

    /// The letter to show at a position, if any (revealed or typed).
    func letter(_ i: Int, _ pos: Int) -> Character? {
        let word = Array(words[i])
        if record.solved[i] || pos < record.revealed[i] { return word[pos] }
        if i == selected {
            let t = pos - record.revealed[i]
            if t < typed.count { return typed[t] }
        }
        return nil
    }

    func isTyped(_ i: Int, _ pos: Int) -> Bool {
        i == selected && pos >= record.revealed[i] && pos - record.revealed[i] < typed.count
    }

    // MARK: Input

    func select(_ i: Int) {
        guard state(i) == .active, selected != i else { return }
        selected = i
        typed = []
    }

    /// Moves the keyboard to the other open end of the chain, if there is one.
    func switchWord() {
        guard let top = topFrontier, let bottom = bottomFrontier, top != bottom else { return }
        select(selected == top ? bottom : top)
    }

    func type(_ c: Character) {
        guard let i = selected, !isFinished else { return }
        let room = words[i].count - record.revealed[i]
        guard typed.count < room else { return }
        typed.append(Character(c.uppercased()))
    }

    func backspace() {
        guard !typed.isEmpty else { return }
        typed.removeLast()
    }

    var canSubmit: Bool {
        guard let i = selected else { return false }
        return typed.count == words[i].count - record.revealed[i] && !typed.isEmpty
    }

    func submit() {
        guard let i = selected, canSubmit else { return }
        let word = words[i]
        let guess = String(word.prefix(record.revealed[i])) + String(typed)
        typed = []
        if guess == word {
            solve(i, given: false)
        } else {
            lastWrong = i
            wrongCount += 1
            revealLetter(in: i)
        }
    }

    /// Show one more letter of the selected word. Costs the same as a wrong guess.
    func hint() {
        guard let i = selected, !isFinished else { return }
        typed = []
        revealLetter(in: i)
    }

    private func revealLetter(in i: Int) {
        record.revealed[i] = min(words[i].count, record.revealed[i] + 1)
        if record.revealed[i] >= words[i].count {
            solve(i, given: true)
        } else {
            persist()
        }
    }

    private func solve(_ i: Int, given: Bool) {
        let fromTop = i == topFrontier
        record.revealed[i] = max(record.revealed[i], given ? words[i].count : record.revealed[i])
        record.solved[i] = true
        record.given[i] = given
        lastSolved = i
        solveCount += 1
        if !record.solved.contains(false) {
            record.finishedAt = .now
            selected = nil
        } else {
            refreshFrontier(preferTop: fromTop)
        }
        persist()
    }

    private func refreshFrontier(preferTop: Bool) {
        guard let top = topFrontier, let bottom = bottomFrontier else {
            selected = nil
            return
        }
        for i in Set([top, bottom]) where record.revealed[i] == 0 {
            record.revealed[i] = 1
        }
        if let s = selected, s == top || s == bottom, !record.solved[s] { return }
        selected = preferTop ? top : bottom
        typed = []
    }

    private func persist() {
        store.save(record, for: puzzle.number)
    }

    // MARK: Sharing

    var shareText: String {
        let hints = record.totalExtra
        let summary = hints == 0 ? "Perfect chain" : "\(hints) extra letter\(hints == 1 ? "" : "s")"
        return "Hitch No. \(puzzle.number)\n\(record.emojiRow)\n\(summary)"
    }
}
