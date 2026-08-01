//
//  Date+Extensions.swift
//  hadisak
//
//  Small date helpers for burying cards until next local midnight.
//

import Foundation

extension Date {
    /// Start of the next local calendar day.
    var startOfNextDay: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: self)
        return calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? self.addingTimeInterval(24 * 60 * 60)
    }
}
