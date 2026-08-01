//
//  DeckFormView.swift
//  hadisak
//

import SwiftUI

struct DeckFormView: View {
    let title: String
    @Binding var name: String
    var onSave: () -> Void
    var onCancel: () -> Void

    @Environment(\.themePalette) private var palette
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "deck.name.placeholder"), text: $name)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(onSave)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel"), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save"), action: onSave)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }
}
