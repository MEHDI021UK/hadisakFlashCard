//
//  CardEditorViewModel.swift
//  hadisak
//
//  Create and edit flashcards within a deck.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class CardEditorViewModel {
    var front: String
    var back: String
    var tagsText: String
    var errorMessage: String?

    private let deck: Deck
    private let existingCard: Card?
    private let modelContext: ModelContext

    var isEditing: Bool { existingCard != nil }

    init(deck: Deck, card: Card? = nil, modelContext: ModelContext) {
        self.deck = deck
        self.existingCard = card
        self.modelContext = modelContext
        self.front = card?.front ?? ""
        self.back = card?.back ?? ""
        self.tagsText = card?.tags.joined(separator: ", ") ?? ""
    }

    @discardableResult
    func save() -> Bool {
        let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else {
            errorMessage = String(localized: "error.card.emptySides")
            return false
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let existingCard {
            existingCard.front = trimmedFront
            existingCard.back = trimmedBack
            existingCard.tags = tags
            existingCard.updatedAt = .now
        } else {
            let card = Card(
                front: trimmedFront,
                back: trimmedBack,
                tags: tags,
                deck: deck
            )
            modelContext.insert(card)
            deck.updatedAt = .now
        }

        do {
            try modelContext.save()
            Haptics.success()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func delete() -> Bool {
        guard let existingCard else { return false }
        let parentDeck = existingCard.deck ?? deck
        modelContext.delete(existingCard)
        parentDeck.updatedAt = .now
        do {
            try modelContext.save()
            Haptics.warning()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
