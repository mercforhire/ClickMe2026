//
//  ChatThreadItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single chat thread row returned by `GET /chats`.
/// Enriched with the counterparty's public display info (`partner`),
/// partner presence (`isOnline` from Redis, best-effort), and
/// caller-relative `unreadCount`.
struct ChatThreadItem: Decodable {

    /// Public display info for the counterparty on this thread.
    /// `roles` distinguishes 1:1 client↔expert threads from support
    /// threads. Post-Phase-15 the server returns a role set (users can
    /// hold both `client` and `expert` capabilities); check
    /// `roles.contains(.support)` when deciding whether this is a
    /// support thread.
    struct Partner: Decodable {
        enum Role: String, Decodable {
            case client, expert, support
        }
        let id: UUID
        let name: String?
        let avatarUrl: String?
        let roles: [Role]
    }

    let threadId: UUID
    let partner: Partner
    let lastMessage: String?
    let lastMsgAt: Date?
    let unreadCount: Int
    let isOnline: Bool
    let isBlocked: Bool
    /// Caller-relative blocker flag. Only `true` when `isBlocked` is also
    /// `true` AND the caller is the recorded blocker. Legacy blocks pre
    /// 2026-10-17 don't have a recorded blocker, so both sides see
    /// `false` (`docs/ios/CHAT-UNBLOCK.md` §7). A payload from before the
    /// key existed, or a `null`, decodes as `false` too (§9, D-08), so a
    /// legacy block reads as blocked by the peer with no Unblock for either side.
    let blockedByMe: Bool
}

extension ChatThreadItem {

    /// The eight camelCase keys of a `GET /chats` thread; the network decoder's
    /// `convertFromSnakeCase` maps them from the snake_case wire names.
    private enum CodingKeys: String, CodingKey {
        case threadId, partner, lastMessage, lastMsgAt, unreadCount, isOnline, isBlocked, blockedByMe
    }

    /// Declared in an extension so the memberwise initializer stays available.
    /// `blocked_by_me` defaults to `false` when missing or null (D-08).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        threadId = try container.decode(UUID.self, forKey: .threadId)
        partner = try container.decode(Partner.self, forKey: .partner)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        lastMsgAt = try container.decodeIfPresent(Date.self, forKey: .lastMsgAt)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isBlocked = try container.decode(Bool.self, forKey: .isBlocked)
        blockedByMe = try container.decodeIfPresent(Bool.self, forKey: .blockedByMe) ?? false
    }
}
