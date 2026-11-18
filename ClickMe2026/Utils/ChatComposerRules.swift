//
//  ChatComposerRules.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The chat composer's length cap and counter rules (CHAT-01, D-04).
///
/// Every length is `text.utf16.count`, the unit the server counts. Swift's
/// `Character` count would let a message full of emoji pass here and still be
/// refused with a 422 after the user taps Send.
///
/// Mirrors Android `TextCap.kt` and `ChatComposer.kt`.
nonisolated enum ChatComposerRules {

    /// Backend `chat.schema.js` `content` limit (`z.string().max(10000)`), in UTF-16 code units.
    static let limit = 10_000

    /// The counter appears from this many UTF-16 units (Android `COUNTER_FROM`).
    static let counterFrom = 9_000

    /// Cuts typed or pasted text at `limit` units on a whole-character boundary,
    /// so an emoji or surrogate pair is never split.
    static func cap(_ raw: String) -> String {
        UTF16Prefix.prefix(raw, limit: limit)
    }

    /// Whether the counter is on screen for a composer holding `length` units.
    static func showsCounter(length: Int) -> Bool {
        length >= counterFrom
    }

    /// Whether the composer is full.
    static func isAtLimit(length: Int) -> Bool {
        length >= limit
    }

    /// `{n} / 10,000` with both numbers grouped for `locale`, for example `9,500 / 10,000`.
    static func counterText(length: Int, locale: Locale = .current) -> String {
        "\(length.formatted(.number.locale(locale))) / \(limit.formatted(.number.locale(locale)))"
    }

    /// `{n} of 10,000 characters`, read by VoiceOver when the composer is full.
    static func accessibilityCounterLabel(length: Int, locale: Locale = .current) -> String {
        "\(length.formatted(.number.locale(locale))) of \(limit.formatted(.number.locale(locale))) characters"
    }

    /// True on the edit that takes the composer from below the limit to the limit,
    /// so the "Message length limit reached" announcement posts once and not per keystroke.
    static func crossedLimit(oldLength: Int, newLength: Int) -> Bool {
        oldLength < limit && newLength >= limit
    }
}
