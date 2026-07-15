//
//  ChatMessageItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Single message row returned by `GET /chats/{id}/messages`.
///
/// For `type == .event` (system-injected booking lifecycle events):
/// `senderId` and `sender` are nil; `eventType`/`eventData` are populated;
/// `content` is a human-readable summary (may also be nil).
///
/// For user messages (`text`/`image`/`file`): `eventType` and `eventData`
/// are nil; `clientMsgId` is a UUID idempotency key from the sender;
/// `sender` carries the sender's public display info.
struct ChatMessageItem: Decodable {

    /// Public display info for the message sender. Nil on `.event` rows.
    struct Sender: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    let id: UUID
    let threadId: UUID
    let senderId: UUID?
    let sender: Sender?
    let type: MessageType
    let content: String?
    let status: MessageStatus
    let clientMsgId: String?
    let eventType: MessageEventType?
    let eventData: JSONValue?
    let createdAt: Date
}
