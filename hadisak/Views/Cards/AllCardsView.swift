//
//  AllCardsView.swift
//  hadisak
//
//  Browse and edit every card across all decks in one searchable list.
//

import SwiftUI
import SwiftData

struct AllCardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Card.updatedAt, order: .reverse) private var cards: [Card]
    @State private var searchText = ""
    @State private var cardToEdit: Card?

    private var filteredCards: [Card] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return cards }
        return cards.filter {
            $0.front.localizedCaseInsensitiveContains(query)
            || $0.back.localizedCaseInsensitiveContains(query)
            || $0.tagsRaw.localizedCaseInsensitiveContains(query)
            || ($0.deck?.name.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        Group {
            if filteredCards.isEmpty {
                EmptyStateView(
                    title: String(localized: "allCards.empty.title"),
                    systemImage: "rectangle.on.rectangle.angled",
                    message: String(localized: "allCards.empty.message")
                )
            } else {
                List {
                    ForEach(filteredCards) { card in
                        Button {
                            cardToEdit = card
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                if let deckName = card.deck?.name {
                                    Text(deckName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.accent)
                                }
                                CardRowView(card: card)
                            }
                        }
                        .listRowBackground(palette.cardBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteCard(card)
                            } label: {
                                Label(String(localized: "action.delete"), systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(String(localized: "allCards.title"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: String(localized: "allCards.search"))
        .sheet(item: $cardToEdit) { card in
            if let deck = card.deck {
                CardEditorView(deck: deck, card: card)
                    .themed(settings.theme)
            }
        }
    }

    private func deleteCard(_ card: Card) {
        let deck = card.deck
        modelContext.delete(card)
        deck?.updatedAt = .now
        try? modelContext.save()
        Haptics.warning()
    }
}
