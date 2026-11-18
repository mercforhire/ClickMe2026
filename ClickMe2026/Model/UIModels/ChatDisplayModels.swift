//
//  ChatDisplayModels.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which side of a chat bubble a message belongs on.
enum MessageSender { case me, them }

/// Where one of my own bubbles stands in the send flow (CHAT-01, D-01).
///
/// Local only: never decoded from the server and never written anywhere. A
/// `.sending` or `.failed` bubble lives in the view model's `items` and is gone
/// when the thread closes (D-02). Rows that came from the server are `.sent`.
enum ChatSendState {
    /// On the server (or a peer row). The default.
    case sent
    /// Appended locally; the POST has not answered yet.
    case sending
    /// The POST failed in a way that may still succeed on retry.
    case failed
}

/// A single row rendered in the chat scroll view. Wraps the three kinds
/// of things the message list can contain — user messages, day / time
/// separators, and system-injected booking lifecycle events.
enum ChatItem: Identifiable {
    case message(ChatMessage)
    case timestamp(String)
    case systemEvent(BookingEvent)

    var id: String {
        switch self {
        case let .message(m): return m.id.uuidString
        case let .timestamp(t): return "ts_\(t)"
        case let .systemEvent(e): return e.id.uuidString
        }
    }
}

extension ChatItem {
    /// The server's id for this row: the message id or the booking-event
    /// row id. Nil for local unsent bubbles and `.timestamp` separators.
    var serverId: UUID? {
        switch self {
        case let .message(m): return m.serverId
        case let .systemEvent(e): return e.serverId
        case .timestamp: return nil
        }
    }

    /// The time `ChatThreadReducer.order(_:)` sorts server rows by.
    var orderDate: Date? {
        switch self {
        case let .message(m): return m.timestamp
        case let .systemEvent(e): return e.createdAt
        case .timestamp: return nil
        }
    }
}

/// Display model for a single chat bubble. Populated from
/// `ChatMessageItem` on the wire.
struct ChatMessage: Identifiable {
    /// SwiftUI identity. Kept across ack, fail, retry and every merge, so a
    /// bubble is never removed and re-inserted while it changes state
    /// (07-RESEARCH Pitfall 2).
    var id: UUID = UUID()
    /// Server-assigned message uuid. Nil for locally-appended optimistic
    /// bubbles that haven't come back from the send ack yet, and for
    /// the sample data used in previews. Required to correlate live
    /// `message.read` receipts back to the sending bubble and to build
    /// the outgoing `message.read` payload.
    var serverId: UUID?
    let sender: MessageSender
    let senderName: String
    let body: String
    let avatarURL: String
    /// When the message was sent (server `created_at`). Rendered as a
    /// short "10:23 AM" caption beneath each bubble so users can see
    /// message timing without needing the day-separator context. A local
    /// bubble starts with the device clock; the send ack replaces it with
    /// the server time.
    var timestamp: Date
    /// Delivery status for `.me` bubbles — bumped from `.sent` to
    /// `.read` when the peer's socket fires `message.read` with this
    /// bubble's `serverId`. Meaningless on `.them` bubbles; kept there
    /// for symmetry so future ack updates work uniformly.
    var status: MessageStatus
    /// Idempotency key of one send. Set on my own bubbles, sent in the POST
    /// body and reused on retry; it lets a reloaded page row be matched back
    /// to the bubble that sent it (D-01).
    var clientMsgId: String? = nil
    /// Local send state (D-01, D-02). `.sent` for everything the server has.
    var sendState: ChatSendState = .sent
}

/// Display model for a system-injected booking lifecycle event row
/// (e.g. "Booking Confirmed", "Request Expired"). Derived from
/// `ChatMessageItem` where `type == .event`.
struct BookingEvent: Identifiable {
    /// SwiftUI identity, kept when a reloaded page row replaces this row.
    var id: UUID = UUID()
    let icon: String // SF Symbol
    let title: String
    let subtitle: String?
    let isAccepted: Bool
    let avatarURL: String? // nil = no avatar on left

    /// Booking this event refers to. Nil for legacy events that predate
    /// the server sending `event_data.booking_id`, and for sample /
    /// preview rows — in both cases the row renders but isn't tappable.
    let bookingId: UUID?

    /// Whether the underlying booking is still in-flight (request /
    /// confirmed / rescheduled) vs. finished (declined / cancelled /
    /// completed / expired). Drives which detail screen the tap routes
    /// to — active bookings → `UpcomingBookingView`, terminal ones →
    /// `BookingSummaryView`.
    let isTerminal: Bool

    /// Snapshot of the topic name at the time the event was emitted —
    /// stable even if the expert later renames the topic. Nil on legacy
    /// rows that predate `event_data.topic_title`.
    let topicTitle: String?

    /// When the referenced booking is scheduled to start. Used to render
    /// the "Fri, Jul 19 · 2:17 PM" caption beneath the event title.
    let startTime: Date?

    /// Booking duration in minutes. Included alongside `startTime` so
    /// the row can show "30 min consultation" without re-deriving it
    /// from end_time.
    let durationMins: Int?

    /// The server's id for this event row. Lets an overlapping page collapse
    /// into the row already shown instead of adding a second copy.
    var serverId: UUID? = nil

    /// Server `created_at` of this event row; orders it among messages.
    var createdAt: Date? = nil
}
