//
//  StatBadge.swift
//  hadisak
//

import SwiftUI

struct StatBadge: View {
    let title: String
    let value: Int
    var tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
