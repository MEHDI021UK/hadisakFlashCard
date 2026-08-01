//
//  CardStatus.swift
//  hadisak
//
//  Learning lifecycle states for spaced-repetition cards.
//

import Foundation

/// Learning lifecycle for a flashcard in the SM-2 pipeline.
enum CardStatus: String, Codable, CaseIterable, Sendable {
    /// Never studied; waiting to enter the learning queue.
    case new
    /// Currently progressing through learning steps.
    case learning
    /// Graduated into the long-term review schedule.
    case review
    /// Relearning after a lapse from the review queue.
    case relearning
    /// Temporarily excluded from study sessions.
    case suspended
}
