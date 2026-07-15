//
//  ChatThreadItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Single chat thread row returned by `GET /chats`.
/// Enriched with the counterparty's public display info (`partner`),
/// partner presence (`isOnline` from Redis, best-effort), and
/// caller-relative `unreadCount`.
struct ChatThreadItem: Decodable {

    /// Public display info for the counterparty on this thread.
    /// `role` distinguishes 1:1 client↔expert threads from support threads.
    struct Partner: Decodable {
        enum Role: String, Decodable {
            case client, expert, support
        }
        let id: UUID
        let name: String?
        let avatarUrl: String?
        let role: Role
    }

    let threadId: UUID
    let partner: Partner
    let lastMessage: String?
    let lastMsgAt: Date?
    let unreadCount: Int
    let isOnline: Bool
    let isBlocked: Bool
}
