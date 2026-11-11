//
//  CancelReasonComposer.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Builds the `reason` sent with a client cancel (BOOK-07).
///
/// The cancel endpoint takes one `reason` string. The backend's `cancelSchema`
/// is `z.string().trim().max(500)`, counted in UTF-16 code units, and BACK-14
/// stores it on the booking. Android composes `"label: comment"` with a
/// 450-unit comment cap (`CancellationReason.kt`); this mirrors it, so the
/// longest reason sent is 20 (longest label) + 2 + 450 = 472 units.
///
/// Truncation is by whole character, so an emoji is never split.
nonisolated enum CancelReasonComposer {

    /// Longest comment the field accepts, in UTF-16 units.
    static let commentLimit = 450

    /// The server's limit for the whole reason, in UTF-16 units.
    static let reasonLimit = 500

    /// Caps a typed comment at `commentLimit` UTF-16 units on a character boundary.
    static func capComment(_ text: String) -> String {
        UTF16Prefix.prefix(text, limit: commentLimit)
    }

    /// `"label: comment"` with the comment trimmed, or the label alone when the
    /// comment is blank. Never longer than `reasonLimit` UTF-16 units.
    /// - Parameters:
    ///   - label: The picked reason, for example "Change of plans".
    ///   - comment: The optional free text.
    static func reason(label: String, comment: String) -> String {
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let composed = trimmed.isEmpty ? label : "\(label): \(trimmed)"
        return UTF16Prefix.prefix(composed, limit: reasonLimit)
    }
}
