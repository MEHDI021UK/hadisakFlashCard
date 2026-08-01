//
//  DeckListViewModel.swift
//  hadisak
//
//  Deck CRUD, search, and duplication.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class DeckListViewModel {
    var searchText: String = ""
    var errorMessage: String?
    var showCreateSheet: Bool = false
    var deckPendingRename: Deck?
    var deckNameDraft: String = ""

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func filteredDecks(from decks: [Deck]) -> [Deck] {
        let sorted = decks.sorted { $0.updatedAt > $1.updatedAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func createDeck(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let deck = Deck(name: trimmed)
        modelContext.insert(deck)
        save()
        Haptics.success()
        showCreateSheet = false
        deckNameDraft = ""
    }

    func renameDeck(_ deck: Deck, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        deck.name = trimmed
        deck.updatedAt = .now
        save()
        deckPendingRename = nil
        deckNameDraft = ""
        Haptics.selection()
    }

    func deleteDeck(_ deck: Deck) {
        modelContext.delete(deck)
        save()
        Haptics.warning()
    }

    func duplicateDeck(_ deck: Deck) {
        let copy = Deck(name: String(localized: "deck.copyName \(deck.name)"))
        modelContext.insert(copy)
        for card in deck.cards {
            let duplicated = Card(
                front: card.front,
                back: card.back,
                tags: card.tags,
                easeFactor: 2.5,
                interval: 0,
                repetitions: 0,
                dueDate: .now,
                lapses: 0,
                status: .new,
                learningStep: 0,
                cardType: card.cardType,
                deck: copy
            )
            modelContext.insert(duplicated)
        }
        save()
        Haptics.success()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
