//
//  ChatSendAckData.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Minimal acknowledgment returned by `POST /chats/:id/send`.
///
/// The endpoint deliberately returns only the id + status + timestamp
/// rather than the full message row — clients already have the content
/// and sender info from the request that just went out, so the ack is
/// enough to reconcile a local optimistic insert. The full row is
/// available via `GET /chats/:id/messages` when the ViewModel refreshes.
struct ChatSendAckData: Decodable {
    let messageId: UUID
    let status: MessageStatus
    let timestamp: Date
}
