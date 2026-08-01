//
//  DeckRowView.swift
//  hadisak
//

import SwiftUI

struct DeckRowView: View {
    let deck: Deck

    @Environment(\.themePalette) private var palette

    private var stats: DeckStatistics {
        DeckStatistics.compute(from: deck.cards)
    }

    private var statsIdentity: String {
        deck.cards
            .map { "\($0.id.uuidString):\($0.statusRaw):\($0.dueDate.timeIntervalSince1970):\($0.isSuspended)" }
            .sorted()
            .joined(separator: "|")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(deck.name)
                .font(.headline)
                .foregroundStyle(palette.primaryText)
                .lineLimit(2)

            HStack(spacing: 0) {
                StatBadge(title: String(localized: "deck.stat.total"), value: stats.total, tint: palette.primaryText)
                StatBadge(title: String(localized: "deck.stat.due"), value: stats.due, tint: palette.again)
                StatBadge(title: String(localized: "deck.stat.learning"), value: stats.learning, tint: palette.hard)
                StatBadge(title: String(localized: "deck.stat.new"), value: stats.new, tint: palette.easy)
            }
            .id(statsIdentity)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
