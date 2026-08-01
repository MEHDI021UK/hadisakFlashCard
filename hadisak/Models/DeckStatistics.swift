//
//  DeckStatistics.swift
//  hadisak
//
//  Shared, consistent deck counters used by list + detail screens.
//

import Foundation

struct DeckStatistics: Equatable, Sendable {
    /// Non-suspended cards (buried still count toward total).
    var total: Int
    /// Learning / relearning / review cards whose due date is now or past.
    var due: Int
    /// Cards currently in learning or relearning (whether due yet or not).
    var learning: Int
    /// Unseen new cards.
    var new: Int
    /// Review-stage cards (not suspended / buried).
    var review: Int

    /// Cards Study Now will actually load (active, not buried).
    var studyable: Int

    static let zero = DeckStatistics(total: 0, due: 0, learning: 0, new: 0, review: 0, studyable: 0)

    static func compute(from cards: [Card], now: Date = .now) -> DeckStatistics {
        var total = 0
        var due = 0
        var learning = 0
        var new = 0
        var review = 0
        var studyable = 0

        for card in cards {
            if card.isSuspended { continue }

            total += 1

            if card.isBuried { continue }

            studyable += 1

            switch card.status {
            case .new:
                new += 1
            case .learning, .relearning:
                learning += 1
                if card.dueDate <= now { due += 1 }
            case .review:
                review += 1
                if card.dueDate <= now { due += 1 }
            case .suspended:
                break
            }
        }

        return DeckStatistics(
            total: total,
            due: due,
            learning: learning,
            new: new,
            review: review,
            studyable: studyable
        )
    }
}
