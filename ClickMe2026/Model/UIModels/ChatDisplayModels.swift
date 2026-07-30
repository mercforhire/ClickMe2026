//
//  ChatDisplayModels.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Which side of a chat bubble a message belongs on.
enum MessageSender { case me, them }

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

/// Display model for a single chat bubble. Populated from
/// `ChatMessageItem` on the wire.
struct ChatMessage: Identifiable {
    let id = UUID()
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
    /// message timing without needing the day-separator context.
    let timestamp: Date
    /// Delivery status for `.me` bubbles — bumped from `.sent` to
    /// `.read` when the peer's socket fires `message.read` with this
    /// bubble's `serverId`. Meaningless on `.them` bubbles; kept there
    /// for symmetry so future ack updates work uniformly.
    var status: MessageStatus
}

/// Display model for a system-injected booking lifecycle event row
/// (e.g. "Booking Confirmed", "Request Expired"). Derived from
/// `ChatMessageItem` where `type == .event`.
struct BookingEvent: Identifiable {
    let id = UUID()
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
}
