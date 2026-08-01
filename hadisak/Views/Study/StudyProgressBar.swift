//
//  StudyProgressBar.swift
//  hadisak
//

import SwiftUI

struct StudyProgressBar: View {
    let progress: Double
    let remaining: Int
    let reviewed: Int
    let deckName: String

    @Environment(\.themePalette) private var palette

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(deckName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                Spacer()
                Text(String(localized: "study.remaining \(remaining)"))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.secondaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.divider)
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(String(localized: "study.reviewed \(reviewed)"))
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }
}
