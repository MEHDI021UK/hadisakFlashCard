//
//  SettingsView.swift
//  hadisak
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Deck.name) private var decks: [Deck]

    @State private var viewModel: SettingsViewModel?
    @State private var showImporter = false
    @State private var showExportFormat = false
    @State private var alertMessage: String?
    @State private var selectedImportDeck: Deck?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                studySection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle(String(localized: "settings.title"))
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(settings: settings)
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json, .plainText, .commaSeparatedText, .data],
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
                    viewModel?.prepareExport(decks: decks, format: .json)
                }
                Button(String(localized: "export.format.sqlite")) {
                    viewModel?.prepareExport(decks: decks, format: .sqlite)
                }
                Button(String(localized: "action.cancel"), role: .cancel) {}
            }
            .sheet(item: Binding(
                get: { viewModel?.exportDocument },
                set: { viewModel?.exportDocument = $0 }
            )) { document in
                ShareSheet(items: [TemporaryFile(data: document.data, filename: document.filename).url].compactMap { $0 })
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
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section {
            ThemePickerView(selection: Bindable(settings).theme)
                .listRowBackground(palette.secondaryBackground)
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))

            Picker(String(localized: "settings.language"), selection: Bindable(settings).language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(String(localized: String.LocalizationValue(language.localizationKey)))
                        .tag(language)
                }
            }
            .listRowBackground(palette.cardBackground)
        } header: {
            Text(String(localized: "settings.section.appearance"))
        } footer: {
            Text(String(localized: "settings.theme.footer"))
        }
    }

    private var studySection: some View {
        Section {
            Stepper(
                value: Bindable(settings).dailyNewCardLimit,
                in: 1...200
            ) {
                HStack {
                    Text(String(localized: "settings.newCardLimit"))
                    Spacer()
                    Text("\(settings.dailyNewCardLimit)")
                        .foregroundStyle(palette.secondaryText)
                        .monospacedDigit()
                }
            }
            .listRowBackground(palette.cardBackground)

            Toggle(String(localized: "settings.reverseMode"), isOn: Bindable(settings).reverseMode)
                .listRowBackground(palette.cardBackground)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "settings.learningSteps"))
                TextField("1, 10", text: Binding(
                    get: { viewModel?.learningStepsText ?? "1, 10" },
                    set: { viewModel?.learningStepsText = $0 }
                ))
                .textInputAutocapitalization(.never)
                .keyboardType(.numbersAndPunctuation)
                .onSubmit {
                    viewModel?.applyLearningSteps()
                }
                Button(String(localized: "settings.learningSteps.apply")) {
                    viewModel?.applyLearningSteps()
                }
                .font(.footnote.weight(.semibold))
            }
            .listRowBackground(palette.cardBackground)
        } header: {
            Text(String(localized: "settings.section.study"))
        } footer: {
            Text(String(localized: "settings.learningSteps.footer"))
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                showExportFormat = true
            } label: {
                Label(String(localized: "settings.exportCollection"), systemImage: "square.and.arrow.up")
            }
            .listRowBackground(palette.cardBackground)

            Button {
                if decks.count == 1 {
                    selectedImportDeck = decks.first
                    showImporter = true
                } else if decks.isEmpty {
                    alertMessage = String(localized: "error.import.needsDeck")
                } else {
                    // Import JSON collection doesn't need a deck; TXT/CSV does.
                    selectedImportDeck = decks.first
                    showImporter = true
                }
            } label: {
                Label(String(localized: "settings.importCollection"), systemImage: "square.and.arrow.down")
            }
            .listRowBackground(palette.cardBackground)
        } header: {
            Text(String(localized: "settings.section.data"))
        } footer: {
            Text(String(localized: "settings.data.footer"))
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent(String(localized: "settings.version"), value: settings.appVersion)
                .listRowBackground(palette.cardBackground)

            Text(String(localized: "settings.about.body"))
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)
                .listRowBackground(palette.cardBackground)
        } header: {
            Text(String(localized: "settings.section.about"))
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard let viewModel else { return }
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            viewModel.importFile(url: url, into: selectedImportDeck, modelContext: modelContext)
            if let error = viewModel.importError {
                alertMessage = error
                viewModel.importError = nil
            } else if let status = viewModel.statusMessage {
                alertMessage = status
                viewModel.statusMessage = nil
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
        }
    }
}
