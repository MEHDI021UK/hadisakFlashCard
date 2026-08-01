//
//  ReviewLog.swift
//  hadisak
//
//  Immutable history entry for each review action.
//

import Foundation
import SwiftData

@Model
final class ReviewLog {
    @Attribute(.unique) var id: UUID
    var reviewDate: Date
    var ratingRaw: Int
    var previousInterval: Double
    var newInterval: Double
    var previousEaseFactor: Double
    var newEaseFactor: Double
    var previousStatusRaw: String
    var newStatusRaw: String

    var card: Card?

    var rating: ReviewRating {
        get { ReviewRating(rawValue: ratingRaw) ?? .good }
        set { ratingRaw = newValue.rawValue }
    }

    var previousStatus: CardStatus {
        get { CardStatus(rawValue: previousStatusRaw) ?? .new }
        set { previousStatusRaw = newValue.rawValue }
    }

    var newStatus: CardStatus {
        get { CardStatus(rawValue: newStatusRaw) ?? .review }
        set { newStatusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        reviewDate: Date = .now,
        rating: ReviewRating,
        previousInterval: Double,
        newInterval: Double,
        previousEaseFactor: Double,
        newEaseFactor: Double,
        previousStatus: CardStatus,
        newStatus: CardStatus,
        card: Card? = nil
    ) {
        self.id = id
        self.reviewDate = reviewDate
        self.ratingRaw = rating.rawValue
        self.previousInterval = previousInterval
        self.newInterval = newInterval
        self.previousEaseFactor = previousEaseFactor
        self.newEaseFactor = newEaseFactor
        self.previousStatusRaw = previousStatus.rawValue
        self.newStatusRaw = newStatus.rawValue
        self.card = card
    }
}
