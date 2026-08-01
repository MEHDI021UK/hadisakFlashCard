//
//  Card.swift
//  hadisak
//
//  SwiftData model for a Front/Back flashcard with SM-2 scheduling fields.
//  Designed so future card types (Cloze, Image Occlusion) can extend via `cardType`.
//

import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var front: String
    var back: String
    /// Comma-separated tags for lightweight filtering; kept as a string for simple import/export.
    var tagsRaw: String
    var easeFactor: Double
    /// Interval in days (fractional for learning steps measured in minutes).
    var interval: Double
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var statusRaw: String
    var learningStep: Int
    var createdAt: Date
    var updatedAt: Date
    var lastReviewedAt: Date?
    /// Extensible type discriminator for future card kinds.
    var cardType: String
    var isSuspended: Bool
    /// Buried until the next calendar day (local midnight).
    var buriedUntil: Date?

    var deck: Deck?

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviewLogs: [ReviewLog] = []

    var tags: [String] {
        get {
            tagsRaw
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRaw = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        }
    }

    var status: CardStatus {
        get { CardStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var isBuried: Bool {
        guard let buriedUntil else { return false }
        return buriedUntil > Date.now
    }

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        tags: [String] = [],
        easeFactor: Double = 2.5,
        interval: Double = 0,
        repetitions: Int = 0,
        dueDate: Date = .now,
        lapses: Int = 0,
        status: CardStatus = .new,
        learningStep: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastReviewedAt: Date? = nil,
        cardType: String = "basic",
        isSuspended: Bool = false,
        buriedUntil: Date? = nil,
        deck: Deck? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.tagsRaw = tags.joined(separator: ", ")
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.lapses = lapses
        self.statusRaw = status.rawValue
        self.learningStep = learningStep
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReviewedAt = lastReviewedAt
        self.cardType = cardType
        self.isSuspended = isSuspended
        self.buriedUntil = buriedUntil
        self.deck = deck
    }

    /// Snapshot of scheduling fields used for undo.
    func schedulingSnapshot() -> CardSchedulingSnapshot {
        CardSchedulingSnapshot(
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            dueDate: dueDate,
            lapses: lapses,
            status: status,
            learningStep: learningStep,
            lastReviewedAt: lastReviewedAt,
            updatedAt: updatedAt
        )
    }

    func restore(from snapshot: CardSchedulingSnapshot) {
        easeFactor = snapshot.easeFactor
        interval = snapshot.interval
        repetitions = snapshot.repetitions
        dueDate = snapshot.dueDate
        lapses = snapshot.lapses
        status = snapshot.status
        learningStep = snapshot.learningStep
        lastReviewedAt = snapshot.lastReviewedAt
        updatedAt = snapshot.updatedAt
    }
}

/// Value-type snapshot of mutable scheduling state for undo support.
struct CardSchedulingSnapshot: Sendable, Equatable {
    var easeFactor: Double
    var interval: Double
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var status: CardStatus
    var learningStep: Int
    var lastReviewedAt: Date?
    var updatedAt: Date
}
