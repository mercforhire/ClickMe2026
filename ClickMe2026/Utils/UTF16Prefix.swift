//
//  UTF16Prefix.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Grapheme-safe truncation by UTF-16 length.
///
/// The server's zod `.max()` counts UTF-16 code units, while Swift's `count`
/// counts characters. A reason full of emoji can pass a character count and
/// still be rejected by the server after the user confirmed, so free text bound
/// for a capped field is cut with this helper instead.
nonisolated enum UTF16Prefix {

    /// The longest whole-character prefix of `text` whose UTF-16 length is at most `limit`.
    /// - Parameters:
    ///   - text: The string to cap. Returned unchanged when it already fits.
    ///   - limit: Maximum length in UTF-16 code units.
    static func prefix(_ text: String, limit: Int) -> String {
        guard text.utf16.count > limit else { return text }
        var result = ""
        var used = 0
        for character in text {
            let units = String(character).utf16.count
            if used + units > limit { break }
            result.append(character)
            used += units
        }
        return result
    }
}
