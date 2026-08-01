//
//  ContentView.swift
//  hadisak
//
//  Root navigation: Decks + Settings tabs with theme and locale applied.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.themePalette) private var palette

    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label(String(localized: "tab.decks"), systemImage: "rectangle.stack.fill")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "tab.settings"), systemImage: "gearshape.fill")
                }
        }
        .themed(settings.theme)
        .environment(\.locale, resolvedLocale)
        .environment(\.layoutDirection, resolvedLayoutDirection)
    }

    private var resolvedLocale: Locale {
        settings.language.locale ?? .autoupdatingCurrent
    }

    private var resolvedLayoutDirection: LayoutDirection {
        if let direction = settings.language.layoutDirection {
            return direction
        }
        return Locale.current.language.characterDirection == .rightToLeft
            ? .rightToLeft
            : .leftToRight
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
