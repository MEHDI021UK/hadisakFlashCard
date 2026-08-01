//
//  AppTheme.swift
//  hadisak
//
//  Built-in visual themes with smooth animated switching.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case light
    case dark
    case coffee
    case ocean
    case forest
    case midnight
    case sakura
    case matcha
    case ember
    case slate

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .light: "theme.light"
        case .dark: "theme.dark"
        case .coffee: "theme.coffee"
        case .ocean: "theme.ocean"
        case .forest: "theme.forest"
        case .midnight: "theme.midnight"
        case .sakura: "theme.sakura"
        case .matcha: "theme.matcha"
        case .ember: "theme.ember"
        case .slate: "theme.slate"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light, .coffee, .ocean, .forest, .sakura, .matcha:
            .light
        case .dark, .midnight, .ember, .slate:
            .dark
        }
    }

    /// Small preview chips for the settings picker.
    var previewColors: [Color] {
        let p = palette
        return [p.background, p.cardBackground, p.accent, p.good]
    }

    var palette: ThemePalette {
        switch self {
        case .light:
            ThemePalette(
                background: Color(red: 0.96, green: 0.97, blue: 0.98),
                secondaryBackground: Color(red: 1.0, green: 1.0, blue: 1.0),
                cardBackground: Color.white,
                primaryText: Color(red: 0.11, green: 0.13, blue: 0.16),
                secondaryText: Color(red: 0.45, green: 0.48, blue: 0.52),
                accent: Color(red: 0.15, green: 0.45, blue: 0.78),
                again: Color(red: 0.86, green: 0.24, blue: 0.24),
                hard: Color(red: 0.90, green: 0.55, blue: 0.12),
                good: Color(red: 0.18, green: 0.62, blue: 0.36),
                easy: Color(red: 0.20, green: 0.48, blue: 0.82),
                divider: Color.black.opacity(0.08),
                navigationBar: Color(red: 0.96, green: 0.97, blue: 0.98)
            )

        case .dark:
            ThemePalette(
                background: Color(red: 0.07, green: 0.08, blue: 0.10),
                secondaryBackground: Color(red: 0.12, green: 0.13, blue: 0.16),
                cardBackground: Color(red: 0.14, green: 0.16, blue: 0.19),
                primaryText: Color(red: 0.95, green: 0.96, blue: 0.97),
                secondaryText: Color(red: 0.65, green: 0.68, blue: 0.72),
                accent: Color(red: 0.40, green: 0.68, blue: 0.98),
                again: Color(red: 0.95, green: 0.40, blue: 0.40),
                hard: Color(red: 0.98, green: 0.70, blue: 0.30),
                good: Color(red: 0.35, green: 0.80, blue: 0.52),
                easy: Color(red: 0.45, green: 0.70, blue: 0.98),
                divider: Color.white.opacity(0.12),
                navigationBar: Color(red: 0.07, green: 0.08, blue: 0.10)
            )

        case .coffee:
            ThemePalette(
                background: Color(red: 0.96, green: 0.93, blue: 0.88),
                secondaryBackground: Color(red: 0.93, green: 0.88, blue: 0.80),
                cardBackground: Color(red: 0.99, green: 0.97, blue: 0.93),
                primaryText: Color(red: 0.28, green: 0.18, blue: 0.10),
                secondaryText: Color(red: 0.52, green: 0.40, blue: 0.28),
                accent: Color(red: 0.55, green: 0.33, blue: 0.18),
                again: Color(red: 0.72, green: 0.28, blue: 0.18),
                hard: Color(red: 0.78, green: 0.48, blue: 0.18),
                good: Color(red: 0.42, green: 0.52, blue: 0.28),
                easy: Color(red: 0.45, green: 0.35, blue: 0.22),
                divider: Color(red: 0.55, green: 0.33, blue: 0.18).opacity(0.18),
                navigationBar: Color(red: 0.96, green: 0.93, blue: 0.88)
            )

        case .ocean:
            // Coastal calm — misty aqua surfaces, deep teal accent.
            ThemePalette(
                background: Color(red: 0.90, green: 0.95, blue: 0.97),
                secondaryBackground: Color(red: 0.84, green: 0.92, blue: 0.95),
                cardBackground: Color(red: 0.97, green: 0.99, blue: 1.0),
                primaryText: Color(red: 0.08, green: 0.22, blue: 0.30),
                secondaryText: Color(red: 0.30, green: 0.48, blue: 0.55),
                accent: Color(red: 0.05, green: 0.52, blue: 0.58),
                again: Color(red: 0.82, green: 0.28, blue: 0.32),
                hard: Color(red: 0.88, green: 0.55, blue: 0.18),
                good: Color(red: 0.12, green: 0.62, blue: 0.52),
                easy: Color(red: 0.18, green: 0.48, blue: 0.72),
                divider: Color(red: 0.05, green: 0.52, blue: 0.58).opacity(0.16),
                navigationBar: Color(red: 0.90, green: 0.95, blue: 0.97)
            )

        case .forest:
            // Moss & fern — soft sage paper with evergreen accent.
            ThemePalette(
                background: Color(red: 0.93, green: 0.95, blue: 0.90),
                secondaryBackground: Color(red: 0.88, green: 0.92, blue: 0.84),
                cardBackground: Color(red: 0.98, green: 0.99, blue: 0.96),
                primaryText: Color(red: 0.14, green: 0.22, blue: 0.14),
                secondaryText: Color(red: 0.38, green: 0.48, blue: 0.36),
                accent: Color(red: 0.22, green: 0.48, blue: 0.32),
                again: Color(red: 0.78, green: 0.30, blue: 0.24),
                hard: Color(red: 0.80, green: 0.55, blue: 0.18),
                good: Color(red: 0.28, green: 0.58, blue: 0.34),
                easy: Color(red: 0.25, green: 0.45, blue: 0.42),
                divider: Color(red: 0.22, green: 0.48, blue: 0.32).opacity(0.16),
                navigationBar: Color(red: 0.93, green: 0.95, blue: 0.90)
            )

        case .midnight:
            // Deep night sky — navy canvas with soft cyan highlights.
            ThemePalette(
                background: Color(red: 0.05, green: 0.07, blue: 0.14),
                secondaryBackground: Color(red: 0.09, green: 0.12, blue: 0.22),
                cardBackground: Color(red: 0.11, green: 0.15, blue: 0.26),
                primaryText: Color(red: 0.90, green: 0.93, blue: 0.98),
                secondaryText: Color(red: 0.58, green: 0.66, blue: 0.78),
                accent: Color(red: 0.35, green: 0.72, blue: 0.92),
                again: Color(red: 0.95, green: 0.42, blue: 0.48),
                hard: Color(red: 0.95, green: 0.72, blue: 0.35),
                good: Color(red: 0.40, green: 0.82, blue: 0.68),
                easy: Color(red: 0.45, green: 0.68, blue: 0.98),
                divider: Color.white.opacity(0.10),
                navigationBar: Color(red: 0.05, green: 0.07, blue: 0.14)
            )

        case .sakura:
            // Soft petal wash — blush surfaces, rose accent.
            ThemePalette(
                background: Color(red: 0.98, green: 0.94, blue: 0.95),
                secondaryBackground: Color(red: 0.96, green: 0.90, blue: 0.92),
                cardBackground: Color(red: 1.0, green: 0.98, blue: 0.99),
                primaryText: Color(red: 0.28, green: 0.14, blue: 0.20),
                secondaryText: Color(red: 0.58, green: 0.40, blue: 0.46),
                accent: Color(red: 0.78, green: 0.32, blue: 0.48),
                again: Color(red: 0.82, green: 0.22, blue: 0.30),
                hard: Color(red: 0.88, green: 0.52, blue: 0.28),
                good: Color(red: 0.42, green: 0.62, blue: 0.42),
                easy: Color(red: 0.55, green: 0.40, blue: 0.68),
                divider: Color(red: 0.78, green: 0.32, blue: 0.48).opacity(0.16),
                navigationBar: Color(red: 0.98, green: 0.94, blue: 0.95)
            )

        case .matcha:
            // Quiet tea room — pale matcha paper, muted leaf accent.
            ThemePalette(
                background: Color(red: 0.95, green: 0.96, blue: 0.91),
                secondaryBackground: Color(red: 0.90, green: 0.93, blue: 0.84),
                cardBackground: Color(red: 0.99, green: 0.99, blue: 0.96),
                primaryText: Color(red: 0.18, green: 0.24, blue: 0.16),
                secondaryText: Color(red: 0.42, green: 0.50, blue: 0.38),
                accent: Color(red: 0.42, green: 0.55, blue: 0.28),
                again: Color(red: 0.76, green: 0.32, blue: 0.26),
                hard: Color(red: 0.82, green: 0.58, blue: 0.22),
                good: Color(red: 0.36, green: 0.60, blue: 0.36),
                easy: Color(red: 0.32, green: 0.50, blue: 0.48),
                divider: Color(red: 0.42, green: 0.55, blue: 0.28).opacity(0.16),
                navigationBar: Color(red: 0.95, green: 0.96, blue: 0.91)
            )

        case .ember:
            // Warm hearth night — charcoal with amber glow.
            ThemePalette(
                background: Color(red: 0.10, green: 0.08, blue: 0.07),
                secondaryBackground: Color(red: 0.16, green: 0.12, blue: 0.10),
                cardBackground: Color(red: 0.18, green: 0.14, blue: 0.12),
                primaryText: Color(red: 0.98, green: 0.94, blue: 0.88),
                secondaryText: Color(red: 0.72, green: 0.62, blue: 0.52),
                accent: Color(red: 0.92, green: 0.55, blue: 0.22),
                again: Color(red: 0.92, green: 0.35, blue: 0.28),
                hard: Color(red: 0.95, green: 0.68, blue: 0.28),
                good: Color(red: 0.48, green: 0.72, blue: 0.40),
                easy: Color(red: 0.85, green: 0.58, blue: 0.35),
                divider: Color.white.opacity(0.10),
                navigationBar: Color(red: 0.10, green: 0.08, blue: 0.07)
            )

        case .slate:
            // Cool stone — graphite surfaces, steel-blue accent.
            ThemePalette(
                background: Color(red: 0.12, green: 0.14, blue: 0.16),
                secondaryBackground: Color(red: 0.16, green: 0.18, blue: 0.21),
                cardBackground: Color(red: 0.19, green: 0.21, blue: 0.24),
                primaryText: Color(red: 0.93, green: 0.94, blue: 0.95),
                secondaryText: Color(red: 0.62, green: 0.66, blue: 0.70),
                accent: Color(red: 0.48, green: 0.66, blue: 0.78),
                again: Color(red: 0.90, green: 0.42, blue: 0.42),
                hard: Color(red: 0.92, green: 0.68, blue: 0.32),
                good: Color(red: 0.42, green: 0.74, blue: 0.58),
                easy: Color(red: 0.52, green: 0.70, blue: 0.88),
                divider: Color.white.opacity(0.11),
                navigationBar: Color(red: 0.12, green: 0.14, blue: 0.16)
            )
        }
    }
}

struct ThemePalette: Equatable {
    var background: Color
    var secondaryBackground: Color
    var cardBackground: Color
    var primaryText: Color
    var secondaryText: Color
    var accent: Color
    var again: Color
    var hard: Color
    var good: Color
    var easy: Color
    var divider: Color
    var navigationBar: Color

    func color(for rating: ReviewRating) -> Color {
        switch rating {
        case .again: again
        case .hard: hard
        case .good: good
        case .easy: easy
        }
    }
}

// MARK: - Environment

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = AppTheme.light.palette
}

extension EnvironmentValues {
    var themePalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

extension View {
    func themed(_ theme: AppTheme) -> some View {
        self
            .environment(\.themePalette, theme.palette)
            .preferredColorScheme(theme.preferredColorScheme)
            .tint(theme.palette.accent)
            .animation(.easeInOut(duration: 0.35), value: theme)
    }
}
