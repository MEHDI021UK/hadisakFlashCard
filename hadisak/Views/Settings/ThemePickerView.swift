//
//  ThemePickerView.swift
//  hadisak
//
//  Visual theme grid with live color swatches.
//

import SwiftUI

struct ThemePickerView: View {
    @Binding var selection: AppTheme
    @Environment(\.themePalette) private var palette

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selection = theme
                    }
                    Haptics.selection()
                } label: {
                    themeCard(theme)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: String.LocalizationValue(theme.localizationKey)))
                .accessibilityAddTraits(selection == theme ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        let isSelected = selection == theme
        let colors = theme.previewColors

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                }
            }

            HStack {
                Text(String(localized: String.LocalizationValue(theme.localizationKey)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .imageScale(.medium)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? palette.accent : palette.divider, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? palette.accent.opacity(0.18) : .clear, radius: 8, y: 2)
    }
}
