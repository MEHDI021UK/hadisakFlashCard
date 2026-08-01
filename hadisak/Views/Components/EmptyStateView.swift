//
//  EmptyStateView.swift
//  hadisak
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.themePalette) private var palette

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(palette.primaryText)
        } description: {
            if let message {
                Text(message)
                    .foregroundStyle(palette.secondaryText)
            }
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(palette.accent)
            }
        }
    }
}
