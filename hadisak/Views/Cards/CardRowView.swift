//
//  CardRowView.swift
//  hadisak
//

import SwiftUI

struct CardRowView: View {
    let card: Card

    @Environment(\.themePalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            DirectionalText(text: card.front, font: .body.weight(.medium), color: palette.primaryText)
                .lineLimit(2)

            DirectionalText(text: card.back, font: .subheadline, color: palette.secondaryText)
                .lineLimit(2)

            HStack(spacing: 8) {
                statusChip
                if !card.tags.isEmpty {
                    Text(card.tags.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                if card.isSuspended {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(palette.secondaryText)
                        .accessibilityLabel(String(localized: "card.suspended"))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusChip: some View {
        Text(statusLabel)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var statusLabel: String {
        switch card.status {
        case .new: String(localized: "card.status.new")
        case .learning: String(localized: "card.status.learning")
        case .review: String(localized: "card.status.review")
        case .relearning: String(localized: "card.status.relearning")
        case .suspended: String(localized: "card.status.suspended")
        }
    }

    private var statusColor: Color {
        switch card.status {
        case .new: palette.easy
        case .learning, .relearning: palette.hard
        case .review: palette.good
        case .suspended: palette.secondaryText
        }
    }
}
