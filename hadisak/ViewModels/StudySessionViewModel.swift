//
//  StudySessionViewModel.swift
//  hadisak
//
//  Orchestrates a study session: queue building, reveal, rating, undo, bury, suspend.
//

import Foundation
import Observation
import SwiftData

/// Which side is shown first during a study session. Does not duplicate cards.
enum StudyDirection: String, CaseIterable, Identifiable, Sendable {
    case normal
    case reverse

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .normal: "study.direction.normal"
        case .reverse: "study.direction.reverse"
        }
    }
}

struct UndoRecord: Sendable {
    var cardID: UUID
    var snapshot: CardSchedulingSnapshot
    var reviewLogID: UUID?
    var countedAsNewIntroduction: Bool
}

@Observable
@MainActor
final class StudySessionViewModel {
    private(set) var queue: [Card] = []
    private(set) var currentIndex: Int = 0
    private(set) var isAnswerRevealed: Bool = false
    private(set) var isFinished: Bool = false
    private(set) var reviewedCount: Int = 0
    private(set) var intervalPreviews: [ReviewRating: String] = [:]

    var direction: StudyDirection
    var deckName: String

    private var modelContext: ModelContext
    private var settings: AppSettings
    private var scheduler: SM2Scheduler
    private var undoStack: [UndoRecord] = []
    private var sessionNewIntroductions: Int = 0

    var currentCard: Card? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var remainingCount: Int {
        max(0, queue.count - currentIndex)
    }

    var progress: Double {
        let total = reviewedCount + remainingCount
        guard total > 0 else { return 1 }
        return Double(reviewedCount) / Double(total)
    }

    /// Prompt side text based on study direction.
    var promptText: String {
        guard let card = currentCard else { return "" }
        return direction == .normal ? card.front : card.back
    }

    /// Answer side text based on study direction.
    var answerText: String {
        guard let card = currentCard else { return "" }
        return direction == .normal ? card.back : card.front
    }

    var canUndo: Bool { !undoStack.isEmpty }

    init(
        deck: Deck,
        modelContext: ModelContext,
        settings: AppSettings,
        direction: StudyDirection? = nil
    ) {
        self.modelContext = modelContext
        self.settings = settings
        self.direction = direction ?? (settings.reverseMode ? .reverse : .normal)
        self.deckName = deck.name
        self.scheduler = SM2Scheduler(configuration: settings.schedulerConfiguration)
        rebuildQueue(from: deck)
        refreshPreviews()
    }

    func rebuildQueue(from deck: Deck) {
        // Include every active card so the user can study whenever they want.
        // Due cards come first; not-yet-due learning/review follow; new cards last.
        let now = Date.now
        let eligible = deck.cards.filter { card in
            !card.isSuspended && !card.isBuried
        }

        let dueLearning = eligible
            .filter { ($0.status == .learning || $0.status == .relearning) && $0.dueDate <= now }
            .sorted { $0.dueDate < $1.dueDate }

        let dueReview = eligible
            .filter { $0.status == .review && $0.dueDate <= now }
            .sorted { $0.dueDate < $1.dueDate }

        let earlyLearning = eligible
            .filter { ($0.status == .learning || $0.status == .relearning) && $0.dueDate > now }
            .sorted { $0.dueDate < $1.dueDate }

        let earlyReview = eligible
            .filter { $0.status == .review && $0.dueDate > now }
            .sorted { $0.dueDate < $1.dueDate }

        let newCards = eligible
            .filter { $0.status == .new }
            .sorted { $0.createdAt < $1.createdAt }

        queue = dueLearning + dueReview + earlyLearning + earlyReview + newCards
        currentIndex = 0
        isAnswerRevealed = false
        isFinished = queue.isEmpty
        reviewedCount = 0
    }

    func revealAnswer() {
        guard !isAnswerRevealed, currentCard != nil else { return }
        isAnswerRevealed = true
        Haptics.selection()
    }

    func rate(_ rating: ReviewRating) {
        guard let card = currentCard, isAnswerRevealed else { return }

        let previousStatus = card.status
        let snapshot = card.schedulingSnapshot()
        let wasNew = previousStatus == .new

        let result = scheduler.schedule(
            status: card.status == .new ? .learning : card.status,
            easeFactor: card.easeFactor,
            interval: card.interval,
            repetitions: card.repetitions,
            lapses: card.lapses,
            learningStep: card.learningStep,
            rating: rating
        )

        card.easeFactor = result.easeFactor
        card.interval = result.interval
        card.repetitions = result.repetitions
        card.dueDate = result.dueDate
        card.lapses = result.lapses
        card.status = result.status
        card.learningStep = result.learningStep
        card.lastReviewedAt = .now
        card.updatedAt = .now

        let log = ReviewLog(
            rating: rating,
            previousInterval: snapshot.interval,
            newInterval: result.interval,
            previousEaseFactor: snapshot.easeFactor,
            newEaseFactor: result.easeFactor,
            previousStatus: previousStatus,
            newStatus: result.status,
            card: card
        )
        modelContext.insert(log)

        if wasNew {
            settings.recordNewCardIntroduction()
            sessionNewIntroductions += 1
        }

        // Re-queue learning cards that become due again within the session window.
        if (result.status == .learning || result.status == .relearning),
           result.dueDate.timeIntervalSinceNow <= 60 * 15 {
            // Keep in session later by appending a reference after current position.
            // We'll re-insert when due; for simplicity, append if due within a few minutes.
            if result.dueDate.timeIntervalSinceNow <= 10 * 60 {
                queue.append(card)
            }
        }

        undoStack.append(
            UndoRecord(
                cardID: card.id,
                snapshot: snapshot,
                reviewLogID: log.id,
                countedAsNewIntroduction: wasNew
            )
        )

        try? modelContext.save()
        Haptics.rating(rating)

        reviewedCount += 1
        advance()
    }

    func undo() {
        guard let record = undoStack.popLast() else { return }
        guard let card = queue.first(where: { $0.id == record.cardID })
                ?? fetchCard(id: record.cardID) else { return }

        card.restore(from: record.snapshot)

        if let logID = record.reviewLogID,
           let log = card.reviewLogs.first(where: { $0.id == logID }) {
            modelContext.delete(log)
        }

        // Best-effort: cannot perfectly rewind daily quota across days, but within session:
        if record.countedAsNewIntroduction {
            sessionNewIntroductions = max(0, sessionNewIntroductions - 1)
        }

        // Put the card back as current.
        if let existingIndex = queue.firstIndex(where: { $0.id == card.id }) {
            currentIndex = existingIndex
        } else {
            queue.insert(card, at: currentIndex)
        }

        reviewedCount = max(0, reviewedCount - 1)
        isAnswerRevealed = false
        isFinished = false
        refreshPreviews()
        try? modelContext.save()
        Haptics.warning()
    }

    func suspendCurrent() {
        guard let card = currentCard else { return }
        card.isSuspended = true
        card.updatedAt = .now
        try? modelContext.save()
        Haptics.impactRigid()
        removeCurrentAndAdvance()
    }

    func buryCurrent() {
        guard let card = currentCard else { return }
        card.buriedUntil = Date.now.startOfNextDay
        card.updatedAt = .now
        try? modelContext.save()
        Haptics.impactLight()
        removeCurrentAndAdvance()
    }

    func toggleDirection() {
        direction = (direction == .normal) ? .reverse : .normal
        isAnswerRevealed = false
        Haptics.selection()
    }

    // MARK: - Private

    private func advance() {
        currentIndex += 1
        isAnswerRevealed = false
        if currentIndex >= queue.count {
            isFinished = true
        } else {
            refreshPreviews()
        }
    }

    private func removeCurrentAndAdvance() {
        guard currentIndex < queue.count else { return }
        queue.remove(at: currentIndex)
        isAnswerRevealed = false
        if currentIndex >= queue.count {
            isFinished = true
        } else {
            refreshPreviews()
        }
    }

    private func refreshPreviews() {
        guard let card = currentCard else {
            intervalPreviews = [:]
            return
        }
        let status = card.status == .new ? CardStatus.learning : card.status
        intervalPreviews = scheduler.previewIntervals(
            status: status,
            easeFactor: card.easeFactor,
            interval: card.interval,
            repetitions: card.repetitions,
            lapses: card.lapses,
            learningStep: card.learningStep
        )
    }

    private func fetchCard(id: UUID) -> Card? {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }
}
