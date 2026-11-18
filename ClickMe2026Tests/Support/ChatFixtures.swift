//
//  ChatFixtures.swift
//  ClickMe2026Tests
//
//  JSON builders for the chat thread suites (Phase 7): a page of
//  `GET /chats/:id/messages` rows and a `POST /chats/:id/send` ack. Message and
//  event rows are returned as one JSON object each, so a test can assemble a
//  page from any mix of them.
//

import Foundation

enum ChatFixtures {

    static let threadId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"

    // MARK: Rows

    /// One text message row as `GET /chats/:id/messages` returns it.
    ///
    /// - Parameters:
    ///   - senderId: The sender's user id. Nil gives a row with no sender, as for an event.
    ///   - status: The raw wire value: `sent`, `delivered` or `read`.
    ///   - clientMsgId: The sender's idempotency key, or nil.
    static func message(
        id: UUID,
        senderId: UUID?,
        content: String,
        status: String = "sent",
        clientMsgId: String? = nil,
        createdAt: Date
    ) -> String {
        let sender = senderId.map {
            #"{"id":"\#($0.uuidString)","name":"Sender","avatar_url":null}"#
        } ?? "null"
        let senderIdJSON = senderId.map { "\"\($0.uuidString)\"" } ?? "null"
        let clientMsgIdJSON = clientMsgId.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"id":"\#(id.uuidString)","thread_id":"\#(threadId)","sender_id":\#(senderIdJSON),"sender":\#(sender),"type":"text","content":"\#(content)","status":"\#(status)","client_msg_id":\#(clientMsgIdJSON),"event_type":null,"event_data":null,"created_at":"\#(ClientBookingFixtures.iso(createdAt))"}
        """#
    }

    /// One booking-lifecycle event row (`type` "event").
    ///
    /// - Parameters:
    ///   - eventType: The raw wire value, for example `BOOKING_CONFIRMED`.
    ///   - bookingId: Put in `event_data.booking_id` when given.
    static func event(
        id: UUID,
        createdAt: Date,
        eventType: String = "BOOKING_CONFIRMED",
        bookingId: UUID? = nil
    ) -> String {
        let eventData = bookingId.map { #"{"booking_id":"\#($0.uuidString)"}"# } ?? "null"
        return #"""
        {"id":"\#(id.uuidString)","thread_id":"\#(threadId)","sender_id":null,"sender":null,"type":"event","content":null,"status":"sent","client_msg_id":null,"event_type":"\#(eventType)","event_data":\#(eventData),"created_at":"\#(ClientBookingFixtures.iso(createdAt))"}
        """#
    }

    // MARK: Envelopes

    /// `GET /chats/:id/messages` success envelope around `rows` (each from `message` or `event`).
    static func messagesPage(_ rows: [String], page: Int = 1, totalPages: Int = 1) -> Data {
        Data(
            #"{"status":"success","data":{"messages":[\#(rows.joined(separator: ","))],"pagination":{"current_page":\#(page),"total_pages":\#(totalPages)}}}"#.utf8
        )
    }

    /// `POST /chats/:id/send` 201 ack.
    static func ack(messageId: UUID, timestamp: Date) -> Data {
        Data(
            #"{"status":"success","data":{"message_id":"\#(messageId.uuidString)","status":"sent","timestamp":"\#(ClientBookingFixtures.iso(timestamp))"}}"#.utf8
        )
    }
}
