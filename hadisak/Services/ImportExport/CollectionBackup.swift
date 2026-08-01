//
//  CollectionBackup.swift
//  hadisak
//
//  Codable DTOs used for JSON import/export of the full collection or a single deck.
//

import Foundation

struct CollectionBackup: Codable, Sendable {
    var version: Int
    var exportedAt: Date
    var decks: [DeckDTO]

    static let currentVersion = 1
}

struct DeckDTO: Codable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var cards: [CardDTO]
}

struct CardDTO: Codable, Sendable, Identifiable {
    var id: UUID
    var front: String
    var back: String
    var tags: [String]
    var easeFactor: Double
    var interval: Double
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var status: String
    var learningStep: Int
    var createdAt: Date
    var updatedAt: Date
    var lastReviewedAt: Date?
    var cardType: String
    var isSuspended: Bool
    var buriedUntil: Date?
    var reviewLogs: [ReviewLogDTO]
}

struct ReviewLogDTO: Codable, Sendable, Identifiable {
    var id: UUID
    var reviewDate: Date
    var rating: Int
    var previousInterval: Double
    var newInterval: Double
    var previousEaseFactor: Double
    var newEaseFactor: Double
    var previousStatus: String
    var newStatus: String
}

// MARK: - Mapping

extension DeckDTO {
    init(deck: Deck) {
        id = deck.id
        name = deck.name
        createdAt = deck.createdAt
        updatedAt = deck.updatedAt
        cards = deck.cards.map(CardDTO.init)
    }
}

extension CardDTO {
    init(card: Card) {
        id = card.id
        front = card.front
        back = card.back
        tags = card.tags
        easeFactor = card.easeFactor
        interval = card.interval
        repetitions = card.repetitions
        dueDate = card.dueDate
        lapses = card.lapses
        status = card.status.rawValue
        learningStep = card.learningStep
        createdAt = card.createdAt
        updatedAt = card.updatedAt
        lastReviewedAt = card.lastReviewedAt
        cardType = card.cardType
        isSuspended = card.isSuspended
        buriedUntil = card.buriedUntil
        reviewLogs = card.reviewLogs.map(ReviewLogDTO.init)
    }
}

extension ReviewLogDTO {
    init(log: ReviewLog) {
        id = log.id
        reviewDate = log.reviewDate
        rating = log.ratingRaw
        previousInterval = log.previousInterval
        newInterval = log.newInterval
        previousEaseFactor = log.previousEaseFactor
        newEaseFactor = log.newEaseFactor
        previousStatus = log.previousStatusRaw
        newStatus = log.newStatusRaw
    }
}
