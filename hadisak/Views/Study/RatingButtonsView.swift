//
//  RatingButtonsView.swift
//  hadisak
//

import SwiftUI

struct RatingButtonsView: View {
    let previews: [ReviewRating: String]
    var onRate: (ReviewRating) -> Void

    @Environment(\.themePalette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ReviewRating.allCases) { rating in
                Button {
                    onRate(rating)
                } label: {
                    VStack(spacing: 4) {
                        Text(String(localized: String.LocalizationValue(rating.localizationKey)))
                            .font(.subheadline.weight(.semibold))
                        Text(previews[rating] ?? "—")
                            .font(.caption2.monospacedDigit())
                            .opacity(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(palette.color(for: rating), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: String.LocalizationValue(rating.accessibilityKey)))
                .accessibilityValue(previews[rating] ?? "")
            }
        }
    }
}
