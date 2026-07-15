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
/// `senderId` is nil, `eventType`/`eventData` are populated, `content` is a
/// human-readable summary.
///
/// For user messages (`text`/`image`/`file`): `eventType` and `eventData` are nil,
/// `clientMsgId` is a UUID idempotency key from the sender.
struct ChatMessageItem: Decodable {
    enum MessageType: String, Decodable {
        case text
        case image
        case file
        case event
    }

    enum Status: String, Decodable {
        case sent
        case delivered
        case read
    }

    enum EventType: String, Decodable {
        case bookingRequest      = "booking_request"
        case bookingConfirmed    = "BOOKING_CONFIRMED"
        case bookingDeclined     = "BOOKING_DECLINED"
        case bookingCancelled    = "BOOKING_CANCELLED"
        case bookingRescheduled  = "BOOKING_RESCHEDULED"
        case bookingCompleted    = "BOOKING_COMPLETED"
        case bookingExpired      = "BOOKING_EXPIRED"
    }

    let id: UUID
    let threadId: UUID
    let senderId: UUID?
    let type: MessageType
    let content: String?
    let status: Status
    let clientMsgId: String?
    let eventType: EventType?
    let eventData: JSONValue?
    let createdAt: Date
}
