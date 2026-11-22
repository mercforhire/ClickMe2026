//
//  ChatItemMapperTests.swift
//  ClickMe2026Tests
//
//  IN-03: `event_data` comes from the backend, so a number outside the `Int` range must
//  read as missing instead of crashing the mapping of a whole thread page.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Chat item mapper")
@MainActor
struct ChatItemMapperTests {

    private static let identity = ChatItemMapper.Identity(
        myUserId: UUID(),
        myName: "Me",
        myAvatarURL: "",
        peerName: "Peer",
        peerAvatarURL: ""
    )

    private static func mappedEvent(durationMins: JSONValue?) -> BookingEvent? {
        let item = ChatMessageItem(
            id: UUID(),
            threadId: UUID(),
            senderId: nil,
            sender: nil,
            type: .event,
            content: nil,
            status: .sent,
            clientMsgId: nil,
            eventType: .bookingConfirmed,
            eventData: durationMins.map { .object(["duration_mins": $0]) },
            createdAt: Date()
        )
        guard case let .systemEvent(event) = ChatItemMapper.chatItem(from: item, identity: identity) else {
            return nil
        }
        return event
    }

    private static func mappedEvent(
        _ kind: MessageEventType,
        eventData: [String: JSONValue]?
    ) -> BookingEvent? {
        let item = ChatMessageItem(
            id: UUID(),
            threadId: UUID(),
            senderId: nil,
            sender: nil,
            type: .event,
            content: nil,
            status: .sent,
            clientMsgId: nil,
            eventType: kind,
            eventData: eventData.map { .object($0) },
            createdAt: Date()
        )
        guard case let .systemEvent(event) = ChatItemMapper.chatItem(from: item, identity: identity) else {
            return nil
        }
        return event
    }

    @Test("a cancel reason is trimmed and labelled by reason_by")
    func cancelReasonIsLabelledByWhoGaveIt() {
        let client = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("  Running late  "), "reason_by": .string("client")]
        )
        #expect(client?.reasonCaption == "Reason from the client: Running late")
        let expert = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("Running late"), "reason_by": .string("expert")]
        )
        #expect(expert?.reasonCaption == "Reason from the expert: Running late")
        let plain = Self.mappedEvent(.bookingCancelled, eventData: ["reason_text": .string("Running late")])
        #expect(plain?.reasonCaption == "Reason: Running late")
        let unknown = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("Running late"), "reason_by": .string("admin")]
        )
        #expect(unknown?.reasonCaption == "Reason: Running late")
    }

    @Test("a whitespace-only reason shows no caption")
    func blankReasonShowsNothing() {
        let event = Self.mappedEvent(
            .bookingCancelled,
            eventData: ["reason_text": .string("   "), "reason_by": .string("client")]
        )
        #expect(event?.reasonCaption == nil)
    }

    @Test("a cancelled event without the new keys maps as before")
    func eventWithoutReasonKeysIsUnchanged() {
        let event = Self.mappedEvent(.bookingCancelled, eventData: ["duration_mins": .int(30)])
        #expect(event?.reasonCaption == nil)
        #expect(event?.reasonCodeLabel == nil)
        #expect(event?.title == "Booking Cancelled")
        #expect(event?.isTerminal == true)
        #expect(event?.durationMins == 30)
    }

    @Test("duration_mins reads from an int, a numeric string and a whole double")
    func readsWholeNumbers() {
        #expect(Self.mappedEvent(durationMins: .int(30))?.durationMins == 30)
        #expect(Self.mappedEvent(durationMins: .string("45"))?.durationMins == 45)
        #expect(Self.mappedEvent(durationMins: .double(60))?.durationMins == 60)
    }

    @Test("duration_mins reads as nil for a double that is out of range, fractional or not a number")
    func rejectsUnrepresentableDoubles() {
        #expect(Self.mappedEvent(durationMins: .double(1e30))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(30.5))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(.nan))?.durationMins == nil)
        #expect(Self.mappedEvent(durationMins: .double(.infinity))?.durationMins == nil)
        // The row itself still maps.
        #expect(Self.mappedEvent(durationMins: .double(1e30)) != nil)
    }
}
