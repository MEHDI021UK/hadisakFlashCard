//
//  ReviewRating.swift
//  hadisak
//
//  Answer buttons shown after revealing a card.
//

import Foundation

/// User rating for a review, matching Anki's Again / Hard / Good / Easy buttons.
enum ReviewRating: Int, Codable, CaseIterable, Sendable, Identifiable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .again: "rating.again"
        case .hard: "rating.hard"
        case .good: "rating.good"
        case .easy: "rating.easy"
        }
    }

    /// Accessibility / VoiceOver label key.
    var accessibilityKey: String {
        switch self {
        case .again: "rating.again.a11y"
        case .hard: "rating.hard.a11y"
        case .good: "rating.good.a11y"
        case .easy: "rating.easy.a11y"
        }
    }
}
