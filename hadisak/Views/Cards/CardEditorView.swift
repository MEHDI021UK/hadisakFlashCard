//
//  CardEditorView.swift
//  hadisak
//

import SwiftUI
import SwiftData

struct CardEditorView: View {
    let deck: Deck
    var card: Card? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette

    @State private var viewModel: CardEditorViewModel?
    @State private var showDeleteConfirm = false
    @FocusState private var focus: Field?

    private enum Field {
        case front, back, tags
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "card.front"))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                        TextField(String(localized: "card.front.placeholder"), text: frontBinding, axis: .vertical)
                            .focused($focus, equals: .front)
                            .lineLimit(3...8)
                            .environment(\.layoutDirection, TextDirectionDetector.detect(in: frontBinding.wrappedValue).layoutDirection)
                    }
                    .listRowBackground(palette.cardBackground)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "card.back"))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                        TextField(String(localized: "card.back.placeholder"), text: backBinding, axis: .vertical)
                            .focused($focus, equals: .back)
                            .lineLimit(3...8)
                            .environment(\.layoutDirection, TextDirectionDetector.detect(in: backBinding.wrappedValue).layoutDirection)
                    }
                    .listRowBackground(palette.cardBackground)
                }

                Section {
                    TextField(String(localized: "card.tags.placeholder"), text: tagsBinding)
                        .focused($focus, equals: .tags)
                        .listRowBackground(palette.cardBackground)
                } header: {
                    Text(String(localized: "card.tags"))
                } footer: {
                    Text(String(localized: "card.tags.footer"))
                }

                if card != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label(String(localized: "card.delete"), systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(palette.cardBackground)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle(card == nil ? String(localized: "card.add") : String(localized: "card.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save")) {
                        if viewModel?.save() == true {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(
                String(localized: "alert.title"),
                isPresented: Binding(
                    get: { viewModel?.errorMessage != nil },
                    set: { if !$0 { viewModel?.errorMessage = nil } }
                )
            ) {
                Button(String(localized: "action.ok"), role: .cancel) {}
            } message: {
                Text(viewModel?.errorMessage ?? "")
            }
            .confirmationDialog(
                String(localized: "card.delete.confirm.title"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "card.delete"), role: .destructive) {
                    if viewModel?.delete() == true {
                        dismiss()
                    }
                }
                Button(String(localized: "action.cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "card.delete.confirm.message"))
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = CardEditorViewModel(deck: deck, card: card, modelContext: modelContext)
                }
                focus = .front
            }
        }
    }

    private var frontBinding: Binding<String> {
        Binding(
            get: { viewModel?.front ?? "" },
            set: { viewModel?.front = $0 }
        )
    }

    private var backBinding: Binding<String> {
        Binding(
            get: { viewModel?.back ?? "" },
            set: { viewModel?.back = $0 }
        )
    }

    private var tagsBinding: Binding<String> {
        Binding(
            get: { viewModel?.tagsText ?? "" },
            set: { viewModel?.tagsText = $0 }
        )
    }
}
