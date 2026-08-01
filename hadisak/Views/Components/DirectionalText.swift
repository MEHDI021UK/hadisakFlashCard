//
//  DirectionalText.swift
//  hadisak
//
//  Text that auto-aligns based on the dominant script of its content.
//

import SwiftUI

struct DirectionalText: View {
    let text: String
    var font: Font = .title2
    var color: Color = .primary

    private var direction: ContentWritingDirection {
        TextDirectionDetector.detect(in: text)
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(direction.textAlignment)
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: direction.horizontalAlignment, vertical: .center))
            .environment(\.layoutDirection, direction.layoutDirection)
            .accessibilityLabel(text)
    }
}
