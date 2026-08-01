//
//  StudySessionView.swift
//  hadisak
//

import SwiftUI
import SwiftData

struct StudySessionView: View {
    let deck: Deck
    var direction: StudyDirection

    @Environment(\.modelContext) private var modelContext
    @Environment(\.themePalette) private var palette
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var viewModel: StudySessionViewModel?
    @State private var showEditCard = false

    var body: some View {
        Group {
            if let viewModel {
                sessionBody(viewModel)
            } else {
                ProgressView()
            }
        }
        .background(palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = StudySessionViewModel(
                    deck: deck,
                    modelContext: modelContext,
                    settings: settings,
                    direction: direction
                )
            }
        }
    }

    @ViewBuilder
    private func sessionBody(_ viewModel: StudySessionViewModel) -> some View {
        VStack(spacing: 20) {
            StudyProgressBar(
                progress: viewModel.progress,
                remaining: viewModel.remainingCount,
                reviewed: viewModel.reviewedCount,
                deckName: viewModel.deckName
            )
            .padding(.horizontal)

            if viewModel.isFinished || viewModel.currentCard == nil {
                finishedView
            } else {
                FlashcardView(
                    prompt: viewModel.promptText,
                    answer: viewModel.answerText,
                    isRevealed: viewModel.isAnswerRevealed,
                    onReveal: { viewModel.revealAnswer() }
                )
                .padding(.horizontal)

                Spacer(minLength: 0)

                if viewModel.isAnswerRevealed {
                    RatingButtonsView(previews: viewModel.intervalPreviews) { rating in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.rate(rating)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Color.clear.frame(height: 72)
                }
            }
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.toggleDirection()
                } label: {
                    Image(systemName: viewModel.direction == .normal
                          ? "arrow.right.circle"
                          : "arrow.left.circle")
                }
                .accessibilityLabel(String(localized: String.LocalizationValue(viewModel.direction.localizationKey)))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditCard = true
                    } label: {
                        Label(String(localized: "card.edit"), systemImage: "pencil")
                    }
                    .disabled(viewModel.currentCard == nil)

                    Button {
                        viewModel.buryCurrent()
                    } label: {
                        Label(String(localized: "study.bury"), systemImage: "tray")
                    }
                    .disabled(viewModel.currentCard == nil)

                    Button {
                        viewModel.suspendCurrent()
                    } label: {
                        Label(String(localized: "study.suspend"), systemImage: "pause.circle")
                    }
                    .disabled(viewModel.currentCard == nil)

                    Divider()

                    Button {
                        viewModel.undo()
                    } label: {
                        Label(String(localized: "study.undo"), systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!viewModel.canUndo)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditCard) {
            if let card = viewModel.currentCard {
                CardEditorView(deck: deck, card: card)
                    .themed(settings.theme)
            }
        }
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(palette.good)
                .accessibilityHidden(true)
            Text(String(localized: "study.finished.title"))
                .font(.title2.weight(.bold))
                .foregroundStyle(palette.primaryText)
            Text(String(localized: "study.finished.message"))
                .font(.body)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(String(localized: "study.finished.done")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
