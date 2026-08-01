//
//  SchedulingResult.swift
//  hadisak
//
//  Output of a single SM-2 scheduling calculation.
//

import Foundation

/// Result of applying a review rating to the current card state.
struct SchedulingResult: Sendable, Equatable {
    var easeFactor: Double
    var interval: Double
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var status: CardStatus
    var learningStep: Int

    /// Human-readable interval preview for rating buttons (e.g. "10m", "3d").
    var intervalDescription: String {
        Self.formatInterval(interval)
    }

    static func formatInterval(_ days: Double) -> String {
        if days < 1.0 / 1440.0 {
            return "<1m"
        }
        if days < 1.0 {
            let minutes = Int((days * 24 * 60).rounded())
            if minutes < 60 {
                return "\(max(minutes, 1))m"
            }
            let hours = Int((days * 24).rounded())
            return "\(hours)h"
        }
        if days < 30 {
            let wholeDays = Int(days.rounded())
            return "\(wholeDays)d"
        }
        if days < 365 {
            let months = Int((days / 30).rounded())
            return "\(months)mo"
        }
        let years = days / 365
        if years < 10 {
            return String(format: "%.1fy", years)
        }
        return "\(Int(years.rounded()))y"
    }
}
