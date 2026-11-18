//
//  ChatUnreadRules.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Display and counting rules for the unread pill on the Chats list
/// (CHAT-07, D-12 to D-14). Pure, so the boundaries are unit-tested without a
/// view. Mirrors Android's `UnreadBadge` in `ConversationRow.kt`, which caps
/// the count at 99.
nonisolated enum ChatUnreadRules {

    /// The most the pill shows as a number; above this it reads `99+`.
    static let badgeCap = 99

    /// A thread that was just opened has nothing unread (D-12).
    static let afterOpen = 0

    /// The pill text, or nil when the pill is not in the layout. Zero and
    /// negative counts are hidden; counts above 99 read `99+` (D-14).
    static func badgeLabel(count: Int) -> String? {
        guard count > 0 else { return nil }
        return count > badgeCap ? "99+" : String(count)
    }

    /// The unread sentence for VoiceOver, or nil at zero or below.
    static func unreadClause(count: Int) -> String? {
        guard count > 0 else { return nil }
        if count == 1 { return "1 unread message" }
        if count > badgeCap { return "More than 99 unread messages" }
        return "\(count) unread messages"
    }

    /// One VoiceOver label for the whole row: `{name}. {clause}. {preview}. {time}`,
    /// with the unread clause omitted at zero and ` Online.` appended when the
    /// peer is online. The pill itself is not read separately.
    static func rowAccessibilityLabel(
        name: String,
        count: Int,
        preview: String,
        time: String,
        isOnline: Bool
    ) -> String {
        var parts = [name]
        if let clause = unreadClause(count: count) { parts.append(clause) }
        parts.append(preview)
        parts.append(time)
        let label = parts.joined(separator: ". ")
        return isOnline ? label + ". Online." : label
    }

    /// A live message from the other person on a thread that is not on screen
    /// adds one to the row (D-13). The next `GET /chats` replaces the result
    /// with the server's count.
    static func afterPeerMessage(count: Int) -> Int {
        count + 1
    }
}
