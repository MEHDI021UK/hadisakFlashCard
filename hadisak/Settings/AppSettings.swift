//
//  AppSettings.swift
//  hadisak
//
//  Persisted user preferences via UserDefaults. Injected as an @Observable environment object.
//

import Foundation
import Observation
import SwiftUI

/// Supported UI languages. Card content is never translated.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case persian = "fa"

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .system: "settings.language.system"
        case .english: "settings.language.english"
        case .persian: "settings.language.persian"
        }
    }

    var locale: Locale? {
        switch self {
        case .system: nil
        case .english: Locale(identifier: "en")
        case .persian: Locale(identifier: "fa")
        }
    }

    var layoutDirection: LayoutDirection? {
        switch self {
        case .system: nil
        case .english: .leftToRight
        case .persian: .rightToLeft
        }
    }
}

@Observable
final class AppSettings {
    private enum Keys {
        static let theme = "settings.theme"
        static let language = "settings.language"
        static let dailyNewCardLimit = "settings.dailyNewCardLimit"
        static let learningSteps = "settings.learningSteps"
        static let reverseMode = "settings.reverseMode"
        static let newCardsStudiedDate = "settings.newCardsStudiedDate"
        static let newCardsStudiedCount = "settings.newCardsStudiedCount"
    }

    private let defaults: UserDefaults

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    var dailyNewCardLimit: Int {
        didSet { defaults.set(dailyNewCardLimit, forKey: Keys.dailyNewCardLimit) }
    }

    /// Learning steps in minutes, stored as a comma-separated string.
    var learningStepsMinutes: [Double] {
        didSet {
            let encoded = learningStepsMinutes.map { String(Int($0)) }.joined(separator: ",")
            defaults.set(encoded, forKey: Keys.learningSteps)
        }
    }

    /// Global reverse mode: show Back first, then Front.
    var reverseMode: Bool {
        didSet { defaults.set(reverseMode, forKey: Keys.reverseMode) }
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var schedulerConfiguration: SchedulerConfiguration {
        var config = SchedulerConfiguration.default
        let steps = learningStepsMinutes.filter { $0 > 0 }
        config.learningStepsMinutes = steps.isEmpty ? [1, 10] : steps
        return config
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Keys.theme),
           let stored = AppTheme(rawValue: raw) {
            theme = stored
        } else {
            theme = .light
        }

        if let raw = defaults.string(forKey: Keys.language),
           let stored = AppLanguage(rawValue: raw) {
            language = stored
        } else {
            language = .system
        }

        let limit = defaults.object(forKey: Keys.dailyNewCardLimit) as? Int
        dailyNewCardLimit = limit ?? 20

        if let stepsRaw = defaults.string(forKey: Keys.learningSteps) {
            learningStepsMinutes = stepsRaw
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        } else {
            learningStepsMinutes = [1, 10]
        }

        reverseMode = defaults.bool(forKey: Keys.reverseMode)
    }

    // MARK: - Daily New Card Tracking

    /// How many new cards have already been introduced today (local calendar).
    func newCardsIntroducedToday() -> Int {
        guard let date = defaults.object(forKey: Keys.newCardsStudiedDate) as? Date,
              Calendar.current.isDateInToday(date) else {
            return 0
        }
        return defaults.integer(forKey: Keys.newCardsStudiedCount)
    }

    func remainingNewCardQuota() -> Int {
        max(0, dailyNewCardLimit - newCardsIntroducedToday())
    }

    func recordNewCardIntroduction() {
        if let date = defaults.object(forKey: Keys.newCardsStudiedDate) as? Date,
           Calendar.current.isDateInToday(date) {
            let count = defaults.integer(forKey: Keys.newCardsStudiedCount) + 1
            defaults.set(count, forKey: Keys.newCardsStudiedCount)
        } else {
            defaults.set(Date.now, forKey: Keys.newCardsStudiedDate)
            defaults.set(1, forKey: Keys.newCardsStudiedCount)
        }
    }

    func resetDailyNewCardCount() {
        defaults.removeObject(forKey: Keys.newCardsStudiedDate)
        defaults.removeObject(forKey: Keys.newCardsStudiedCount)
    }
}
