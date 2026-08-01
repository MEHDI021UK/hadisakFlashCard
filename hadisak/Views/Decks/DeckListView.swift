//
//  DeckListView.swift
//  hadisak
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Deck.updatedAt, order: .reverse) private var decks: [Deck]
    @State private var viewModel: DeckListViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var showBackupImporter = false
    @State private var alertMessage: String?

    private enum DeckListRoute: Hashable {
        case allCards
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    deckContent(viewModel)
                } else {
                    ProgressView()
                }
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle(String(localized: "decks.title"))
            .searchable(
                text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ),
                prompt: String(localized: "decks.search")
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showBackupImporter = true
                        } label: {
                            Label(String(localized: "decks.importBackup"), systemImage: "square.and.arrow.down")
                        }
                        NavigationLink(value: DeckListRoute.allCards) {
                            Label(String(localized: "allCards.title"), systemImage: "list.bullet.rectangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(String(localized: "decks.more"))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel?.deckNameDraft = ""
                        viewModel?.showCreateSheet = true
                    } label: {
                        Label(String(localized: "deck.create"), systemImage: "plus")
                    }
                    .accessibilityLabel(String(localized: "deck.create"))
                }
            }
            .navigationDestination(for: DeckListRoute.self) { route in
                switch route {
                case .allCards:
                    AllCardsView()
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showCreateSheet ?? false },
                set: { viewModel?.showCreateSheet = $0 }
            )) {
                DeckFormView(
                    title: String(localized: "deck.create"),
                    name: Binding(
                        get: { viewModel?.deckNameDraft ?? "" },
                        set: { viewModel?.deckNameDraft = $0 }
                    ),
                    onSave: {
                        viewModel?.createDeck(named: viewModel?.deckNameDraft ?? "")
                    },
                    onCancel: {
                        viewModel?.showCreateSheet = false
                    }
                )
                .presentationDetents([.medium])
                .themed(settings.theme)
            }
            .sheet(item: Binding(
                get: { viewModel?.deckPendingRename },
                set: { viewModel?.deckPendingRename = $0 }
            )) { deck in
                DeckFormView(
                    title: String(localized: "deck.rename"),
                    name: Binding(
                        get: { viewModel?.deckNameDraft ?? deck.name },
                        set: { viewModel?.deckNameDraft = $0 }
                    ),
                    onSave: {
                        viewModel?.renameDeck(deck, to: viewModel?.deckNameDraft ?? deck.name)
                    },
                    onCancel: {
                        viewModel?.deckPendingRename = nil
                    }
                )
                .presentationDetents([.medium])
                .themed(settings.theme)
            }
            .fileImporter(
                isPresented: $showBackupImporter,
                allowedContentTypes: [.json, .data, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleBackupImport(result)
            }
            .alert(
                String(localized: "alert.title"),
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                Button(String(localized: "action.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DeckListViewModel(modelContext: modelContext)
            }
            if settingsVM == nil {
                settingsVM = SettingsViewModel(settings: settings)
            }
        }
    }

    @ViewBuilder
    private func deckContent(_ viewModel: DeckListViewModel) -> some View {
        let filtered = viewModel.filteredDecks(from: decks)
        List {
            Section {
                NavigationLink(value: DeckListRoute.allCards) {
                    Label(String(localized: "allCards.title"), systemImage: "list.bullet.rectangle")
                        .font(.body.weight(.medium))
                }
                .listRowBackground(palette.cardBackground)
            }

            Section {
                if filtered.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "decks.empty.title"))
                            .font(.headline)
                            .foregroundStyle(palette.primaryText)
                        Text(String(localized: "decks.empty.message"))
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryText)
                        Button(String(localized: "deck.create")) {
                            viewModel.deckNameDraft = ""
                            viewModel.showCreateSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(palette.accent)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(palette.cardBackground)
                } else {
                    ForEach(filtered) { deck in
                        NavigationLink(value: deck.id) {
                            DeckRowView(deck: deck)
                        }
                        .listRowBackground(palette.cardBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteDeck(deck)
                            } label: {
                                Label(String(localized: "action.delete"), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.deckNameDraft = deck.name
                                viewModel.deckPendingRename = deck
                            } label: {
                                Label(String(localized: "deck.rename"), systemImage: "pencil")
                            }
                            .tint(palette.accent)

                            Button {
                                viewModel.duplicateDeck(deck)
                            } label: {
                                Label(String(localized: "deck.duplicate"), systemImage: "plus.square.on.square")
                            }
                            .tint(palette.good)
                        }
                        .contextMenu {
                            Button {
                                viewModel.deckNameDraft = deck.name
                                viewModel.deckPendingRename = deck
                            } label: {
                                Label(String(localized: "deck.rename"), systemImage: "pencil")
                            }
                            Button {
                                viewModel.duplicateDeck(deck)
                            } label: {
                                Label(String(localized: "deck.duplicate"), systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                viewModel.deleteDeck(deck)
                            } label: {
                                Label(String(localized: "action.delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "decks.section.title"))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: UUID.self) { deckID in
            if let deck = decks.first(where: { $0.id == deckID }) {
                DeckDetailView(deck: deck)
            } else {
                EmptyStateView(
                    title: String(localized: "decks.empty.title"),
                    systemImage: "rectangle.stack"
                )
            }
        }
    }

    private func handleBackupImport(_ result: Result<[URL], Error>) {
        guard let settingsVM else { return }
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            settingsVM.importFile(url: url, into: nil, modelContext: modelContext)
            if let error = settingsVM.importError {
                alertMessage = error
                settingsVM.importError = nil
            } else if let status = settingsVM.statusMessage {
                alertMessage = status
                settingsVM.statusMessage = nil
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
    }
}
