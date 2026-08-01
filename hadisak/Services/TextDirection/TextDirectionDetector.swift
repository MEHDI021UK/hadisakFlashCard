//
//  TextDirectionDetector.swift
//  hadisak
//
//  Detects dominant writing direction for flashcard content independently of app locale.
//

import Foundation
import SwiftUI

/// Writing direction inferred from card content.
enum ContentWritingDirection: Sendable, Equatable {
    case leftToRight
    case rightToLeft

    var layoutDirection: LayoutDirection {
        switch self {
        case .leftToRight: .leftToRight
        case .rightToLeft: .rightToLeft
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leftToRight: .leading
        case .rightToLeft: .trailing
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leftToRight: .leading
        case .rightToLeft: .trailing
        }
    }
}

/// Detects whether text is primarily RTL (Persian, Arabic, Hebrew, Urdu, etc.) or LTR.
enum TextDirectionDetector {
    /// Unicode ranges commonly associated with RTL scripts.
    private static let rtlRanges: [ClosedRange<UInt32>] = [
        0x0590...0x05FF, // Hebrew
        0x0600...0x06FF, // Arabic
        0x0700...0x074F, // Syriac
        0x0750...0x077F, // Arabic Supplement
        0x0780...0x07BF, // Thaana
        0x08A0...0x08FF, // Arabic Extended-A
        0xFB1D...0xFB4F, // Hebrew presentation forms
        0xFB50...0xFDFF, // Arabic presentation forms-A
        0xFE70...0xFEFF  // Arabic presentation forms-B
    ]

    /// Returns the dominant writing direction for the given string.
    /// Mixed-language text uses a simple majority of strong directional letters.
    static func detect(in text: String) -> ContentWritingDirection {
        var rtlCount = 0
        var ltrCount = 0

        for scalar in text.unicodeScalars {
            let value = scalar.value
            if isRTL(value) {
                rtlCount += 1
            } else if isLTRLetter(scalar) {
                ltrCount += 1
            }
        }

        if rtlCount == 0 && ltrCount == 0 {
            return .leftToRight
        }
        return rtlCount >= ltrCount ? .rightToLeft : .leftToRight
    }

    private static func isRTL(_ value: UInt32) -> Bool {
        rtlRanges.contains { $0.contains(value) }
    }

    private static func isLTRLetter(_ scalar: Unicode.Scalar) -> Bool {
        // Strong LTR letters: Latin, Cyrillic, Greek, etc. Exclude digits and punctuation.
        guard CharacterSet.letters.contains(scalar) else { return false }
        return !isRTL(scalar.value)
    }
}
