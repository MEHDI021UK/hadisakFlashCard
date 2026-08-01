//
//  Deck.swift
//  hadisak
//
//  SwiftData model representing a flashcard deck.
//

import Foundation
import SwiftData

@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Deck Statistics

extension Deck {
    var statistics: DeckStatistics {
        DeckStatistics.compute(from: cards)
    }

    var totalCards: Int { statistics.total }
    var dueCards: Int { statistics.due }
    var learningCards: Int { statistics.learning }
    var newCards: Int { statistics.new }
    var reviewCards: Int { statistics.review }
}
