//
//  ChatThreadItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Single chat thread row returned by `GET /chats`.
/// Enriched with partner presence (`isOnline` from Redis, best-effort) and
/// caller-relative `unreadCount`.
struct ChatThreadItem: Decodable {
    let threadId: UUID
    let partnerId: UUID
    let lastMessage: String?
    let lastMsgAt: Date?
    let unreadCount: Int
    let isOnline: Bool
    let isBlocked: Bool
}
