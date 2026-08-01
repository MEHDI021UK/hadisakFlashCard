//
//  DeckDetailView.swift
//  hadisak
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DeckDetailView: View {
    @Bindable var deck: Deck

    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette
    @Environment(AppSettings.self) private var settings

    @State private var showAddCard = false
    @State private var showPasteContent = false
    @State private var cardToEdit: Card?
    @State private var showStudyOptions = false
    @State private var studyRoute: StudySessionRoute?
    @State private var searchText = ""
    @State private var showImporter = false
    @State private var settingsVM: SettingsViewModel?
    @State private var showExportFormat = false
    @State private var alertMessage: String?

    /// Live stats from current card properties (recomputed every render).
    private var stats: DeckStatistics {
        DeckStatistics.compute(from: deck.cards)
    }

    private var filteredCards: [Card] {
        let sorted = deck.cards.sorted { $0.createdAt > $1.createdAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.front.localizedCaseInsensitiveContains(query)
            || $0.back.localizedCaseInsensitiveContains(query)
            || $0.tagsRaw.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    StatBadge(title: String(localized: "deck.stat.total"), value: stats.total, tint: palette.primaryText)
                    StatBadge(title: String(localized: "deck.stat.due"), value: stats.due, tint: palette.again)
                    StatBadge(title: String(localized: "deck.stat.learning"), value: stats.learning, tint: palette.hard)
                    StatBadge(title: String(localized: "deck.stat.new"), value: stats.new, tint: palette.easy)
                }
                .padding(.vertical, 4)
                .listRowBackground(palette.cardBackground)
                // Touch card fields so SwiftUI refreshes when scheduling changes.
                .id(statsIdentity)

                Button {
                    openStudy()
                } label: {
                    Label {
                        Text(String(localized: "study.start"))
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
                .tint(palette.accent)
                .listRowBackground(palette.cardBackground)
            }

            Section {
                if filteredCards.isEmpty {
                    Text(String(localized: "cards.empty"))
                        .foregroundStyle(palette.secondaryText)
                        .listRowBackground(palette.cardBackground)
                } else {
                    ForEach(filteredCards) { card in
                        Button {
                            cardToEdit = card
                        } label: {
                            CardRowView(card: card)
                        }
                        .listRowBackground(palette.cardBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteCard(card)
                            } label: {
                                Label(String(localized: "action.delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "cards.section.title"))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: String(localized: "cards.search"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showPasteContent = true
                    } label: {
                        Label(String(localized: "content.add"), systemImage: "doc.text")
                    }
                    Button {
                        showAddCard = true
                    } label: {
                        Label(String(localized: "card.add"), systemImage: "plus")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label(String(localized: "import.cards"), systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showExportFormat = true
                    } label: {
                        Label(String(localized: "export.deck"), systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPasteContent) {
            PasteContentView(deck: deck)
                .themed(settings.theme)
        }
        .sheet(isPresented: $showAddCard) {
            CardEditorView(deck: deck)
                .themed(settings.theme)
        }
        .sheet(item: $cardToEdit) { card in
            CardEditorView(deck: deck, card: card)
                .themed(settings.theme)
        }
        .confirmationDialog(
            String(localized: "study.options.title"),
            isPresented: $showStudyOptions,
            titleVisibility: .visible
        ) {
            Button(String(localized: "study.direction.normal")) {
                startStudy(direction: .normal)
            }
            Button(String(localized: "study.direction.reverse")) {
                startStudy(direction: .reverse)
            }
            Button(String(localized: "action.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "study.options.message \(stats.studyable)"))
        }
        .navigationDestination(item: $studyRoute) { route in
            StudySessionView(deck: deck, direction: route.direction)
                .onDisappear {
                    // Always clear so the next Study Now can push again.
                    studyRoute = nil
                    deck.updatedAt = .now
                }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.plainText, .commaSeparatedText, .json, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .confirmationDialog(
            String(localized: "export.format.title"),
            isPresented: $showExportFormat,
            titleVisibility: .visible
        ) {
            Button(String(localized: "export.format.json")) {
                exportDeck(.json)
            }
            Button(String(localized: "export.format.sqlite")) {
                exportDeck(.sqlite)
            }
            Button(String(localized: "action.cancel"), role: .cancel) {}
        }
        .sheet(item: Binding(
            get: { settingsVM?.exportDocument },
            set: { settingsVM?.exportDocument = $0 }
        )) { document in
            ShareSheet(items: [TemporaryFile(data: document.data, filename: document.filename).url].compactMap { $0 })
        }
        .alert(
            String(localized: "alert.title"),
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { dismissNotice() } }
            )
        ) {
            Button(String(localized: "action.ok"), role: .cancel) {
                dismissNotice()
            }
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear {
            if settingsVM == nil {
                settingsVM = SettingsViewModel(settings: settings)
            }
            // Returning from study / sheets — make sure nav flag is clear.
            if studyRoute != nil {
                studyRoute = nil
            }
        }
    }

    /// Fingerprint of scheduling fields so badges refresh after reviews.
    private var statsIdentity: String {
        deck.cards
            .map { "\($0.id.uuidString):\($0.statusRaw):\($0.dueDate.timeIntervalSince1970):\($0.isSuspended)" }
            .sorted()
            .joined(separator: "|")
    }

    private func openStudy() {
        // Reset any leftover navigation / alert state first.
        studyRoute = nil
        alertMessage = nil

        let current = DeckStatistics.compute(from: deck.cards)
        guard current.studyable > 0 else {
            alertMessage = String(localized: "study.noCards")
            return
        }
        showStudyOptions = true
    }

    private func dismissNotice() {
        alertMessage = nil
        studyRoute = nil
    }

    private func startStudy(direction: StudyDirection) {
        studyRoute = nil
        // Assign on next run-loop turn so a cleared nil → new value always triggers navigation.
        DispatchQueue.main.async {
            studyRoute = StudySessionRoute(direction: direction)
        }
    }

    private func deleteCard(_ card: Card) {
        modelContext.delete(card)
        deck.updatedAt = .now
        try? modelContext.save()
        Haptics.warning()
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard let vm = settingsVM else { return }
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            vm.importFile(url: url, into: deck, modelContext: modelContext)
            if let error = vm.importError {
                alertMessage = error
                vm.importError = nil
            } else if let status = vm.statusMessage {
                alertMessage = status
                vm.statusMessage = nil
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
    }

    private func exportDeck(_ format: ExportFormat) {
        settingsVM?.prepareDeckExport(deck: deck, format: format)
        if let error = settingsVM?.exportError {
            alertMessage = error
            settingsVM?.exportError = nil
        }
    }
}

// MARK: - Study navigation

/// Unique route so Study Now can push a new session after the previous one is dismissed.
struct StudySessionRoute: Hashable, Identifiable {
    let id: UUID
    let direction: StudyDirection

    init(direction: StudyDirection) {
        self.id = UUID()
        self.direction = direction
    }
}

// MARK: - Share helpers

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TemporaryFile {
    let url: URL?

    init(data: Data, filename: String) {
        let dir = FileManager.default.temporaryDirectory
        let fileURL = dir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            url = fileURL
        } catch {
            url = nil
        }
    }
}
