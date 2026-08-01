//
//  PasteContentView.swift
//  hadisak
//
//  Paste TXT-formatted flashcard content into a deck, with a copyable format guide.
//

import SwiftUI
import SwiftData
import UIKit

struct PasteContentView: View {
    let deck: Deck

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette

    @State private var pastedText: String = ""
    @State private var errorMessage: String?
    @State private var didCopyGuide = false
    @FocusState private var isEditorFocused: Bool

    private let importService = ImportService()

    /// Canonical example shown to users and copied to the clipboard.
    static let formatGuide = """
    Front side 1
    Back side 1
    ---
    Front side 2
    Back side 2
    ---
    Hello
    سلام
    greeting, english
    ---
    Cat
    گربه
    animals
    """

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    guideSection
                    pasteSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(palette.background.ignoresSafeArea())
            .navigationTitle(String(localized: "content.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "content.import")) {
                        importPastedContent()
                    }
                    .fontWeight(.semibold)
                    .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert(
                String(localized: "alert.title"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(String(localized: "action.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Guide

    private var guideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "content.guide.title"))
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)
                Spacer()
                Button {
                    UIPasteboard.general.string = Self.formatGuide
                    didCopyGuide = true
                    Haptics.success()
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        didCopyGuide = false
                    }
                } label: {
                    Label(
                        didCopyGuide
                            ? String(localized: "content.guide.copied")
                            : String(localized: "content.guide.copy"),
                        systemImage: didCopyGuide ? "checkmark" : "doc.on.doc"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(palette.accent)
            }

            Text(String(localized: "content.guide.description"))
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)

            Text(Self.formatGuide)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(palette.primaryText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(palette.secondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Paste area

    private var pasteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "content.paste.title"))
                .font(.headline)
                .foregroundStyle(palette.primaryText)

            Text(String(localized: "content.paste.description"))
                .font(.footnote)
                .foregroundStyle(palette.secondaryText)

            TextEditor(text: $pastedText)
                .focused($isEditorFocused)
                .font(.body.monospaced())
                .frame(minHeight: 220)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(palette.secondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if pastedText.isEmpty {
                        Text(String(localized: "content.paste.placeholder"))
                            .font(.body)
                            .foregroundStyle(palette.secondaryText.opacity(0.7))
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { isEditorFocused = true }
    }

    // MARK: - Import

    private func importPastedContent() {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "error.import.empty")
            return
        }

        do {
            let pairs = try importService.parseTXT(Data(trimmed.utf8))
            importService.importPairs(pairs, into: deck, modelContext: modelContext)
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

#Preview {
    PasteContentView(deck: Deck(name: "Demo"))
        .environment(AppSettings())
        .themed(.light)
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
