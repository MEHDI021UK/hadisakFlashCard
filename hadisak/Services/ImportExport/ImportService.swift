//
//  ImportService.swift
//  hadisak
//
//  Imports decks/cards from TXT, CSV, and JSON collection backups.
//

import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case invalidFormat
    case decodingFailed
    case emptyFile
    case unsupportedType

    var errorDescription: String? {
        switch self {
        case .invalidFormat: String(localized: "error.import.invalidFormat")
        case .decodingFailed: String(localized: "error.import.decoding")
        case .emptyFile: String(localized: "error.import.empty")
        case .unsupportedType: String(localized: "error.import.unsupported")
        }
    }
}

struct ImportedCardPair: Sendable, Equatable {
    var front: String
    var back: String
    var tags: [String]
}

struct ImportService: Sendable {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - TXT

    /// Parses Anki-style TXT:
    /// Front\nBack\n---\nFront\nBack
    func parseTXT(_ data: Data) throws -> [ImportedCardPair] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { throw ImportError.emptyFile }

        let blocks = normalized.components(separatedBy: "\n---\n")
        var pairs: [ImportedCardPair] = []

        for block in blocks {
            let lines = block
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
                .map { $0.trimmingCharacters(in: .whitespaces) }

            let nonEmpty = lines.filter { !$0.isEmpty }
            guard nonEmpty.count >= 2 else { continue }

            let front = nonEmpty[0]
            let back = nonEmpty[1]
            let tags: [String]
            if nonEmpty.count > 2 {
                tags = nonEmpty[2]
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            } else {
                tags = []
            }
            pairs.append(ImportedCardPair(front: front, back: back, tags: tags))
        }

        guard !pairs.isEmpty else { throw ImportError.invalidFormat }
        return pairs
    }

    // MARK: - CSV

    /// Parses CSV with columns: front,back[,tags]
    /// Supports simple quoted fields.
    func parseCSV(_ data: Data) throws -> [ImportedCardPair] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else { throw ImportError.emptyFile }

        var startIndex = 0
        if let first = lines.first?.lowercased(),
           first.contains("front") && first.contains("back") {
            startIndex = 1
        }

        var pairs: [ImportedCardPair] = []
        for line in lines[startIndex...] {
            let columns = parseCSVLine(line)
            guard columns.count >= 2 else { continue }
            let front = columns[0].trimmingCharacters(in: .whitespaces)
            let back = columns[1].trimmingCharacters(in: .whitespaces)
            guard !front.isEmpty, !back.isEmpty else { continue }
            let tags: [String]
            if columns.count > 2 {
                tags = columns[2]
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            } else {
                tags = []
            }
            pairs.append(ImportedCardPair(front: front, back: back, tags: tags))
        }

        guard !pairs.isEmpty else { throw ImportError.invalidFormat }
        return pairs
    }

    // MARK: - JSON

    func parseJSONBackup(_ data: Data) throws -> CollectionBackup {
        do {
            return try decoder.decode(CollectionBackup.self, from: data)
        } catch {
            throw ImportError.decodingFailed
        }
    }

    // MARK: - Persist

    @MainActor
    func importPairs(
        _ pairs: [ImportedCardPair],
        into deck: Deck,
        modelContext: ModelContext
    ) {
        for pair in pairs {
            let card = Card(front: pair.front, back: pair.back, tags: pair.tags, deck: deck)
            modelContext.insert(card)
        }
        deck.updatedAt = .now
        try? modelContext.save()
    }

    @MainActor
    func importBackup(
        _ backup: CollectionBackup,
        modelContext: ModelContext,
        merge: Bool = true
    ) throws {
        for deckDTO in backup.decks {
            let deck: Deck
            if merge,
               let existing = try modelContext.fetch(
                FetchDescriptor<Deck>(predicate: #Predicate { $0.id == deckDTO.id })
               ).first {
                existing.name = deckDTO.name
                existing.updatedAt = deckDTO.updatedAt
                deck = existing
            } else {
                deck = Deck(
                    id: deckDTO.id,
                    name: deckDTO.name,
                    createdAt: deckDTO.createdAt,
                    updatedAt: deckDTO.updatedAt
                )
                modelContext.insert(deck)
            }

            for cardDTO in deckDTO.cards {
                if merge,
                   let existingCard = try modelContext.fetch(
                    FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardDTO.id })
                   ).first {
                    apply(cardDTO, to: existingCard)
                    existingCard.deck = deck
                } else {
                    let card = makeCard(from: cardDTO, deck: deck)
                    modelContext.insert(card)
                    for logDTO in cardDTO.reviewLogs {
                        let log = makeReviewLog(from: logDTO, card: card)
                        modelContext.insert(log)
                    }
                }
            }
        }
        try modelContext.save()
    }

    // MARK: - Helpers

    private func apply(_ dto: CardDTO, to card: Card) {
        card.front = dto.front
        card.back = dto.back
        card.tags = dto.tags
        card.easeFactor = dto.easeFactor
        card.interval = dto.interval
        card.repetitions = dto.repetitions
        card.dueDate = dto.dueDate
        card.lapses = dto.lapses
        card.status = CardStatus(rawValue: dto.status) ?? .new
        card.learningStep = dto.learningStep
        card.createdAt = dto.createdAt
        card.updatedAt = dto.updatedAt
        card.lastReviewedAt = dto.lastReviewedAt
        card.cardType = dto.cardType
        card.isSuspended = dto.isSuspended
        card.buriedUntil = dto.buriedUntil
    }

    private func makeCard(from dto: CardDTO, deck: Deck) -> Card {
        Card(
            id: dto.id,
            front: dto.front,
            back: dto.back,
            tags: dto.tags,
            easeFactor: dto.easeFactor,
            interval: dto.interval,
            repetitions: dto.repetitions,
            dueDate: dto.dueDate,
            lapses: dto.lapses,
            status: CardStatus(rawValue: dto.status) ?? .new,
            learningStep: dto.learningStep,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            lastReviewedAt: dto.lastReviewedAt,
            cardType: dto.cardType,
            isSuspended: dto.isSuspended,
            buriedUntil: dto.buriedUntil,
            deck: deck
        )
    }

    private func makeReviewLog(from dto: ReviewLogDTO, card: Card) -> ReviewLog {
        ReviewLog(
            id: dto.id,
            reviewDate: dto.reviewDate,
            rating: ReviewRating(rawValue: dto.rating) ?? .good,
            previousInterval: dto.previousInterval,
            newInterval: dto.newInterval,
            previousEaseFactor: dto.previousEaseFactor,
            newEaseFactor: dto.newEaseFactor,
            previousStatus: CardStatus(rawValue: dto.previousStatus) ?? .new,
            newStatus: CardStatus(rawValue: dto.newStatus) ?? .review,
            card: card
        )
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]
            if char == "\"" {
                let next = line.index(after: index)
                if inQuotes, next < line.endIndex, line[next] == "\"" {
                    current.append("\"")
                    index = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
                index = line.index(after: index)
                continue
            }
            if char == "," && !inQuotes {
                result.append(current)
                current = ""
                index = line.index(after: index)
                continue
            }
            current.append(char)
            index = line.index(after: index)
        }
        result.append(current)
        return result
    }
}
