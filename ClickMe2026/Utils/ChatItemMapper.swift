//
//  ChatItemMapper.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Maps a server message row (`GET /chats/:id/messages`) to the display row the
/// thread renders. Moved out of `ChattingViewModel` (CLAUDE.md Function Design:
/// extract into a helper rather than growing the largest view models) with no
/// change in behaviour beyond two additions for CHAT-01:
/// - a message row carries the server's `client_msg_id`, so a reloaded page can be
///   matched back to the bubble that sent it (D-01);
/// - a booking-event row carries its server id and created time, so an
///   overlapping page never duplicates it and it sorts among the messages.
enum ChatItemMapper {

    /// Who "me" and "the peer" are for one thread, since the mapper does not
    /// reach into the view model.
    struct Identity: Equatable {
        let myUserId: UUID?
        let myName: String
        let myAvatarURL: String
        let peerName: String
        let peerAvatarURL: String
    }

    // MARK: - Row mapping

    static func chatItem(from item: ChatMessageItem, identity: Identity) -> ChatItem {
        if item.type == .event, let eventType = item.eventType {
            var event = bookingEvent(
                from: eventType,
                content: item.content,
                eventData: item.eventData
            )
            event.serverId = item.id
            event.createdAt = item.createdAt
            return .systemEvent(event)
        }
        let mine = (item.senderId != nil && item.senderId == identity.myUserId)
        // Prefer server-provided sender info for the peer; fall back to
        // the caller-supplied peer identity for older payloads.
        let displayName = mine
            ? identity.myName
            : (item.sender?.name ?? identity.peerName)
        let displayAvatar = mine
            ? identity.myAvatarURL
            : (item.sender?.avatarUrl ?? identity.peerAvatarURL)
        return .message(ChatMessage(
            serverId: item.id,
            sender: mine ? .me : .them,
            senderName: displayName,
            body: item.content ?? "",
            avatarURL: displayAvatar,
            timestamp: item.createdAt,
            status: item.status,
            clientMsgId: item.clientMsgId
        ))
    }

    /// Maps a booking-lifecycle event to the visual style used by the
    /// sample conversation. Subtitle is the server's `content` if
    /// present (e.g. `"Tomorrow, 2:00 PM"`). `eventData` carries the
    /// server's `{ booking_id, client_id, expert_id, start_time,
    /// end_time, duration_mins, topic_title }` payload — the display
    /// metadata is pulled out so the row can render the booking's topic
    /// name and time inline without a per-row fetch.
    private static func bookingEvent(
        from event: MessageEventType,
        content: String?,
        eventData: JSONValue?
    ) -> BookingEvent {
        let bookingId = extractBookingId(from: eventData)
        let topicTitle = extractString(from: eventData, key: "topic_title")
        let startTime = extractDate(from: eventData, key: "start_time")
        let durationMins = extractInt(from: eventData, key: "duration_mins")
        let terminal = isTerminal(event)

        switch event {
        case .bookingRequest:
            return BookingEvent(icon: "envelope", title: "Booking Request",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingConfirmed:
            return BookingEvent(icon: "checkmark.square", title: "Booking Confirmed",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingDeclined:
            return BookingEvent(icon: "xmark.square", title: "Booking Declined",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingCancelled:
            return BookingEvent(icon: "xmark.circle", title: "Booking Cancelled",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingRescheduled:
            return BookingEvent(icon: "clock.arrow.circlepath", title: "Booking Rescheduled",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingCompleted:
            return BookingEvent(icon: "checkmark.seal", title: "Session Completed",
                                subtitle: content, isAccepted: true, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        case .bookingExpired:
            return BookingEvent(icon: "hourglass", title: "Request Expired",
                                subtitle: content, isAccepted: false, avatarURL: nil,
                                bookingId: bookingId, isTerminal: terminal,
                                topicTitle: topicTitle, startTime: startTime, durationMins: durationMins)
        }
    }

    // MARK: - event_data helpers

    /// Whether a booking event represents a finished lifecycle state
    /// (nothing more will happen). Decides whether tapping the row
    /// routes to the read-only summary or the still-actionable
    /// upcoming-booking screen.
    private static func isTerminal(_ event: MessageEventType) -> Bool {
        switch event {
        case .bookingDeclined, .bookingCancelled, .bookingCompleted, .bookingExpired:
            return true
        case .bookingRequest, .bookingConfirmed, .bookingRescheduled:
            return false
        }
    }

    /// Pulls `booking_id` out of the server's `event_data` payload.
    /// Returns nil for legacy events that predate this field or if the
    /// value isn't a valid UUID string.
    private static func extractBookingId(from data: JSONValue?) -> UUID? {
        guard case let .object(dict) = data,
              case let .string(str) = dict["booking_id"] else { return nil }
        return UUID(uuidString: str)
    }

    /// Reads a string field from the server's `event_data` object.
    /// Nil when the payload isn't an object or the field is missing.
    private static func extractString(from data: JSONValue?, key: String) -> String? {
        guard case let .object(dict) = data,
              case let .string(str) = dict[key] else { return nil }
        return str
    }

    /// Reads an integer field from `event_data`. Accepts both raw ints
    /// and stringly-typed numbers (some backends stringify small ints).
    /// A double that is not a whole number in `Int` range (fractional, NaN,
    /// infinite, or too large) reads as nil rather than trapping.
    private static func extractInt(from data: JSONValue?, key: String) -> Int? {
        guard case let .object(dict) = data else { return nil }
        switch dict[key] {
        case .int(let v): return v
        case .string(let s): return Int(s)
        case .double(let d): return Int(exactly: d)
        default: return nil
        }
    }

    /// Parses an ISO 8601 timestamp field from `event_data`. Fractional
    /// seconds are optional; the server currently emits them
    /// (`.424+00:00`) but we accept both for safety.
    private static let isoWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static func extractDate(from data: JSONValue?, key: String) -> Date? {
        guard let str = extractString(from: data, key: key) else { return nil }
        return isoWithFraction.date(from: str) ?? isoNoFraction.date(from: str)
    }
}
