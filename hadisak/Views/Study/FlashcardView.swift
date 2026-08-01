//
//  FlashcardView.swift
//  hadisak
//
//  Flip-style flashcard with content-aware text direction.
//

import SwiftUI

struct FlashcardView: View {
    let prompt: String
    let answer: String
    let isRevealed: Bool
    var onReveal: () -> Void

    @Environment(\.themePalette) private var palette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

            VStack(spacing: 20) {
                Text(isRevealed
                     ? String(localized: "study.side.answer")
                     : String(localized: "study.side.question"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.2)

                DirectionalText(
                    text: isRevealed ? answer : prompt,
                    font: .title.weight(.medium),
                    color: palette.primaryText
                )
                .id(isRevealed ? "answer" : "prompt")
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

                if !isRevealed {
                    Text(String(localized: "study.tapToReveal"))
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryText)
                        .padding(.top, 8)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRevealed {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    onReveal()
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if !isRevealed, abs(value.translation.width) > 40 || value.translation.height < -40 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            onReveal()
                        }
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isRevealed
            ? String(localized: "study.a11y.answerShown")
            : String(localized: "study.a11y.tapToReveal"))
        .accessibilityElement(children: .combine)
    }
}
