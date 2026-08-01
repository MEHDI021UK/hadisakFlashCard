//
//  SettingsViewModel.swift
//  hadisak
//
//  Settings screen actions for theme, language, limits, and import/export.
//

import Foundation
import Observation
import SwiftData
import UniformTypeIdentifiers

@Observable
@MainActor
final class SettingsViewModel {
    var learningStepsText: String
    var exportDocument: ExportDocument?
    var importError: String?
    var exportError: String?
    var statusMessage: String?

    private let settings: AppSettings
    private let exportService = ExportService()
    private let importService = ImportService()

    init(settings: AppSettings) {
        self.settings = settings
        self.learningStepsText = settings.learningStepsMinutes
            .map { String(Int($0)) }
            .joined(separator: ", ")
    }

    func applyLearningSteps() {
        let steps = learningStepsText
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 > 0 }
        settings.learningStepsMinutes = steps.isEmpty ? [1, 10] : steps
        learningStepsText = settings.learningStepsMinutes.map { String(Int($0)) }.joined(separator: ", ")
        Haptics.selection()
    }

    func prepareExport(decks: [Deck], format: ExportFormat) {
        guard !decks.isEmpty else {
            exportError = ExportError.noDecks.localizedDescription
            return
        }
        let backup = exportService.makeBackup(decks: decks)
        do {
            let data: Data
            switch format {
            case .json:
                data = try exportService.exportJSON(backup: backup)
            case .sqlite:
                data = exportService.exportSQLiteSQL(backup: backup)
            }
            let filename = "hadisak-collection.\(format.fileExtension)"
            exportDocument = ExportDocument(data: data, filename: filename, format: format)
            Haptics.success()
        } catch {
            exportError = error.localizedDescription
        }
    }

    func prepareDeckExport(deck: Deck, format: ExportFormat) {
        let backup = exportService.makeBackup(deck: deck)
        do {
            let data: Data
            switch format {
            case .json:
                data = try exportService.exportJSON(backup: backup)
            case .sqlite:
                data = exportService.exportSQLiteSQL(backup: backup)
            }
            let safeName = deck.name
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: " ", with: "_")
            let filename = "hadisak-\(safeName).\(format.fileExtension)"
            exportDocument = ExportDocument(data: data, filename: filename, format: format)
            Haptics.success()
        } catch {
            exportError = error.localizedDescription
        }
    }

    func importFile(
        url: URL,
        into deck: Deck?,
        modelContext: ModelContext
    ) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()

            switch ext {
            case "json":
                let backup = try importService.parseJSONBackup(data)
                try importService.importBackup(backup, modelContext: modelContext)
                statusMessage = String(localized: "import.success.collection")
            case "txt":
                guard let deck else {
                    importError = String(localized: "error.import.needsDeck")
                    return
                }
                let pairs = try importService.parseTXT(data)
                importService.importPairs(pairs, into: deck, modelContext: modelContext)
                statusMessage = String(localized: "import.success.cards \(pairs.count)")
            case "csv":
                guard let deck else {
                    importError = String(localized: "error.import.needsDeck")
                    return
                }
                let pairs = try importService.parseCSV(data)
                importService.importPairs(pairs, into: deck, modelContext: modelContext)
                statusMessage = String(localized: "import.success.cards \(pairs.count)")
            default:
                // Try JSON first, then TXT.
                if let backup = try? importService.parseJSONBackup(data) {
                    try importService.importBackup(backup, modelContext: modelContext)
                    statusMessage = String(localized: "import.success.collection")
                } else if let pairs = try? importService.parseTXT(data), let deck {
                    importService.importPairs(pairs, into: deck, modelContext: modelContext)
                    statusMessage = String(localized: "import.success.cards \(pairs.count)")
                } else {
                    throw ImportError.unsupportedType
                }
            }
            Haptics.success()
        } catch {
            importError = error.localizedDescription
            Haptics.error()
        }
    }
}

/// FileDocument wrapper for the share/export sheet.
struct ExportDocument: Identifiable {
    let id = UUID()
    let data: Data
    let filename: String
    let format: ExportFormat
}

extension UTType {
    static var hadisakSQL: UTType {
        UTType(filenameExtension: "sql") ?? .plainText
    }
}
