//
//  ExportService.swift
//  hadisak
//
//  Exports collection or individual decks to JSON and SQLite-compatible dump formats.
//

import Foundation
import SwiftData

enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case json
    case sqlite

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .json: "export.format.json"
        case .sqlite: "export.format.sqlite"
        }
    }

    var fileExtension: String {
        switch self {
        case .json: "json"
        case .sqlite: "sqlite.sql"
        }
    }

    var contentTypeIdentifier: String {
        switch self {
        case .json: "public.json"
        case .sqlite: "public.sql"
        }
    }
}

enum ExportError: LocalizedError {
    case encodingFailed
    case noDecks

    var errorDescription: String? {
        switch self {
        case .encodingFailed: String(localized: "error.export.encoding")
        case .noDecks: String(localized: "error.export.noDecks")
        }
    }
}

struct ExportService: Sendable {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// Export the entire collection as a `CollectionBackup`.
    func makeBackup(decks: [Deck]) -> CollectionBackup {
        CollectionBackup(
            version: CollectionBackup.currentVersion,
            exportedAt: .now,
            decks: decks.map(DeckDTO.init)
        )
    }

    /// Export a single deck wrapped in a collection backup.
    func makeBackup(deck: Deck) -> CollectionBackup {
        CollectionBackup(
            version: CollectionBackup.currentVersion,
            exportedAt: .now,
            decks: [DeckDTO(deck: deck)]
        )
    }

    func exportJSON(backup: CollectionBackup) throws -> Data {
        do {
            return try encoder.encode(backup)
        } catch {
            throw ExportError.encodingFailed
        }
    }

    /// Produce a portable SQL dump that can recreate the collection in SQLite.
    func exportSQLiteSQL(backup: CollectionBackup) -> Data {
        var lines: [String] = []
        lines.append("-- hadisak SQLite dump")
        lines.append("-- Exported: \(ISO8601DateFormatter().string(from: backup.exportedAt))")
        lines.append("PRAGMA foreign_keys = OFF;")
        lines.append("BEGIN TRANSACTION;")
        lines.append("""
        CREATE TABLE IF NOT EXISTS decks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
        """)
        lines.append("""
        CREATE TABLE IF NOT EXISTS cards (
          id TEXT PRIMARY KEY,
          deck_id TEXT NOT NULL,
          front TEXT NOT NULL,
          back TEXT NOT NULL,
          tags TEXT,
          ease_factor REAL,
          interval REAL,
          repetitions INTEGER,
          due_date TEXT,
          lapses INTEGER,
          status TEXT,
          learning_step INTEGER,
          created_at TEXT,
          updated_at TEXT,
          last_reviewed_at TEXT,
          card_type TEXT,
          is_suspended INTEGER,
          buried_until TEXT,
          FOREIGN KEY(deck_id) REFERENCES decks(id)
        );
        """)
        lines.append("""
        CREATE TABLE IF NOT EXISTS review_logs (
          id TEXT PRIMARY KEY,
          card_id TEXT NOT NULL,
          review_date TEXT,
          rating INTEGER,
          previous_interval REAL,
          new_interval REAL,
          previous_ease_factor REAL,
          new_ease_factor REAL,
          previous_status TEXT,
          new_status TEXT,
          FOREIGN KEY(card_id) REFERENCES cards(id)
        );
        """)

        let iso = ISO8601DateFormatter()

        for deck in backup.decks {
            lines.append(
                "INSERT INTO decks (id, name, created_at, updated_at) VALUES (" +
                "'\(deck.id.uuidString)', \(sqlString(deck.name)), '\(iso.string(from: deck.createdAt))', '\(iso.string(from: deck.updatedAt))');"
            )

            for card in deck.cards {
                let tags = card.tags.joined(separator: ", ")
                let lastReviewed = card.lastReviewedAt.map { "'\(iso.string(from: $0))'" } ?? "NULL"
                let buried = card.buriedUntil.map { "'\(iso.string(from: $0))'" } ?? "NULL"
                lines.append(
                    "INSERT INTO cards (id, deck_id, front, back, tags, ease_factor, interval, repetitions, due_date, lapses, status, learning_step, created_at, updated_at, last_reviewed_at, card_type, is_suspended, buried_until) VALUES (" +
                    "'\(card.id.uuidString)', '\(deck.id.uuidString)', \(sqlString(card.front)), \(sqlString(card.back)), \(sqlString(tags)), " +
                    "\(card.easeFactor), \(card.interval), \(card.repetitions), '\(iso.string(from: card.dueDate))', \(card.lapses), " +
                    "'\(card.status)', \(card.learningStep), '\(iso.string(from: card.createdAt))', '\(iso.string(from: card.updatedAt))', " +
                    "\(lastReviewed), '\(card.cardType)', \(card.isSuspended ? 1 : 0), \(buried));"
                )

                for log in card.reviewLogs {
                    lines.append(
                        "INSERT INTO review_logs (id, card_id, review_date, rating, previous_interval, new_interval, previous_ease_factor, new_ease_factor, previous_status, new_status) VALUES (" +
                        "'\(log.id.uuidString)', '\(card.id.uuidString)', '\(iso.string(from: log.reviewDate))', \(log.rating), " +
                        "\(log.previousInterval), \(log.newInterval), \(log.previousEaseFactor), \(log.newEaseFactor), " +
                        "'\(log.previousStatus)', '\(log.newStatus)');"
                    )
                }
            }
        }

        lines.append("COMMIT;")
        lines.append("PRAGMA foreign_keys = ON;")
        return Data(lines.joined(separator: "\n").utf8)
    }

    private func sqlString(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "''") + "'"
    }
}
