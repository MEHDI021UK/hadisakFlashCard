//
//  Haptics.swift
//  hadisak
//
//  Lightweight haptic helpers for review and CRUD actions.
//

import UIKit

enum Haptics {
    static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func impactMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func impactRigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func rating(_ rating: ReviewRating) {
        switch rating {
        case .again:
            error()
        case .hard:
            impactLight()
        case .good:
            impactMedium()
        case .easy:
            success()
        }
    }
}
