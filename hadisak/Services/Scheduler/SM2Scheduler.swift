//
//  SM2Scheduler.swift
//  hadisak
//
//  Simplified Anki-like SM-2 spaced repetition engine with learning steps.
//

import Foundation

/// Configuration knobs for the SM-2 scheduler.
struct SchedulerConfiguration: Sendable, Equatable {
    /// Learning step durations in minutes (e.g. [1, 10]).
    var learningStepsMinutes: [Double]
    /// Starting ease factor for new cards.
    var startingEase: Double
    /// Minimum allowed ease factor.
    var minimumEase: Double
    /// Easy bonus multiplier applied on Easy from review.
    var easyBonus: Double
    /// Hard interval multiplier for review cards.
    var hardIntervalMultiplier: Double
    /// Interval modifier applied to Good/Easy graduating intervals.
    var intervalModifier: Double
    /// Graduating interval in days when leaving learning via Good.
    var graduatingIntervalDays: Double
    /// Easy graduating interval in days when leaving learning via Easy.
    var easyGraduatingIntervalDays: Double

    static let `default` = SchedulerConfiguration(
        learningStepsMinutes: [1, 10],
        startingEase: 2.5,
        minimumEase: 1.3,
        easyBonus: 1.3,
        hardIntervalMultiplier: 1.2,
        intervalModifier: 1.0,
        graduatingIntervalDays: 1,
        easyGraduatingIntervalDays: 4
    )
}

/// Pure SM-2 scheduling engine. Stateless and side-effect free.
struct SM2Scheduler: Sendable {
    var configuration: SchedulerConfiguration

    init(configuration: SchedulerConfiguration = .default) {
        self.configuration = configuration
    }

    /// Compute the next scheduling state for a card given a rating.
    func schedule(
        status: CardStatus,
        easeFactor: Double,
        interval: Double,
        repetitions: Int,
        lapses: Int,
        learningStep: Int,
        rating: ReviewRating,
        now: Date = .now
    ) -> SchedulingResult {
        switch status {
        case .new, .learning, .relearning:
            return scheduleLearning(
                status: status,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                lapses: lapses,
                learningStep: learningStep,
                rating: rating,
                now: now
            )
        case .review:
            return scheduleReview(
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                lapses: lapses,
                rating: rating,
                now: now
            )
        case .suspended:
            return SchedulingResult(
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                dueDate: now,
                lapses: lapses,
                status: .suspended,
                learningStep: learningStep
            )
        }
    }

    /// Preview intervals for all four buttons without mutating state.
    func previewIntervals(
        status: CardStatus,
        easeFactor: Double,
        interval: Double,
        repetitions: Int,
        lapses: Int,
        learningStep: Int,
        now: Date = .now
    ) -> [ReviewRating: String] {
        var result: [ReviewRating: String] = [:]
        for rating in ReviewRating.allCases {
            let scheduled = schedule(
                status: status,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                lapses: lapses,
                learningStep: learningStep,
                rating: rating,
                now: now
            )
            result[rating] = scheduled.intervalDescription
        }
        return result
    }

    // MARK: - Learning / Relearning

    private func scheduleLearning(
        status: CardStatus,
        easeFactor: Double,
        interval: Double,
        repetitions: Int,
        lapses: Int,
        learningStep: Int,
        rating: ReviewRating,
        now: Date
    ) -> SchedulingResult {
        let steps = configuration.learningStepsMinutes
        let effectiveStatus: CardStatus = (status == .new) ? .learning : status

        switch rating {
        case .again:
            let stepIndex = 0
            let minutes = steps.first ?? 1
            let nextInterval = minutes / (24.0 * 60.0)
            return SchedulingResult(
                easeFactor: easeFactor,
                interval: nextInterval,
                repetitions: 0,
                dueDate: now.addingTimeInterval(minutes * 60),
                lapses: lapses,
                status: effectiveStatus == .relearning ? .relearning : .learning,
                learningStep: stepIndex
            )

        case .hard:
            let stepIndex = min(learningStep, max(steps.count - 1, 0))
            let minutes = steps.isEmpty ? 10 : steps[stepIndex]
            // Hard repeats the current step with a slightly longer delay.
            let hardMinutes = max(minutes * 1.5, minutes + 1)
            let nextInterval = hardMinutes / (24.0 * 60.0)
            return SchedulingResult(
                easeFactor: easeFactor,
                interval: nextInterval,
                repetitions: repetitions,
                dueDate: now.addingTimeInterval(hardMinutes * 60),
                lapses: lapses,
                status: effectiveStatus == .relearning ? .relearning : .learning,
                learningStep: stepIndex
            )

        case .good:
            let nextStep = learningStep + 1
            if nextStep >= steps.count {
                // Graduate to review.
                let days = configuration.graduatingIntervalDays * configuration.intervalModifier
                return SchedulingResult(
                    easeFactor: max(easeFactor, configuration.startingEase),
                    interval: days,
                    repetitions: max(repetitions, 1),
                    dueDate: now.addingTimeInterval(days * 24 * 60 * 60),
                    lapses: lapses,
                    status: .review,
                    learningStep: 0
                )
            }
            let minutes = steps[nextStep]
            let nextInterval = minutes / (24.0 * 60.0)
            return SchedulingResult(
                easeFactor: easeFactor,
                interval: nextInterval,
                repetitions: repetitions,
                dueDate: now.addingTimeInterval(minutes * 60),
                lapses: lapses,
                status: effectiveStatus == .relearning ? .relearning : .learning,
                learningStep: nextStep
            )

        case .easy:
            let days = configuration.easyGraduatingIntervalDays * configuration.intervalModifier
            return SchedulingResult(
                easeFactor: max(easeFactor, configuration.startingEase),
                interval: days,
                repetitions: max(repetitions, 1),
                dueDate: now.addingTimeInterval(days * 24 * 60 * 60),
                lapses: lapses,
                status: .review,
                learningStep: 0
            )
        }
    }

    // MARK: - Review

    private func scheduleReview(
        easeFactor: Double,
        interval: Double,
        repetitions: Int,
        lapses: Int,
        rating: ReviewRating,
        now: Date
    ) -> SchedulingResult {
        switch rating {
        case .again:
            let newEase = max(configuration.minimumEase, easeFactor - 0.2)
            let steps = configuration.learningStepsMinutes
            let minutes = steps.first ?? 1
            let nextInterval = minutes / (24.0 * 60.0)
            return SchedulingResult(
                easeFactor: newEase,
                interval: nextInterval,
                repetitions: 0,
                dueDate: now.addingTimeInterval(minutes * 60),
                lapses: lapses + 1,
                status: .relearning,
                learningStep: 0
            )

        case .hard:
            let newEase = max(configuration.minimumEase, easeFactor - 0.15)
            let days = max(interval * configuration.hardIntervalMultiplier * configuration.intervalModifier, 1.0)
            return SchedulingResult(
                easeFactor: newEase,
                interval: days,
                repetitions: repetitions + 1,
                dueDate: now.addingTimeInterval(days * 24 * 60 * 60),
                lapses: lapses,
                status: .review,
                learningStep: 0
            )

        case .good:
            let days: Double
            if repetitions == 0 {
                days = configuration.graduatingIntervalDays
            } else if repetitions == 1 {
                days = max(interval * easeFactor, configuration.graduatingIntervalDays * 2)
            } else {
                days = max(interval * easeFactor * configuration.intervalModifier, 1.0)
            }
            return SchedulingResult(
                easeFactor: easeFactor,
                interval: days,
                repetitions: repetitions + 1,
                dueDate: now.addingTimeInterval(days * 24 * 60 * 60),
                lapses: lapses,
                status: .review,
                learningStep: 0
            )

        case .easy:
            let newEase = easeFactor + 0.15
            let base: Double
            if repetitions == 0 {
                base = configuration.easyGraduatingIntervalDays
            } else {
                base = max(interval * easeFactor * configuration.easyBonus * configuration.intervalModifier, 1.0)
            }
            return SchedulingResult(
                easeFactor: newEase,
                interval: base,
                repetitions: repetitions + 1,
                dueDate: now.addingTimeInterval(base * 24 * 60 * 60),
                lapses: lapses,
                status: .review,
                learningStep: 0
            )
        }
    }
}
