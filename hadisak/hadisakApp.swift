//
//  hadisakApp.swift
//  hadisak
//
//  App entry point. Fully offline SwiftData store.
//

import SwiftUI
import SwiftData

@main
struct hadisakApp: App {
    @State private var settings = AppSettings()

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Deck.self,
            Card.self,
            ReviewLog.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .themed(settings.theme)
        }
        .modelContainer(sharedModelContainer)
    }
}
