//
//  RealtimeEvents.swift
//  ClickMe2026
//
//  Typed decoders for the Socket.IO payloads defined by the backend's
//  realtime contract. All fields use snake_case matching the wire
//  format; the Codable synth converts to camelCase Swift names via
//  `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` in
//  `RealtimeService`.
//

import Foundation

/// `message.new` — server → client. Fired when a message the caller
/// is a party to lands in the database (any thread the caller is in).
struct RealtimeMessageNewEvent: Decodable {
    let messageId: UUID
    let threadId: UUID
    let senderId: UUID
    let type: MessageType
    let content: String?
    let timestamp: Date
    let status: MessageStatus
}

/// `message.read` — server → client. Delivered to the *sender* of the
/// listed messages after the recipient's socket emits `message.read`.
/// `readBy` is the recipient's user id so a client with multiple
/// concurrent devices can dedupe.
struct RealtimeMessageReadEvent: Decodable {
    let threadId: UUID
    let messageIds: [UUID]
    let readBy: UUID
}

/// `user.status` — server → client. Fired only to conversation
/// partners of the user whose presence changed; never broadcast.
struct RealtimeUserStatusEvent: Decodable {
    enum Status: String, Decodable { case online, offline }
    let userId: UUID
    let status: Status
}

/// `typing.start` / `typing.stop` — server → client. Relayed from the
/// partner's device. `senderId` is who's typing (the partner, since we
/// wouldn't be sent our own events).
struct RealtimeTypingEvent: Decodable {
    let threadId: UUID
    let senderId: UUID
}

/// `booking.update` — server → client. Fires on every lifecycle
/// transition of a booking the caller is a party to.
struct RealtimeBookingUpdateEvent: Decodable {
    let bookingId: UUID
    let status: BookingStatus
    /// Populated only on `completed` — the id of the other party the
    /// caller can now review.
    let revieweeId: UUID?
    /// Populated on `expired` for the expert side — signals the client
    /// should clear any pending Accept/Decline card.
    let actionsInvalidated: Bool?
}

/// `call.ended` — server → client. The Agora call for this booking
/// finished (peer hung up, meeting timed out, admin-terminated). The
/// caller should tear down its own Agora session if it's still in-call.
struct RealtimeCallEndedEvent: Decodable {
    let bookingId: UUID
}
